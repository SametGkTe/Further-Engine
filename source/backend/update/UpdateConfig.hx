package backend.update;

class UpdateConfig {
    public static inline var CHECK_ON_STARTUP:Bool = true;

    public static inline var CURRENT_ENGINE_VERSION:String = "1.0.4";

    public static inline var GITHUB_REPO_OWNER:String = "SametGkTe";
    public static inline var GITHUB_REPO_NAME:String = "PsychEngineTurkiye";
    public static inline var GITHUB_BRANCH:String = "main";

    public static var MODPACK_JSON_URL(get, never):String;

    static function get_MODPACK_JSON_URL():String {
        return 'https://raw.githubusercontent.com/SametGkTe/Psych-Engine-1.0.4-Android/main/updates/modpacks.json';
    }
}