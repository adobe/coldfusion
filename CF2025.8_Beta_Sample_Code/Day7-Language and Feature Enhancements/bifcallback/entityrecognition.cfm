<cfscript>
// ============================================
// Named Entity Recognition (NER)
// ============================================
writeOutput("<h1>Named Entity Recognition (NER)</h1>");

nerProcessorClass = java{
    import opennlp.tools.tokenize.TokenizerME;
    import opennlp.tools.tokenize.TokenizerModel;
    import opennlp.tools.namefind.NameFinderME;
    import opennlp.tools.namefind.TokenNameFinderModel;
    import opennlp.tools.util.Span;
    import java.io.FileInputStream;

    public class NamedEntityRecognizer implements java.util.function.Function {
        private TokenizerME tokenizer;
        private NameFinderME personFinder;
        private NameFinderME locationFinder;
        private NameFinderME organizationFinder;
        
        public NamedEntityRecognizer(
            String tokenizerPath, 
            String personModelPath,
            String locationModelPath,
            String orgModelPath
        ) {
            try {
                FileInputStream tokenizerStream = new FileInputStream(tokenizerPath);
                TokenizerModel tokenizerModel = new TokenizerModel(tokenizerStream);
                tokenizer = new TokenizerME(tokenizerModel);
                tokenizerStream.close();
                
                FileInputStream personStream = new FileInputStream(personModelPath);
                TokenNameFinderModel personModel = new TokenNameFinderModel(personStream);
                personFinder = new NameFinderME(personModel);
                personStream.close();
                
                FileInputStream locationStream = new FileInputStream(locationModelPath);
                TokenNameFinderModel locationModel = new TokenNameFinderModel(locationStream);
                locationFinder = new NameFinderME(locationModel);
                locationStream.close();
                
                FileInputStream orgStream = new FileInputStream(orgModelPath);
                TokenNameFinderModel orgModel = new TokenNameFinderModel(orgStream);
                organizationFinder = new NameFinderME(orgModel);
                orgStream.close();
                
            } catch(Exception e) {
                throw new RuntimeException("Failed to initialize NER: " + e.getMessage());
            }
        }
        
        @Override
        public Object apply(Object obj) {
            String text = obj.toString();
            java.util.Map result = new java.util.HashMap();
            
            try {
                String[] tokens = tokenizer.tokenize(text);
                
                Span[] personSpans = personFinder.find(tokens);
                java.util.List<String> persons = new java.util.ArrayList<>();
                for(Span span : personSpans) {
                    StringBuilder name = new StringBuilder();
                    for(int i = span.getStart(); i < span.getEnd(); i++) {
                        name.append(tokens[i]).append(" ");
                    }
                    persons.add(name.toString().trim());
                }
                personFinder.clearAdaptiveData();
                
                Span[] locationSpans = locationFinder.find(tokens);
                java.util.List<String> locations = new java.util.ArrayList<>();
                for(Span span : locationSpans) {
                    StringBuilder loc = new StringBuilder();
                    for(int i = span.getStart(); i < span.getEnd(); i++) {
                        loc.append(tokens[i]).append(" ");
                    }
                    locations.add(loc.toString().trim());
                }
                locationFinder.clearAdaptiveData();
                
                Span[] orgSpans = organizationFinder.find(tokens);
                java.util.List<String> organizations = new java.util.ArrayList<>();
                for(Span span : orgSpans) {
                    StringBuilder org = new StringBuilder();
                    for(int i = span.getStart(); i < span.getEnd(); i++) {
                        org.append(tokens[i]).append(" ");
                    }
                    organizations.add(org.toString().trim());
                }
                organizationFinder.clearAdaptiveData();
                
                result.put("text", text);
                result.put("persons", persons);
                result.put("locations", locations);
                result.put("organizations", organizations);
                result.put("totalEntities", persons.size() + locations.size() + organizations.size());
                
            } catch(Exception e) {
                result.put("error", e.getMessage());
            }
            
            return result;
        }
    }
};

tokenizerPath = expandPath("./models/opennlp/en-token.bin");
personModelPath = expandPath("./models/opennlp/en-ner-person.bin");
locationModelPath = expandPath("./models/opennlp/en-ner-location.bin");
orgModelPath = expandPath("./models/opennlp/en-ner-organization.bin");

try {
    nerProcessor = nerProcessorClass.init(
        tokenizerPath, 
        personModelPath, 
        locationModelPath, 
        orgModelPath
    );
    writeOutput("<p style='color:green;'>NER models loaded successfully!</p>");
} catch(any e) {
    writeOutput("<p style='color:red;'>Error loading NER models: " & encodeForHTML(e.message) & "</p>");
    writeOutput("<p>Make sure model files exist at:</p>");
    writeOutput("<ul>");
    writeOutput("<li>" & encodeForHTML(tokenizerPath) & "</li>");
    writeOutput("<li>" & encodeForHTML(personModelPath) & "</li>");
    writeOutput("<li>" & encodeForHTML(locationModelPath) & "</li>");
    writeOutput("<li>" & encodeForHTML(orgModelPath) & "</li>");
    writeOutput("</ul>");
    abort;
}

// ============================================
// User-Submitted Text (via form POST)
// ============================================
userSubmitted = structKeyExists(form, "userText") && len(trim(form.userText));

if (userSubmitted) {
    userText = trim(form.userText);
    userResult = nerProcessor.apply(userText);

    personCount = arrayLen(userResult['persons']);
    locationCount = arrayLen(userResult['locations']);
    orgCount = arrayLen(userResult['organizations']);
    totalFound = userResult['totalEntities'];

    writeOutput("<div style='border:3px solid ##3182ce; border-radius:10px; margin:20px 0; padding:20px; background:##ebf8ff;'>");
    writeOutput("<h2 style='margin-top:0;'>Your Text &mdash; #totalFound# Entit#totalFound == 1 ? 'y' : 'ies'# Found</h2>");
    writeOutput("<p style='font-size:1.05em;'><em>&ldquo;#encodeForHTML(userText)#&rdquo;</em></p>");

    writeOutput("<table border='1' cellpadding='10' cellspacing='0' style='border-collapse:collapse; width:100%; margin-top:12px;'>");
    writeOutput("<tr style='background:##e2e8f0;'><th>Entity Type</th><th>Count</th><th>Entities Found</th></tr>");

    writeOutput("<tr>");
    writeOutput("<td><span style='display:inline-block;width:12px;height:12px;background:##3182ce;border-radius:50%;margin-right:6px;'></span><b>Persons</b></td>");
    writeOutput("<td style='text-align:center;'>#personCount#</td>");
    if (personCount > 0) {
        personBadges = "";
        for (p in userResult['persons']) {
            personBadges &= "<span style='background:##3182ce;color:white;padding:3px 10px;border-radius:12px;margin:2px 4px;display:inline-block;'>#encodeForHTML(p)#</span>";
        }
        writeOutput("<td>#personBadges#</td>");
    } else {
        writeOutput("<td style='color:##a0aec0;'>None detected</td>");
    }
    writeOutput("</tr>");

    writeOutput("<tr>");
    writeOutput("<td><span style='display:inline-block;width:12px;height:12px;background:##38a169;border-radius:50%;margin-right:6px;'></span><b>Locations</b></td>");
    writeOutput("<td style='text-align:center;'>#locationCount#</td>");
    if (locationCount > 0) {
        locBadges = "";
        for (l in userResult['locations']) {
            locBadges &= "<span style='background:##38a169;color:white;padding:3px 10px;border-radius:12px;margin:2px 4px;display:inline-block;'>#encodeForHTML(l)#</span>";
        }
        writeOutput("<td>#locBadges#</td>");
    } else {
        writeOutput("<td style='color:##a0aec0;'>None detected</td>");
    }
    writeOutput("</tr>");

    writeOutput("<tr>");
    writeOutput("<td><span style='display:inline-block;width:12px;height:12px;background:##805ad5;border-radius:50%;margin-right:6px;'></span><b>Organizations</b></td>");
    writeOutput("<td style='text-align:center;'>#orgCount#</td>");
    if (orgCount > 0) {
        orgBadges = "";
        for (o in userResult['organizations']) {
            orgBadges &= "<span style='background:##805ad5;color:white;padding:3px 10px;border-radius:12px;margin:2px 4px;display:inline-block;'>#encodeForHTML(o)#</span>";
        }
        writeOutput("<td>#orgBadges#</td>");
    } else {
        writeOutput("<td style='color:##a0aec0;'>None detected</td>");
    }
    writeOutput("</tr>");

    writeOutput("</table>");
    writeOutput("</div>");
}

// ============================================
// Input Form
// ============================================
writeOutput("<div style='border:1px solid ##cbd5e0; border-radius:8px; padding:20px; margin:20px 0; background:##f7fafc;'>");
writeOutput("<h2 style='margin-top:0;'>Try It &mdash; Enter Your Own Text for Entity Extraction</h2>");
writeOutput("<p style='color:##555;'>Paste any sentence containing names of people, places, or organizations.</p>");
writeOutput("<form method='post' action=''>");
writeOutput("<label for='userText'><b>Your Text:</b></label><br>");
writeOutput("<textarea id='userText' name='userText' rows='4' placeholder='e.g. Satya Nadella, CEO of Microsoft, spoke at the conference in Bangalore about Adobe and Microsoft partnerships.' style='width:100%; max-width:700px; padding:8px; margin:6px 0 14px; border:1px solid ##ccc; border-radius:4px; font-family:inherit;'>#userSubmitted ? encodeForHTML(userText) : ""#</textarea><br>");
writeOutput("<button type='submit' style='background:##3182ce; color:white; padding:10px 24px; border:none; border-radius:4px; font-size:1em; cursor:pointer;'>Extract Entities</button>");
writeOutput("</form>");
writeOutput("</div>");

// ============================================
// Sample Texts for Entity Recognition
// ============================================
nerTexts = [
    "A day after Delhi saw its coldest day in December so far this year, the IMD announced that the capital will be on yellow alert on Friday (December 5), putting the city on a coldwave alert.",
    "Apple Inc. CEO Tim Cook announced the new iPhone in San Francisco, California.",
    "Microsoft and Oracle are competing for cloud market share in Europe and Asia.",
    "John Smith from IBM will meet Sarah Johnson from Amazon in New York next week.",
    "Bill Gates is synonymous with Seattle, having co-founded Microsoft there, grown up in the area (attending Lakeside School), and built his famous ""Xanadu 2.0"" estate in nearby Medina overlooking Lake Washington",
    "Apple announced that Tim Cook will become executive chairman of Apple’s board of directors and John Ternus, senior vice president of Hardware Engineering, will become Apple’s next chief executive officer effective on September 1, 2026"
];

writeOutput("<hr style='margin:30px 0;'>");
writeOutput("<h2>Sample Texts &mdash; Extracted Entities</h2>");

nerResults = arrayMap(nerTexts, nerProcessor);

for(result in nerResults) {
    totalEntities = result['totalEntities'];
    borderCol = totalEntities > 0 ? "##3182ce" : "##cbd5e0";

    writeOutput("<div style='border:2px solid #borderCol#; margin:12px 0; padding:15px; background:##fafafa; border-radius:6px;'>");
    writeOutput("<p><b>Text:</b> <em>#encodeForHTML(result['text'])#</em></p>");

    writeOutput("<table cellpadding='4' style='margin-top:8px;'>");

    writeOutput("<tr><td><b style='color:##3182ce;'>Persons:</b></td><td>");
    if (arrayLen(result['persons']) > 0) {
        for (p in result['persons']) {
            writeOutput("<span style='background:##3182ce;color:white;padding:2px 8px;border-radius:10px;margin-right:4px;'>#encodeForHTML(p)#</span>");
        }
    } else {
        writeOutput("<span style='color:##a0aec0;'>None</span>");
    }
    writeOutput("</td></tr>");

    writeOutput("<tr><td><b style='color:##38a169;'>Locations:</b></td><td>");
    if (arrayLen(result['locations']) > 0) {
        for (l in result['locations']) {
            writeOutput("<span style='background:##38a169;color:white;padding:2px 8px;border-radius:10px;margin-right:4px;'>#encodeForHTML(l)#</span>");
        }
    } else {
        writeOutput("<span style='color:##a0aec0;'>None</span>");
    }
    writeOutput("</td></tr>");

    writeOutput("<tr><td><b style='color:##805ad5;'>Organizations:</b></td><td>");
    if (arrayLen(result['organizations']) > 0) {
        for (o in result['organizations']) {
            writeOutput("<span style='background:##805ad5;color:white;padding:2px 8px;border-radius:10px;margin-right:4px;'>#encodeForHTML(o)#</span>");
        }
    } else {
        writeOutput("<span style='color:##a0aec0;'>None</span>");
    }
    writeOutput("</td></tr>");

    writeOutput("</table>");
    writeOutput("<p style='margin-bottom:0; color:##555;'><b>Total Entities:</b> #totalEntities#</p>");
    writeOutput("</div>");
}
</cfscript>