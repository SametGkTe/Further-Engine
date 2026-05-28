package backend.modpack;

#if sys
import haxe.Http;
import haxe.io.Bytes;
import haxe.io.Path;
import StringTools;
import sys.FileSystem;
import sys.io.File;
#end

typedef DownloadProgress = {
	var downloadedBytes:Float;
	var totalBytes:Float;
	var percent:Float;
	var fileName:String;
}

typedef DownloadCallbacks = {
	?onProgress:DownloadProgress->Void,
	?onComplete:String->Void,
	?onError:String->Void,
	?onCancelled:Void->Void
}

class DownloadManager {
	#if sys
	var _downloading:Bool = false;
	var _cancelled:Bool = false;
	var _currentHttp:Http = null;

	public function new() {}

	public function isDownloading():Bool {
		return _downloading;
	}

	public function cancel():Void {
		if (!_downloading) return;

		_cancelled = true;
		_currentHttp = null;
		trace('[DownloadManager] İptal isteği.');
	}

	public function download(url:String, savePath:String, callbacks:DownloadCallbacks):Void {
		if (_downloading) {
			safeError(callbacks, "Zaten bir indirme devam ediyor.");
			return;
		}

		if (url == null || url.length == 0) {
			safeError(callbacks, "İndirme URL'si boş.");
			return;
		}

		_downloading = true;
		_cancelled = false;

		trace('[DownloadManager] İndirme başladı: $url');

		var dir = Path.directory(savePath);
		if (dir != null && dir.length > 0) {
			try {
				ensureDirectoryRecursive(dir);
			} catch (e:Dynamic) {
				finishError(callbacks, 'Klasör oluşturulamadı: ${Std.string(e)}');
				return;
			}
		}

		var fileName = Path.withoutDirectory(savePath);
		var lastStatus:Int = 0;

		var http = new Http(url);
		_currentHttp = http;

		http.addHeader("User-Agent", "PsychEngineTR-Updater/1.0");

		http.onStatus = function(status:Int) {
			lastStatus = status;
			trace('[DownloadManager] HTTP durum: $status');

			if (status >= 300 && status < 400) {
				trace('[DownloadManager] Yönlendirme algılandı.');
			}
		};

		http.onBytes = function(data:Bytes) {
			if (_cancelled) {
				finishCancel(callbacks);
				return;
			}

			if (lastStatus >= 300 && lastStatus < 400) {
				finishError(callbacks,
					'Sunucu yönlendirme döndürdü ($lastStatus). ' +
					'Bu link oyun içi direkt indirme için uygun olmayabilir.'
				);
				return;
			}

			if (data == null || data.length <= 0) {
				finishError(callbacks, "İndirilen dosya boş geldi.");
				return;
			}

			if (looksLikeHtml(data)) {
				finishError(callbacks,
					'Sunucu ZIP yerine HTML sayfa döndürdü. ' +
					'Bu link direkt indirme linki değil.'
				);
				return;
			}

			try {
				if (callbacks != null && callbacks.onProgress != null) {
					callbacks.onProgress({
						downloadedBytes: data.length,
						totalBytes: data.length,
						percent: 1.0,
						fileName: fileName
					});
				}

				File.saveBytes(savePath, data);

				_downloading = false;
				_currentHttp = null;

				trace('[DownloadManager] İndirme tamamlandı: $savePath (${data.length} bytes)');

				if (callbacks != null && callbacks.onComplete != null) {
					callbacks.onComplete(savePath);
				}
			} catch (e:Dynamic) {
				finishError(callbacks, 'Dosya kaydedilemedi: ${Std.string(e)}');
			}
		};

		http.onError = function(error:String) {
			if (_cancelled) {
				finishCancel(callbacks);
				return;
			}

			finishError(callbacks, 'İndirme hatası: $error');
		};

		try {
			http.request(false);
		} catch (e:Dynamic) {
			finishError(callbacks, 'İstek gönderilemedi: ${Std.string(e)}');
		}
	}

	public function downloadFromGitHub(url:String, savePath:String, callbacks:DownloadCallbacks):Void {
		download(url, savePath, callbacks);
	}

	function looksLikeHtml(data:Bytes):Bool {
		if (data == null || data.length <= 0) return false;

		var len = data.length > 256 ? 256 : data.length;
		var sample = data.sub(0, len).toString();
		var trimmed = StringTools.trim(sample).toLowerCase();

		return StringTools.startsWith(trimmed, "<!doctype html")
			|| StringTools.startsWith(trimmed, "<html")
			|| trimmed.indexOf("<head") != -1
			|| trimmed.indexOf("<body") != -1;
	}

	function ensureDirectoryRecursive(path:String):Void {
		if (path == null || path.length == 0) return;
		if (FileSystem.exists(path)) return;

		var parent = Path.directory(path);
		if (parent != null && parent.length > 0 && parent != path) {
			ensureDirectoryRecursive(parent);
		}

		if (!FileSystem.exists(path)) {
			FileSystem.createDirectory(path);
		}
	}

	function safeError(callbacks:DownloadCallbacks, msg:String):Void {
		if (callbacks != null && callbacks.onError != null) {
			callbacks.onError(msg);
		}
	}

	function finishError(callbacks:DownloadCallbacks, msg:String):Void {
		_downloading = false;
		_cancelled = false;
		_currentHttp = null;
		trace('[DownloadManager] ✗ $msg');
		safeError(callbacks, msg);
	}

	function finishCancel(callbacks:DownloadCallbacks):Void {
		_downloading = false;
		_cancelled = false;
		_currentHttp = null;
		trace('[DownloadManager] İptal edildi.');

		if (callbacks != null && callbacks.onCancelled != null) {
			callbacks.onCancelled();
		}
	}

	#else

	public function new() {}

	public function isDownloading():Bool {
		return false;
	}

	public function cancel():Void {}

	public function download(url:String, savePath:String, callbacks:DownloadCallbacks):Void {
		if (callbacks != null && callbacks.onError != null) {
			callbacks.onError("Bu platformda indirme desteklenmiyor.");
		}
	}

	public function downloadFromGitHub(url:String, savePath:String, callbacks:DownloadCallbacks):Void {
		download(url, savePath, callbacks);
	}

	#end
}