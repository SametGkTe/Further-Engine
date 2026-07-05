package backend;

import backend.AuthManager;
import backend.SupabaseClient;
import backend.ClientPrefs;
import states.PlayState;
import flixel.FlxG;

class LeaderboardAPI {

    static inline var MAX_RETRY:Int = 1;

    public static function submitScore(
        username:String, songName:String, difficulty:String,
        score:Int, accuracy:Float, rank:String,
        ?misses:Int = 0, ?maxCombo:Int = 0
    ):Void {
        if (!ClientPrefs.data.serverConnection) {
            trace('[LeaderboardAPI] Server connection disabled, skipping submit');
            return;
        }

        _submitWithRetry(username, songName, difficulty, score, accuracy, rank, misses, maxCombo, 0);
    }

    static function _submitWithRetry(
        username:String, songName:String, difficulty:String,
        score:Int, accuracy:Float, rank:String,
        misses:Int, maxCombo:Int, retryCount:Int
    ):Void {
        if (!AuthManager.isLoggedIn) {
            trace('[LeaderboardAPI] Not logged in, skipping submit');
            return;
        }

        var token = SupabaseClient.getToken();
        var userId = SupabaseClient.getUserId();

        if (token == null || userId == null || userId == "") {
            trace('[LeaderboardAPI] No token/userId, skipping submit');
            return;
        }

        trace('[LeaderboardAPI] submitScore (attempt=' + Std.string(retryCount + 1) + ') | user=' + username + ' song=' + songName + ' diff=' + difficulty + ' score=' + Std.string(score) + ' acc=' + Std.string(accuracy) + ' rank=' + rank);

        var noteCount:Int = 0;
        var bpm:Float = 120;
        var songDuration:Float = 0;

        if (PlayState.SONG != null) {
            if (PlayState.SONG.notes != null) {
                for (section in PlayState.SONG.notes) {
                    if (section != null && section.sectionNotes != null)
                        noteCount += section.sectionNotes.length;
                }
            }
            bpm = PlayState.SONG.bpm;
        }

        if (FlxG.sound.music != null)
            songDuration = FlxG.sound.music.length / 1000.0;

        trace('[LeaderboardAPI] Submitting: song=$songName, score=$score, acc=$accuracy, rank=$rank, notes=$noteCount, bpm=$bpm, dur=$songDuration');

        var rpcBody = {
            p_player_id: userId,
            p_username: username,
            p_song_name: songName,
            p_difficulty: difficulty,
            p_score: score,
            p_accuracy: accuracy,
            p_rank: rank,
            p_misses: misses,
            p_max_combo: maxCombo,
            p_note_count: noteCount,
            p_bpm: bpm,
            p_song_duration: songDuration
        };

        SupabaseClient.postAsync("/rest/v1/rpc/submit_song_score", rpcBody, token, function(status:Int, data:String) {
            trace('[LeaderboardAPI] Server response: status=$status, data=$data');

            if (_is401(status, data) && retryCount < MAX_RETRY) {
                trace('[LeaderboardAPI] 401 detected, refreshing token (retry ' + Std.string(retryCount + 1) + ')...');
                AuthManager.refreshAccessToken(function(success:Bool) {
                    if (success) {
                        trace('[LeaderboardAPI] Token refreshed, retrying submit...');
                        _submitWithRetry(username, songName, difficulty, score, accuracy, rank, misses, maxCombo, retryCount + 1);
                    } else {
                        trace('[LeaderboardAPI] Token refresh failed, submit aborted');
                    }
                });
                return;
            }

            if (status == 200 || status == 201) {
                _handleSubmitSuccess(data);
            } else {
                trace('[LeaderboardAPI] Submit failed: $data');
            }
        });
    }

    static function _handleSubmitSuccess(data:String):Void {
        try {
            var parsed:Dynamic = haxe.Json.parse(data);
            var result:Dynamic = parsed;

            if (Std.isOfType(parsed, Array)) {
                var arr:Array<Dynamic> = cast parsed;
                if (arr.length > 0)
                    result = arr[0];
            }

            trace('[LeaderboardAPI] Parsed result=' + Std.string(result));

            if (result != null && result.success == true) {
                var earnedUP:Int = 0;

                if (Reflect.hasField(result, "earned_up") && Reflect.field(result, "earned_up") != null)
                    earnedUP = Std.int(Reflect.field(result, "earned_up"));

                AuthManager.currentScore = Std.int(result.new_total_score);
                AuthManager.currentUltraPoints = result.new_ultra_points;
                AuthManager.currentLevel = Std.int(result.new_level);

                trace('[LeaderboardAPI] Success! earned=' + Std.string(earnedUP) + ' UP, total UP=' + Std.string(result.new_ultra_points) + ', level=' + Std.string(result.new_level));

                if (objects.ProfileBox.instance != null)
                    objects.ProfileBox.instance.refresh();

                if (earnedUP > 0) {
                    trace('[LeaderboardAPI] Triggering UPPopup.show()');
                    objects.UPPopup.show(
                        earnedUP,
                        AuthManager.currentUltraPoints,
                        AuthManager.currentLevel
                    );
                }
            } else {
                trace('[LeaderboardAPI] result.success != true');
            }
        } catch (e) {
            trace('[LeaderboardAPI] Parse error: $e');
        }
    }

    static function _is401(status:Int, data:String):Bool {
        if (status == 401)
            return true;
        if (status == 0 && data != null) {
            if (data.indexOf("401") != -1)
                return true;
            if (data.indexOf("JWT expired") != -1)
                return true;
            if (data.indexOf("invalid claim") != -1)
                return true;
            if (data.indexOf("token is expired") != -1)
                return true;
        }
        if (data != null && data.indexOf("JWT expired") != -1)
            return true;
        return false;
    }

    public static function getLeaderboard(callback:Array<Dynamic>->Void):Void {
        if (!ClientPrefs.data.serverConnection) {
            trace('[LeaderboardAPI] Server connection disabled, returning empty');
            callback([]);
            return;
        }

        _getLeaderboardWithRetry(callback, 0);
    }

    static function _getLeaderboardWithRetry(callback:Array<Dynamic>->Void, retryCount:Int):Void {
        var token = SupabaseClient.getToken();

        SupabaseClient.getAsync(
            "/rest/v1/profiles?select=username,total_score,ultra_points,level,country,badge&order=ultra_points.desc&limit=50",
            token != null ? token : "",
            function(status:Int, data:String) {
                if (status == 200) {
                    try {
                        callback(haxe.Json.parse(data));
                    } catch (e) {
                        callback([]);
                    }
                } else if (_is401(status, data) && retryCount < MAX_RETRY) {
                    trace('[LeaderboardAPI] getLeaderboard 401, refreshing...');
                    AuthManager.refreshAccessToken(function(ok) {
                        if (ok)
                            _getLeaderboardWithRetry(callback, retryCount + 1);
                        else
                            callback([]);
                    });
                } else {
                    callback([]);
                }
            }
        );
    }

    public static function getSongLeaderboard(songName:String, difficulty:String, callback:Array<Dynamic>->Void):Void {
        if (!ClientPrefs.data.serverConnection) {
            trace('[LeaderboardAPI] Server connection disabled, returning empty');
            callback([]);
            return;
        }

        _getSongLeaderboardWithRetry(songName, difficulty, callback, 0);
    }

    static function _getSongLeaderboardWithRetry(songName:String, difficulty:String, callback:Array<Dynamic>->Void, retryCount:Int):Void {
        var encodedSong = StringTools.urlEncode(songName);
        var encodedDiff = StringTools.urlEncode(difficulty);
        var token = SupabaseClient.getToken();

        SupabaseClient.getAsync(
            '/rest/v1/song_scores?select=username,score,accuracy,rank,misses,max_combo,ultra_points&song_name=eq.$encodedSong&difficulty=eq.$encodedDiff&order=score.desc&limit=20',
            token != null ? token : "",
            function(status:Int, data:String) {
                if (status == 200) {
                    try {
                        callback(haxe.Json.parse(data));
                    } catch (e) {
                        callback([]);
                    }
                } else if (_is401(status, data) && retryCount < MAX_RETRY) {
                    trace('[LeaderboardAPI] getSongLeaderboard 401, refreshing...');
                    AuthManager.refreshAccessToken(function(ok) {
                        if (ok)
                            _getSongLeaderboardWithRetry(songName, difficulty, callback, retryCount + 1);
                        else
                            callback([]);
                    });
                } else {
                    callback([]);
                }
            }
        );
    }
}