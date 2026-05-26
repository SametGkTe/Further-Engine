package backend.update;

import haxe.Http;
import haxe.Json;

typedef RemoteModpackInfo = {
    var id:String;
    var displayName:String;
    var version:String;
    @:optional var versionNote:String;
    var author:String;
    var description:String;
    var category:String;
    var downloadUrl:String;
    @:optional var fileSize:String;
    @:optional var modCount:Int;
}

typedef ModpackListData = {
    @:optional var lastUpdated:String;
    var modpacks:Array<RemoteModpackInfo>;
}

typedef ModpackUpdateInfo = {
    var remote:RemoteModpackInfo;
    var installedVersion:String;
    var newVersion:String;
}

typedef CheckResult = {
    var allModpacks:Array<RemoteModpackInfo>;
    var availableUpdates:Array<ModpackUpdateInfo>;
    var hasUpdates:Bool;
}

class UpdateChecker {
    public var onError:Null<String->Void> = null;
    public var isChecking:Bool = false;
    public var lastResult:Null<CheckResult> = null;
    public var cachedModpacks:Null<Array<RemoteModpackInfo>> = null;

    static var _instance:UpdateChecker;
    public static var instance(get, never):UpdateChecker;

    static function get_instance():UpdateChecker {
        if (_instance == null) _instance = new UpdateChecker();
        return _instance;
    }

    public function new() {}

    /**
     * GitHub'dan modpack listesini çek.
     * Hem mağaza hem güncelleme için kullanılır.
     */
    public function fetchModpackList(?callback:CheckResult->Void):Void {
        if (isChecking) return;
        isChecking = true;

        var url = UpdateConfig.MODPACK_JSON_URL;
        trace('[UpdateChecker] Modpack listesi çekiliyor: $url');

        var http = new Http(url);
        http.addHeader("User-Agent", "PsychEngineTR-Updater");

        http.onData = function(data:String) {
            isChecking = false;

            try {
                var parsed:ModpackListData = cast Json.parse(data);

                if (parsed.modpacks == null) {
                    if (onError != null)
                        onError("modpacks alanı bulunamadı.");
                    if (callback != null)
                        callback(emptyResult());
                    return;
                }

                cachedModpacks = parsed.modpacks;

                var updates = findUpdates(parsed.modpacks);

                var result:CheckResult = {
                    allModpacks: parsed.modpacks,
                    availableUpdates: updates,
                    hasUpdates: updates.length > 0
                };

                lastResult = result;

                trace('[UpdateChecker] ${parsed.modpacks.length} modpack bulundu, ${updates.length} güncelleme mevcut.');

                if (callback != null)
                    callback(result);

            } catch (e:Dynamic) {
                if (onError != null)
                    onError('JSON parse hatası: ${Std.string(e)}');
                if (callback != null)
                    callback(emptyResult());
            }
        };

        http.onError = function(error:String) {
            isChecking = false;

            if (onError != null)
                onError('Bağlantı hatası: $error');
            if (callback != null)
                callback(emptyResult());
        };

        http.request(false);
    }

    /**
     * Kurulu modpackleri kontrol et, güncelleme var mı bak.
     */
    function findUpdates(remoteList:Array<RemoteModpackInfo>):Array<ModpackUpdateInfo> {
        var updates:Array<ModpackUpdateInfo> = [];

        for (remote in remoteList) {
            var installedVersion = getInstalledVersion(remote.id);

            if (installedVersion == null)
                continue;

            if (isRemoteNewer(installedVersion, remote.version)) {
                updates.push({
                    remote: remote,
                    installedVersion: installedVersion,
                    newVersion: remote.version
                });
            }
        }

        return updates;
    }

    /**
     * Kurulu modpack'in versiyonunu oku.
     * Kurulu değilse null döner.
     */
    function getInstalledVersion(packId:String):Null<String> {
        #if sys
        var manifestPath = backend.modpack.ModpackPaths.getInstalledManifestPath(packId);

        if (!sys.FileSystem.exists(manifestPath))
            return null;

        try {
            var raw = sys.io.File.getContent(manifestPath);
            var manifest:Dynamic = Json.parse(raw);
            return manifest.version;
        } catch (e:Dynamic) {
            return null;
        }
        #else
        return null;
        #end
    }

    function emptyResult():CheckResult {
        return {
            allModpacks: [],
            availableUpdates: [],
            hasUpdates: false
        };
    }

    // ─── Versiyon karşılaştırma ───

    public static function isRemoteNewer(current:String, remote:String):Bool {
        var c = parseVersion(current);
        var r = parseVersion(remote);

        var maxLen = c.length > r.length ? c.length : r.length;

        for (i in 0...maxLen) {
            var cv = i < c.length ? c[i] : 0;
            var rv = i < r.length ? r[i] : 0;
            if (rv > cv) return true;
            if (rv < cv) return false;
        }

        return false;
    }

    static function parseVersion(v:String):Array<Int> {
        if (v == null || v.length == 0)
            return [0, 0, 0];

        var cleaned = v;
        if (StringTools.startsWith(cleaned, "v"))
            cleaned = cleaned.substr(1);

        var dashIdx = cleaned.indexOf("-");
        if (dashIdx != -1)
            cleaned = cleaned.substr(0, dashIdx);

        var spaceIdx = cleaned.indexOf(" ");
        if (spaceIdx != -1)
            cleaned = cleaned.substr(0, spaceIdx);

        var parts = cleaned.split(".");
        var out:Array<Int> = [];

        for (p in parts) {
            var n = Std.parseInt(p);
            out.push(n == null ? 0 : n);
        }

        while (out.length < 3)
            out.push(0);

        return out;
    }
}