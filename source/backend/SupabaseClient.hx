package backend;

class SupabaseClient {
    public static final URL = "https://ubhglndbbzidunjgnpqi.supabase.co";
    public static final ANON_KEY = "sb_publishable_xShtsNZot0C3cIDqj3s2Ew_V3zJs_1k";

    public static function saveToken(token:String, userId:String):Void {
        FlxG.save.data.supabaseToken = token;
        FlxG.save.data.supabaseUserId = userId;
        FlxG.save.flush();
    }

    public static function getToken():String {
        var t = FlxG.save.data.supabaseToken;
        return (t != null) ? t : "";
    }

    public static function getUserId():String {
        var u = FlxG.save.data.supabaseUserId;
        return (u != null) ? u : "";
    }

    public static function clearToken():Void {
        FlxG.save.data.supabaseToken = null;
        FlxG.save.data.supabaseUserId = null;
        FlxG.save.flush();
    }

    public static function hasToken():Bool {
        var t = FlxG.save.data.supabaseToken;
        return (t != null && t != "");
    }
	
	public static function postAsync(endpoint:String, body:Dynamic, token:String = "", callback:Int->String->Void):Void {
        #if sys
        sys.thread.Thread.create(function() {
            var fullUrl = '${URL}${endpoint}';
            trace("POST ASYNC -> " + fullUrl);
            try {
                var http = new haxe.Http(fullUrl);
                http.setHeader("apikey", ANON_KEY);
                http.setHeader("Content-Type", "application/json");
                http.setHeader("Accept", "application/json");
                if (token != "") http.setHeader("Authorization", 'Bearer ${token}');

                var responseStatus = 0;
                var responseDone   = false;

                http.onData   = function(d) { responseStatus = 200; lime.app.Application.current.onUpdate.add(function(_) { if (!responseDone) { responseDone = true; callback(responseStatus, d); } }); };
                http.onStatus = function(s) { responseStatus = s; };
                http.onError  = function(e) { lime.app.Application.current.onUpdate.add(function(_) { if (!responseDone) { responseDone = true; callback(0, e); } }); };

                http.setPostData(haxe.Json.stringify(body));
                http.request(true);
            } catch(e:Dynamic) {
                callback(0, Std.string(e));
            }
        });
        #end
	}

	public static function getAsync(endpoint:String, token:String = "", callback:Int->String->Void):Void {
		#if sys
		sys.thread.Thread.create(function() {
			var fullUrl = '${URL}${endpoint}';
			trace("GET ASYNC -> " + fullUrl);
			try {
				var http = new haxe.Http(fullUrl);
				http.setHeader("apikey", ANON_KEY);
				http.setHeader("Accept", "application/json");
				if (token != "") http.setHeader("Authorization", 'Bearer ${token}');

				var responseStatus = 0;
				var responseDone   = false;

				http.onData   = function(d) { responseStatus = 200; lime.app.Application.current.onUpdate.add(function(_) { if (!responseDone) { responseDone = true; callback(responseStatus, d); } }); };
				http.onStatus = function(s) { responseStatus = s; };
				http.onError  = function(e) { lime.app.Application.current.onUpdate.add(function(_) { if (!responseDone) { responseDone = true; callback(0, e); } }); };

				http.request(false);
			} catch(e:Dynamic) {
				callback(0, Std.string(e));
			}
		});
		#end
	}

    public static function post(endpoint:String, body:Dynamic, token:String = "", callback:Int->String->Void):Void {
        var fullUrl = '${URL}${endpoint}';
        trace("POST -> " + fullUrl);

        #if sys
        try {
            var http = new haxe.Http(fullUrl);
            http.setHeader("apikey", ANON_KEY);
            http.setHeader("Content-Type", "application/json");
            http.setHeader("Accept", "application/json");
            if (token != "") http.setHeader("Authorization", 'Bearer ${token}');

            var responseData = "";
            var responseStatus = 0;

            http.onData   = function(d) { trace("DATA: " + d); responseData = d; callback(responseStatus, d); };
            http.onStatus = function(s) { trace("STATUS: " + s); responseStatus = s; };
            http.onError  = function(e) { trace("ERROR: " + e); callback(0, e); };

            http.setPostData(haxe.Json.stringify(body));
            http.request(true);
        } catch(e:Dynamic) {
            trace("EXCEPTION: " + e);
            callback(0, Std.string(e));
        }
        #end
    }

    public static function get(endpoint:String, token:String = "", callback:Int->String->Void):Void {
        var fullUrl = '${URL}${endpoint}';
        trace("GET -> " + fullUrl);

        #if sys
        try {
            var http = new haxe.Http(fullUrl);
            http.setHeader("apikey", ANON_KEY);
            http.setHeader("Accept", "application/json");
            if (token != "") http.setHeader("Authorization", 'Bearer ${token}');

            var responseStatus = 0;

            http.onData   = function(d) { trace("DATA: " + d); callback(responseStatus, d); };
            http.onStatus = function(s) { trace("STATUS: " + s); responseStatus = s; };
            http.onError  = function(e) { trace("ERROR: " + e); callback(0, e); };

            http.request(false);
        } catch(e:Dynamic) {
            trace("EXCEPTION: " + e);
            callback(0, Std.string(e));
        }
        #end
    }
}
