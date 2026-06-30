package backend;

import backend.AuthManager;
import backend.SupabaseClient;
import states.PlayState;
import flixel.FlxG;

class LeaderboardAPI {

    public static function submitScore(
        username:String, songName:String, difficulty:String,
        score:Int, accuracy:Float, rank:String,
        ?misses:Int = 0, ?maxCombo:Int = 0
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

        trace('[LeaderboardAPI] Submitting to server: song=$songName, score=$score, acc=$accuracy, rank=$rank, notes=$noteCount, bpm=$bpm, dur=$songDuration');

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

            if (status == 200 || status == 201) {
                try {
                    var result:Dynamic = haxe.Json.parse(data);

                    if (result.success == true) {
                        AuthManager.currentScore = Std.int(result.new_total_score);
                        AuthManager.currentUltraPoints = result.new_ultra_points;
                        AuthManager.currentLevel = Std.int(result.new_level);

                        trace('[LeaderboardAPI] Success! earned=${result.earned_up} UP (max=${result.max_up}), total UP=${result.new_ultra_points}, level=${result.new_level}');

                        if (objects.ProfileBox.instance != null)
                            objects.ProfileBox.instance.refresh();
                    } else {
                        trace('[LeaderboardAPI] Server rejected: ${result.error}');
                    }
                } catch (e) {
                    trace('[LeaderboardAPI] Parse error: $e');
                }
            } else {
                trace('[LeaderboardAPI] Submit failed: $data');
            }
        });
    }

    public static function getLeaderboard(callback:Array<Dynamic>->Void):Void {
        SupabaseClient.getAsync(
            "/rest/v1/profiles?select=username,total_score,ultra_points,level,country,badge&order=ultra_points.desc&limit=50",
            "",
            function(status:Int, data:String) {
                if (status == 200) {
                    try {
                        callback(haxe.Json.parse(data));
                    } catch (e) {
                        callback([]);
                    }
                } else {
                    callback([]);
                }
            }
        );
    }

    public static function getSongLeaderboard(songName:String, difficulty:String, callback:Array<Dynamic>->Void):Void {
        var encodedSong = StringTools.urlEncode(songName);
        var encodedDiff = StringTools.urlEncode(difficulty);

        SupabaseClient.getAsync(
            '/rest/v1/song_scores?select=username,score,accuracy,rank,misses,max_combo,ultra_points&song_name=eq.$encodedSong&difficulty=eq.$encodedDiff&order=score.desc&limit=20',
            "",
            function(status:Int, data:String) {
                if (status == 200) {
                    try {
                        callback(haxe.Json.parse(data));
                    } catch (e) {
                        callback([]);
                    }
                } else {
                    callback([]);
                }
            }
        );
    }
}