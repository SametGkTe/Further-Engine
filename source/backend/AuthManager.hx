package backend;

import objects.ProfileBox; // ProfileBox import

class AuthManager {
    public static var currentUsername:String = "Player";
    public static var currentUserId:String = "";
    public static var currentLevel:Int = 1;
    public static var currentScore:Int = 0;
    public static var currentAvatar:Int = 0;
    public static var currentCountry:String = "";
    public static var isLoggedIn:Bool = false;
    public static var currentUltraPoints:Float = 0.0;
    public static var currentRole:String = "player";
    public static var currentBadge:String = null;

    public static function register(
        email:String, password:String,
        username:String, country:String,
        callback:Bool->String->Void
    ):Void {
    
        if (BadWordFilter.contains(username)) {
            callback(false, "Username contains inappropriate words.");
            return;
        }
        if (username.length < 4) {
            callback(false, "Username must be at least 4 characters.");
            return;
        }

        var body = {
            email: email,
            password: password,
            data: { username: username, country: country }
        };

        trace("SENDING BODY: " + haxe.Json.stringify(body));

        SupabaseClient.postAsync("/auth/v1/signup", body, "", function(status, data) {
            trace("REGISTER RESPONSE: " + data);

            if (status == 200 || status == 201) {
                try {
                    var parsed = haxe.Json.parse(data);

                    if (parsed.access_token != null) {
                        SupabaseClient.saveToken(parsed.access_token, parsed.user.id);
                        loadProfile(parsed.access_token, callback);
                    }
                    else if (parsed.id != null) {
                        callback(true, "Account created! Please check your email to verify.");
                    }
                    else {
                        callback(false, "Unexpected response.");
                    }
                } catch(e) {
                    callback(false, "Parse error: " + e);
                }
            } else {
                try {
                    var err = haxe.Json.parse(data);
                    callback(false, err.msg ?? err.error_description ?? err.error ?? "Registration failed.");
                } catch(_) {
                    callback(false, data);
                }
            }
        });
    }
    
    public static function loginWithUsername(
        username:String, password:String,
        callback:Bool->String->Void
    ):Void {
        SupabaseClient.getAsync(
            '/rest/v1/profiles?select=email&username=eq.' + StringTools.urlEncode(username),
            "", function(_, data) {
                try {
                    var arr:Array<Dynamic> = haxe.Json.parse(data);
                    if (arr.length == 0 || arr[0].email == null) {
                        callback(false, "Kullanıcı bulunamadı.");
                        return;
                    }
                    var email:String = arr[0].email;
                    login(email, password, callback);
                } catch(e) {
                    callback(false, "Bağlantı hatası.");
                }
            }
        );
    }

    public static function login(
        email:String, password:String,
        callback:Bool->String->Void
    ):Void {
        var body = {
            email: email,
            password: password,
            grant_type: "password"
        };
        
        trace("LOGIN BODY: " + haxe.Json.stringify(body));
        
        SupabaseClient.postAsync("/auth/v1/token?grant_type=password", body, "", function(status, data) {
            trace("LOGIN RESPONSE: " + data);
            if (data.indexOf('"access_token"') != -1) {
                var parsed = haxe.Json.parse(data);
                SupabaseClient.saveToken(parsed.access_token, parsed.user.id);
                loadProfile(parsed.access_token, callback);
            } else {
                try {
                    var err = haxe.Json.parse(data);
                    callback(false, err.error_description ?? err.msg ?? err.error ?? "Invalid email or password.");
                } catch(_) {
                    callback(false, "Invalid email or password.");
                }
            }
        });
    }

	public static function autoLogin(callback:Bool->Void):Void {
		if (!SupabaseClient.hasToken()) {
			trace('[AuthManager] No saved token');
			callback(false);
			return;
		}

		var token = SupabaseClient.getToken();
		var userId = SupabaseClient.getUserId();

		trace('[AuthManager] Auto-login attempting... token exists, userId: $userId');

		if (userId == null || userId == '') {
			trace('[AuthManager] No saved userId');
			callback(false);
			return;
		}

		SupabaseClient.getAsync("/auth/v1/user", token, function(status:Int, data:String) {
			trace('[AuthManager] Auto-login /auth/v1/user response: status=$status');

			if (status == 200 && data != null && data.indexOf('"id"') != -1) {
				loadProfile(token, function(ok, msg) {
					trace('[AuthManager] Auto-login loadProfile result: $ok - $msg');
					if (ok) {
						#if ACHIEVEMENTS_ALLOWED
						backend.AchievementSync.flushQueue();
						#end
					}
					callback(ok);
				});
			} else {
				trace('[AuthManager] Auto-login token expired or invalid');
				// Token geçersiz, temizle
				// SupabaseClient.clearToken(); // bunu açarsan her seferinde login ister
				callback(false);
			}
		});
	}
    // Şifremi unuttum
    public static function forgotPassword(email:String, callback:Bool->String->Void):Void {
        SupabaseClient.postAsync("/auth/v1/recover", { email: email }, "", function(_, data) {
            callback(true, "Password reset email sent!");
        });
    }

    // Hesap sil
    public static function deleteAccount(callback:Bool->String->Void):Void {
        var token = SupabaseClient.getToken();
        var userId = SupabaseClient.getUserId();
        var http = new haxe.Http('${SupabaseClient.URL}/rest/v1/profiles?id=eq.${userId}');
        http.setHeader("apikey", SupabaseClient.ANON_KEY);
        http.setHeader("Authorization", 'Bearer ${token}');
        http.setHeader("Content-Type", "application/json");
        http.onData = function(_) {
            logout();
            callback(true, "Account deleted.");
        };
        http.onError = function(e) callback(false, e);
        http.customRequest(false, new haxe.io.BytesOutput(), null, "DELETE");
    }

    // Çıkış yap
    public static function logout():Void {
        SupabaseClient.clearToken();
        currentUsername = "Player";
        currentUserId = "";
        isLoggedIn = false;
    }

	static function loadProfile(token:String, callback:Bool->String->Void):Void {
		SupabaseClient.getAsync("/rest/v1/profiles?select=*&id=eq." + SupabaseClient.getUserId(), token, function(_, data) {
			try {
				var arr:Array<Dynamic> = haxe.Json.parse(data);
				if (arr.length > 0) {
					var p = arr[0];
					currentUsername = p.username;
					currentLevel    = p.level;
					currentScore    = p.total_score;
					currentAvatar   = p.avatar_id;
					currentCountry  = p.country;
					currentUserId   = p.id;
					isLoggedIn = true;
					
					ProfileBox.syncFromAuth();
					
					// ══════════════════════════════════
					//  ACHIEVEMENT SYNC
					// ══════════════════════════════════
					AchievementSync.flushQueue();
					// ══════════════════════════════════
					
					callback(true, "OK");
				} else {
					_tryOfflineLogin(callback);
				}
			} catch(e) {
				callback(false, "Parse error.");
			}
		});
	}

    // Offline login denemesi - FIXED: ProfileBox kullanımı
    private static function _tryOfflineLogin(callback:Bool->String->Void):Void {
        var cached = ProfileBox.getCachedProfile();
        if (cached != null) {
            currentUsername = cached.username ?? "Player";
            currentLevel = cached.level ?? 1;
            currentScore = cached.score ?? 0;
            currentAvatar = cached.avatar ?? 0;
            currentCountry = "";
            isLoggedIn = true;
            callback(true, "Offline login");
        } else {
            currentUsername = "Player";
            isLoggedIn = false;
            callback(false, "Login required");
        }
    }

    static function tryParseError(data:String):String {
        try {
            var p = haxe.Json.parse(data);
            return p.msg ?? p.error_description ?? p.error ?? "Unknown error.";
        } catch(_) return "Unknown error.";
    }
}