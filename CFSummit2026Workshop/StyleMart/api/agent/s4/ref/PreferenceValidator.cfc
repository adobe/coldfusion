component {
  function init( required string userId ) {
    var configDir = getDirectoryFromPath( getCurrentTemplatePath() ) & "../config/";
    var stateDir  = getDirectoryFromPath( getCurrentTemplatePath() ) & "../state/preferences/";
    var userSchemaPath = stateDir & arguments.userId & ".schema.json";

    // Bootstrap: copy default → per-user on first call for this shopper.
    if ( !fileExists( userSchemaPath ) ) {
      fileCopy( configDir & "preference-schema.default.json", userSchemaPath );
    }

    var schemaJson = fileRead( userSchemaPath );
    variables.schema = deserializeJSON( schemaJson ).fields;
    return this;
  }

  public struct function validate( required struct rawStruct ) {
    var cleaned = {};
    var errors  = [];
    for ( var key in variables.schema ) {
      if ( !structKeyExists( arguments.rawStruct, key ) ) continue;
      var raw  = arguments.rawStruct[ key ];
      var spec = variables.schema[ key ];

      if ( spec.type == "string" ) {
        var s = toString( raw );
        if ( structKeyExists(spec, "enum") && !arrayFindNoCase(spec.enum, s) ) {
          arrayAppend( errors, key & ":enum-violation" ); continue;
        }
        if ( structKeyExists(spec, "pattern") && !reFind(spec.pattern, s) ) {
          arrayAppend( errors, key & ":pattern-violation" ); continue;
        }
        cleaned[ key ] = s;
      } else if ( spec.type == "number" ) {
        if ( !isNumeric(raw) ) { arrayAppend(errors, key & ":not-numeric"); continue; }
        var n = val( raw );
        if ( structKeyExists(spec, "min") && n < spec.min ) { arrayAppend(errors, key & ":below-min"); continue; }
        if ( structKeyExists(spec, "max") && n > spec.max ) { arrayAppend(errors, key & ":above-max"); continue; }
        cleaned[ key ] = n;
      } else if ( spec.type == "array<string>" ) {
        if ( !isArray(raw) ) { arrayAppend(errors, key & ":not-array"); continue; }
        var capped = ( structKeyExists(spec, "maxItems") && arrayLen(raw) > spec.maxItems )
                     ? arraySlice(raw, 1, spec.maxItems)
                     : raw;
        var asStrings = [];
        for ( var item in capped ) arrayAppend( asStrings, toString(item) );
        cleaned[ key ] = asStrings;
      }
    }
    return { valid: arrayLen(errors) == 0, errors: errors, cleaned: cleaned };
  }

  // Field descriptions for the extraction prompt.
  //
  // Returns enriched signatures, not just bare types — the LLM needs the enum
  // and pattern hints to disambiguate short answers (e.g. a lone "M" is not
  // recognized as topSize without seeing the XS/S/M/L/XL/XXL enum). Without
  // these hints, mistral at temp 0.0 routinely drops single-letter size replies
  // and only persists the color half of "M, black".
  public string function describeFields() {
    var parts = [];
    for ( var key in variables.schema ) {
      var spec = variables.schema[ key ];
      var desc = key & " (" & spec.type;
      if ( structKeyExists(spec, "enum") ) {
        desc &= "; one of: " & arrayToList( spec.enum, "/" );
      }
      if ( structKeyExists(spec, "pattern") ) {
        desc &= "; pattern: " & spec.pattern;
      }
      if ( structKeyExists(spec, "min") || structKeyExists(spec, "max") ) {
        desc &= "; range " & ( spec.min ?: "?" ) & ".." & ( spec.max ?: "?" );
      }
      if ( structKeyExists(spec, "maxItems") ) {
        desc &= "; max " & spec.maxItems & " items";
      }
      desc &= ")";
      arrayAppend( parts, desc );
    }
    return arrayToList( parts, ", " );
  }
}
