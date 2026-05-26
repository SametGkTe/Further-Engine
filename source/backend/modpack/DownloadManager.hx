package backend.modpack;

#if sys
import haxe.Http;
import haxe.io.Bytes;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;
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

	/**
	 * Dosya indir ve diske kaydet.
	 *
	 * @param url          İndirme URL'si
	 * @param savePath     Kaydedilecek dosya yolu
	 * @param callbacks    İlerleme callback'leri
	 */
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

		// Hedef klasörü oluştur
		var dir = Path.directory(savePath);
		if (dir != null && dir.length > 0) {
			try {
				if (!FileSystem.exists(dir))
					FileSystem.createDirectory(dir);
			} catch (e:Dynamic) {
				finishError(callbacks, 'Klasör oluşturulamadı: ${e.message}');
				return;
			}
		}

		var fileName = Path.withoutDirectory(savePath);

		var http = new Http(url);
		_currentHttp = http;

		http.addHeader("User-Agent", "PsychEngineTR-Updater/1.0");

		http.onBytes = function(data:Bytes) {
			if (_cancelled) {
				finishCancel(callbacks);
				return;
			}

			try {
				File.saveBytes(savePath, data);
				_downloading = false;
				_currentHttp = null;

				trace('[DownloadManager] İndirme tamamlandı: $savePath (${data.length} bytes)');

				if (callbacks != null && callbacks.onComplete != null)
					callbacks.onComplete(savePath);
			} catch (e:Dynamic) {
				finishError(callbacks, 'Dosya kaydedilemedi: ${e.message}');
			}
		};

		http.onError = function(error:String) {
			if (_cancelled) {
				finishCancel(callbacks);
				return;
			}

			finishError(callbacks, 'İndirme hatası: $error');
		};

		http.onStatus = function(status:Int) {
			trace('[DownloadManager] HTTP durum: $status');

			// Redirect durumlarını takip et
			if (status >= 300 && status < 400) {
				trace('[DownloadManager] Yönlendirme algılandı.');
			}
		};

		// Arka planda başlat
		try {
			http.request(false);
		} catch (e:Dynamic) {
			finishError(callbacks, 'İstek gönderilemedi: ${Std.string(e)}');
		}
	}

	/**
	 * GitHub release asset'ini indir.
	 * GitHub URL'leri genelde redirect içerir.
	 */
	public function downloadFromGitHub(url:String, savePath:String, callbacks:DownloadCallbacks):Void {
		// GitHub release asset linkleri redirect yapar
		// haxe.Http bunu otomatik takip eder
		download(url, savePath, callbacks);
	}

	function safeError(callbacks:DownloadCallbacks, msg:String):Void {
		if (callbacks != null && callbacks.onError != null)
			callbacks.onError(msg);
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
		if (callbacks != null && callbacks.onCancelled != null)
			callbacks.onCancelled();
	}

	#else
	public function new() {}
	public function isDownloading():Bool return false;
	public function cancel():Void {}

	public function download(url:String, savePath:String, callbacks:DownloadCallbacks):Void {
		if (callbacks != null && callbacks.onError != null)
			callbacks.onError("Bu platformda indirme desteklenmiyor.");
	}

	public function downloadFromGitHub(url:String, savePath:String, callbacks:DownloadCallbacks):Void {
		download(url, savePath, callbacks);
	}
	#end
}