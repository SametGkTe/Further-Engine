package backend;

class BadWordFilter {
    static final WORDS:Array<String> = [
        "fuck", "shit", "ass", "bitch", "dick", "pussy", "cock", "cunt", "nigga", "nigger",
        "faggot", "retard", "whore", "slut",
        // Türkçe
        "sik", "orospu", "piç", "göt", "amk", "amına", "oç", "bok", "yarrak",
        "ibne", "orosbuçocuğu", "pezevenk", "salak", "gerizekalı"
    ];

    public static function contains(text:String):Bool {
        var lower = text.toLowerCase();
        for (word in WORDS) {
            if (lower.indexOf(word) != -1) return true;
        }
        return false;
    }
}