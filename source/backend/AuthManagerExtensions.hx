package backend;

class AuthManagerExtensions {

    /**
     * Login başarılı olduktan sonra profil verisini çek.
     * Token ve userId zaten set edilmiş olmalı.
     */
    public static function fetchAndStoreProfile(callback:Void -> Void):Void {
        var uid = SupabaseClient.getUserId();
        if (uid == null || uid == "") {
            callback();
            return;
        }

        SupabaseClient.getAsync(
            '/rest/v1/profiles?select=username,ultra_points,level,role,badge&id=eq.$uid',
            SupabaseClient.getToken(),
            function(status:Int, data:String) {
                try {
                    var arr:Array<Dynamic> = haxe.Json.parse(data);
                    if (arr.length > 0) {
                        var p = arr[0];
                        AuthManager.currentUsername     = Std.string(p.username ?? AuthManager.currentUsername);
                        AuthManager.currentUltraPoints  = p.ultra_points ?? 0.0;
                        AuthManager.currentLevel        = Std.int(p.level ?? 1);
                        AuthManager.currentRole         = Std.string(p.role ?? "player");
                        AuthManager.currentBadge        = p.badge != null ? Std.string(p.badge) : null;
                    }
                } catch(e) {
                    trace("[AuthManagerExtensions] fetchAndStoreProfile parse error: " + e);
                }
                callback();
            }
        );
    }

    /**
     * Çıkış yapınca tüm alanları sıfırla.
     * AuthManager.logout() içinde çağır.
     */
    public static function clearProfile():Void {
        AuthManager.currentUltraPoints = 0.0;
        AuthManager.currentLevel       = 1;
        AuthManager.currentRole        = "player";
        AuthManager.currentBadge       = null;
    }
}
