package backend;

class Language
{
    public static var defaultLangName:String = 'Türkçe (TR)';
    public static var currentLanguage:String = '';
    public static var loadedPhraseCount:Int = 0;

    #if TRANSLATIONS_ALLOWED
    private static var phrases:Map<String, String> = [];

    private static function buildSearchVariants(langFile:String):Array<String>
    {
        var variants:Array<String> = [];
        var raw = langFile.trim();

        if (raw.length == 0)
            return variants;

        if (raw.toLowerCase().endsWith('.lang'))
            raw = raw.substr(0, raw.length - 5);

        variants.push(raw);                                    
        variants.push(raw.toLowerCase());                      
        variants.push(raw.toUpperCase());                      

        if (raw.contains('-'))
        {
            var underscored = raw.split('-').join('_');
            variants.push(underscored);                        
            variants.push(underscored.toLowerCase());          
            variants.push(underscored.toUpperCase());          
        }
        else if (raw.contains('_'))
        {
            var dashed = raw.split('_').join('-');
            variants.push(dashed);                             
            variants.push(dashed.toLowerCase());               
            variants.push(dashed.toUpperCase());               
        }

        var shortLang = '';
        if (raw.contains('-'))
            shortLang = raw.split('-')[0];
        else if (raw.contains('_'))
            shortLang = raw.split('_')[0];

        if (shortLang.length > 0)
        {
            variants.push(shortLang);                          
            variants.push(shortLang.toLowerCase());            
            variants.push(shortLang.toUpperCase());            
        }

        var seen:Map<String, Bool> = [];
        var unique:Array<String> = [];
        for (v in variants)
        {
            if (!seen.exists(v))
            {
                seen.set(v, true);
                unique.push(v);
            }
        }

        return unique;
    }

    private static function tryLoadLangFile(langFile:String):Array<String>
    {
        var variants = buildSearchVariants(langFile);

        for (variant in variants)
        {
            var path = 'data/$variant.lang';
            var loaded:Array<String> = Mods.mergeAllTextsNamed(path);

            if (loaded != null && loaded.length > 0)
            {
                trace('[Language] Loaded: $path (variant: $variant)');
                currentLanguage = variant;
                return loaded;
            }
        }

        trace('[Language] WARNING: No lang file found! Tried variants:');
        for (variant in variants)
            trace('  - data/$variant.lang');

        return [];
    }
    #end

	public static function reloadPhrases()
	{
		#if TRANSLATIONS_ALLOWED
		phrases.clear();

		var langFile:String = ClientPrefs.data.language;

		if (langFile == null || langFile.length == 0 || langFile == ClientPrefs.defaultData.language)
		{
			trace('[Language] Using default hardcoded language. No file needed.');
			AlphaCharacter.loadAlphabetData();
			return;
		}

		var loadedText:Array<String> = Mods.mergeAllTextsNamed('data/$langFile.lang');

		var hasPhrases:Bool = false;
		for (num => phrase in loadedText)
		{
			phrase = phrase.trim();

			if (phrase.length > 0 && phrase.charCodeAt(0) == 0xFEFF)
				phrase = phrase.substr(1);

			if (num < 1 && !phrase.contains(':'))
			{
				phrases.set('language_name', phrase.trim());
				continue;
			}

			if (phrase.length < 4 || phrase.startsWith('//'))
				continue;

			var n:Int = phrase.indexOf(':');
			if (n < 0)
				continue;

			var key:String = phrase.substr(0, n).trim().toLowerCase();

			var value:String = phrase.substr(n);
			n = value.indexOf('"');
			if (n < 0)
				continue;

			phrases.set(key, value.substring(n + 1, value.lastIndexOf('"')).replace('\\n', '\n'));
			hasPhrases = true;
		}

		if (!hasPhrases)
		{
			trace('[Language] No phrases found in: $langFile.lang — falling back to default');
			ClientPrefs.data.language = ClientPrefs.defaultData.language;
		}

		var alphaPath:String = getFileTranslation('images/alphabet');
		if (alphaPath.startsWith('images/'))
			alphaPath = alphaPath.substr('images/'.length);
		var pngPos:Int = alphaPath.indexOf('.png');
		if (pngPos > -1)
			alphaPath = alphaPath.substring(0, pngPos);
		AlphaCharacter.loadAlphabetData(alphaPath);

		#else
		AlphaCharacter.loadAlphabetData();
		#end
	}


    private static function cleanLine(line:String):String
    {
        var cleaned = line.trim();

        if (cleaned.length > 0 && cleaned.charCodeAt(0) == 0xFEFF)
            cleaned = cleaned.substr(1);

        cleaned = cleaned.split('\r').join('');

        return cleaned;
    }

    private static function processEscapes(str:String):String
    {
        str = str.replace('\\n', '\n');
        str = str.replace('\\t', '\t');
        str = str.replace('\\"', '"');
        str = str.replace('\\\\', '\\');
        return str;
    }


    inline public static function getPhrase(key:String, ?defaultPhrase:String, values:Array<Dynamic> = null):String
    {
        #if TRANSLATIONS_ALLOWED
        var str:String = phrases.get(formatKey(key));
        if (str == null)
            str = defaultPhrase;
        #else
        var str:String = defaultPhrase;
        #end

        if (str == null)
            str = key;

        if (values != null)
            for (num => value in values)
                str = str.replace('{${num + 1}}', Std.string(value));

        return str;
    }

    inline public static function getFileTranslation(key:String)
    {
        #if TRANSLATIONS_ALLOWED
        var str:String = phrases.get(key.trim().toLowerCase());
        if (str != null)
            key = str;
        #end
        return key;
    }


    #if TRANSLATIONS_ALLOWED
    public static function hasPhrase(key:String):Bool
    {
        return phrases.exists(formatKey(key));
    }

    public static function getAllKeys():Array<String>
    {
        var keys:Array<String> = [];
        for (key in phrases.keys())
            keys.push(key);
        return keys;
    }

    public static function getLoadedLanguageName():String
    {
        var name = phrases.get('language_name');
        return (name != null) ? name : currentLanguage;
    }

    public static function getPhraseCount():Int
    {
        return loadedPhraseCount;
    }

    public static function dumpAllPhrases():Void
    {
        trace('========== LANGUAGE DUMP ==========');
        trace('Language: $currentLanguage');
        trace('Phrases: $loadedPhraseCount');
        trace('-----------------------------------');
        for (key => value in phrases)
            trace('  [$key] => "$value"');
        trace('===================================');
    }

    inline static private function formatKey(key:String)
    {
        final hideChars = ~/[~&\\\/;:<>#.,'"%?!]/g;
        return hideChars.replace(key.replace(' ', '_'), '').toLowerCase().trim();
    }
    #end


    #if LUA_ALLOWED
    public static function addLuaCallbacks(lua:State)
    {
        Lua_helper.add_callback(lua, "getTranslationPhrase", function(key:String, ?defaultPhrase:String, ?values:Array<Dynamic> = null) {
            return getPhrase(key, defaultPhrase, values);
        });

        Lua_helper.add_callback(lua, "getFileTranslation", function(key:String) {
            return getFileTranslation(key);
        });

        Lua_helper.add_callback(lua, "hasTranslationPhrase", function(key:String) {
            #if TRANSLATIONS_ALLOWED
            return hasPhrase(key);
            #else
            return false;
            #end
        });

        Lua_helper.add_callback(lua, "getLoadedLanguageName", function() {
            #if TRANSLATIONS_ALLOWED
            return getLoadedLanguageName();
            #else
            return defaultLangName;
            #end
        });

        Lua_helper.add_callback(lua, "getTranslationPhraseCount", function() {
            #if TRANSLATIONS_ALLOWED
            return getPhraseCount();
            #else
            return 0;
            #end
        });
    }
    #end
}