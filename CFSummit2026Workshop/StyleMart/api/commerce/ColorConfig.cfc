component {

    public struct function getSwatchMap() {
        return {
            "all black": "##1a1a1a", "amber": "##FFBF00", "beige": "##d6c4a6", "black": "##1a1a1a",
            "bleached blue": "##a8c4d6", "blush pink": "##de98ab", "brown": "##5a3920",
            "burgundy": "##800020", "butter yellow": "##FFFACD", "camel": "##c19a6b",
            "charcoal": "##36454F", "clear": "##e8e8e8", "cognac": "##9A463D", "coral": "##FF7F50",
            "cream": "##f0e8d8", "dark brown": "##3B2214", "deep blue": "##0A1F44",
            "deep burgundy": "##5C0021", "deep teal": "##005F5F", "dusty blue": "##6B8EAE",
            "dusty rose": "##DCAE96", "ecru": "##C2B280", "espresso": "##3C1414",
            "forest green": "##228B22", "graphite": "##4A4A4A", "gray": "##7a7a7a",
            "gunmetal": "##536267", "indigo": "##3F51B5", "ivory": "##FFFFF0", "khaki": "##C3B091",
            "lavender": "##B57EDC", "light gray": "##C0C0C0", "light wash blue": "##A4C8E1",
            "maroon": "##800000", "matte black": "##2B2B2B", "mid blue": "##4682B4",
            "midnight blue": "##191970", "mustard": "##FFDB58", "navy": "##1B2A4E",
            "oatmeal": "##D4C4A8", "off white": "##FAF0E6", "olive": "##5b6240",
            "oxblood": "##4A0000", "oxford blue": "##4A6FA5", "pale pink": "##FFD1DC",
            "pebble gray": "##9E9E8E", "pewter": "##8E9196", "plum": "##8E4585",
            "raw indigo": "##2E3A6E", "rust": "##B7410E", "sage": "##9CAF88",
            "sage green": "##8FBC8F", "sand": "##C2B280", "silver": "##C0C0C0",
            "sky blue": "##87CEEB", "slate": "##708090", "slate blue": "##6A5ACD",
            "slate gray": "##708090", "steel blue": "##4682B4", "stone": "##928E85",
            "tan": "##c8a878", "taupe": "##8B7D6B", "teal": "##008080", "terracotta": "##CC6644",
            "tortoise": "##8B5A2B", "translucent black": "##333333", "vintage blue": "##5B7FA4",
            "walnut": "##5C4033", "white": "##fafafa", "wine": "##722F37"
        };
    }

    public string function getSwatch(required string colorName) {
        var map = getSwatchMap();
        var key = lCase(arguments.colorName);
        return structKeyExists(map, key) ? map[key] : "##888888";
    }

}
