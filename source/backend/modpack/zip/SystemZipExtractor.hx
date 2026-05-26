package backend.modpack.zip;

#if sys
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.zip.Entry;
import haxe.zip.Reader;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;
import backend.modpack.zip.ZipTypes;
import backend.modpack.zip.ZipSecurity;
#end

class SystemZipExtractor implements IZipExtractor {
	#if sys
	var _extracting:Bool = false;
	var _cancelled:Bool = false;

	static final CHUNK_YIELD_EVERY:Int = 10;

	public function new() {}

	public function getBackendName():String {
		return "haxe-zip-streaming";
	}

	public function isSupported():Bool {
		return true;
	}

	public function isExtracting():Bool {
		return _extracting;
	}

	public function cancel():Void {
		if (_extracting) {
			_cancelled = true;
			trace("[SystemZipExtractor] İptal isteği alındı.");
		}
	}

	// ─────────────────────────────────────────────
	//  listEntries
	// ─────────────────────────────────────────────

	public function listEntries(zipPath:String):ExtractResult<Array<ZipEntryInfo>> {
		if (!FileSystem.exists(zipPath))
			return Failure(FileNotFound(zipPath));

		var input:FileInput = null;

		try {
			input = File.read(zipPath, true);
			var reader = new Reader(input);
			var entries = reader.read();

			var result:Array<ZipEntryInfo> = [];

			for (entry in entries) {
				result.push({
					fileName: entry.fileName,
					compressedSize: entry.dataSize,
					uncompressedSize: entry.fileSize,
					isDirectory: isDirectoryEntry(entry),
					crc32: Std.string(entry.crc32),
					isSymlink: false
				});
			}

			input.close();
			return Success(result);
		} catch (e:Dynamic) {
			if (input != null) {
				try { input.close(); } catch (_) {}
			}
			return Failure(CorruptArchive(Std.string(e)));
		}
	}

	// ─────────────────────────────────────────────
	//  extract
	// ─────────────────────────────────────────────

	public function extract(zipPath:String, destinationPath:String, callbacks:ExtractCallbacks):Void {
		if (_extracting) {
			safeError(callbacks, Unknown("Zaten bir extraction devam ediyor."));
			return;
		}

		_extracting = true;
		_cancelled = false;

		// ── 1. ZIP dosyası var mı?
		if (!FileSystem.exists(zipPath)) {
			finishWithError(callbacks, FileNotFound(zipPath));
			return;
		}

		// ── 2. Hedef klasörü oluştur
		try {
			ensureDirectory(destinationPath);
		} catch (e:Dynamic) {
			finishWithError(callbacks, PermissionDenied(destinationPath));
			return;
		}

		var normalizedDest = normalizeDirPath(destinationPath);

		// ── 3. ZIP aç ve entry listesini al
		var input:FileInput = null;
		var entries:List<Entry>;

		try {
			input = File.read(zipPath, true);
			var reader = new Reader(input);
			entries = reader.read();
		} catch (e:Dynamic) {
			if (input != null) {
				try { input.close(); } catch (_) {}
			}
			finishWithError(callbacks, CorruptArchive(Std.string(e)));
			return;
		}

		// ── 4. Güvenlik taraması için entry list oluştur
		var entryInfos:Array<ZipEntryInfo> = [];
		for (entry in entries) {
			entryInfos.push({
				fileName: entry.fileName,
				compressedSize: entry.dataSize,
				uncompressedSize: entry.fileSize,
				isDirectory: isDirectoryEntry(entry),
				crc32: Std.string(entry.crc32),
				isSymlink: false
			});
		}

		// ── 5. Güvenlik taraması
		var scanResult = ZipSecurity.scanEntries(entryInfos, normalizedDest);
		switch (scanResult) {
			case Dangerous(reasons):
				try { input.close(); } catch (_) {}
				finishWithError(callbacks, PathTraversal(reasons.join(" | ")));
				return;

			case Clean:
				// devam
		}

		// ── 6. Toplam boyutu hesapla
		var totalEntries = entryInfos.length;
		var totalBytes:Float = 0;
		for (info in entryInfos)
			totalBytes += info.uncompressedSize;

		// ── 7. Extract loop
		var extractedEntries = 0;
		var extractedBytes:Float = 0;
		var loopIndex = 0;
		var errorOccured:Null<ExtractError> = null;

		for (entry in entries) {
			// İptal kontrolü
			if (_cancelled) {
				try { input.close(); } catch (_) {}
				finishCancelled(callbacks);
				return;
			}

			// Güvenli path'i al
			var safePath:String;
			switch (ZipSecurity.checkEntryPath(entry.fileName, normalizedDest)) {
				case Safe(normalized):
					safePath = normalized;

				case Unsafe(reason):
					// Güvensiz entry'i atla, uyar
					trace('[SystemZipExtractor] Atlandı (güvensiz): ${entry.fileName} — $reason');
					loopIndex++;
					continue;
			}

			var fullDestPath = Path.join([normalizedDest, safePath]);
			fullDestPath = StringTools.replace(fullDestPath, "\\", "/");

			// Dizin mi?
			if (isDirectoryEntry(entry)) {
				try {
					ensureDirectory(fullDestPath);
				} catch (e:Dynamic) {
					trace('[SystemZipExtractor] Klasör oluşturulamadı: $fullDestPath');
				}
				loopIndex++;
				extractedEntries++;
				continue;
			}

			// Üst dizini oluştur
			var parentDir = Path.directory(fullDestPath);
			if (parentDir != null && parentDir.length > 0) {
				try {
					ensureDirectory(parentDir);
				} catch (e:Dynamic) {
					trace('[SystemZipExtractor] Üst klasör oluşturulamadı: $parentDir');
				}
			}

			// Dosyayı çıkar
			try {
				var data:Bytes = extractEntryData(entry);
				File.saveBytes(fullDestPath, data);
				extractedBytes += data.length;
			} catch (e:Dynamic) {
				trace('[SystemZipExtractor] Dosya yazılamadı: $fullDestPath — ${Std.string(e)}');
				errorOccured = Unknown('Dosya yazılamadı: $fullDestPath');
				break;
			}

			extractedEntries++;
			loopIndex++;

			// Progress
			if (callbacks != null && callbacks.onProgress != null) {
				if (loopIndex % CHUNK_YIELD_EVERY == 0 || loopIndex == totalEntries) {
					callbacks.onProgress({
						currentEntries: extractedEntries,
						totalEntries: totalEntries,
						currentFile: safePath,
						processedBytes: extractedBytes,
						totalBytes: totalBytes
					});
				}
			}
		}

		// ── 8. Kapat
		try { input.close(); } catch (_) {}

		if (errorOccured != null) {
			finishWithError(callbacks, errorOccured);
			return;
		}

		// ── 9. Tamamlandı
		_extracting = false;

		if (callbacks != null && callbacks.onComplete != null) {
			callbacks.onComplete({
				destination: normalizedDest,
				extractedEntries: extractedEntries,
				extractedBytes: extractedBytes
			});
		}
	}

	// ─────────────────────────────────────────────
	//  Yardımcılar
	// ─────────────────────────────────────────────

	function extractEntryData(entry:Entry):Bytes {
		if (entry.data == null)
			return Bytes.alloc(0);

		if (!entry.compressed)
			return entry.data;

		return haxe.zip.Uncompress.run(entry.data, entry.fileSize);
	}

	function isDirectoryEntry(entry:Entry):Bool {
		if (entry.fileSize == 0) {
			var name = entry.fileName;
			return StringTools.endsWith(name, "/") || StringTools.endsWith(name, "\\");
		}
		return false;
	}

	function ensureDirectory(path:String):Void {
		if (path == null || path.length == 0) return;
		if (!FileSystem.exists(path)) {
			FileSystem.createDirectory(path);
		}
	}

	function normalizeDirPath(path:String):String {
		var normalized = Path.normalize(path);
		normalized = StringTools.replace(normalized, "\\", "/");
		if (!StringTools.endsWith(normalized, "/"))
			normalized += "/";
		return normalized;
	}

	function safeError(callbacks:ExtractCallbacks, error:ExtractError):Void {
		if (callbacks != null && callbacks.onError != null)
			callbacks.onError(error);
	}

	function finishWithError(callbacks:ExtractCallbacks, error:ExtractError):Void {
		_extracting = false;
		_cancelled = false;
		safeError(callbacks, error);
	}

	function finishCancelled(callbacks:ExtractCallbacks):Void {
		_extracting = false;
		_cancelled = false;
		if (callbacks != null && callbacks.onCancelled != null)
			callbacks.onCancelled();
	}

	#else
	// sys yoksa hiçbir şey çalışmaz
	public function new() {}

	public function getBackendName():String return "unsupported-no-sys";
	public function isSupported():Bool return false;
	public function isExtracting():Bool return false;
	public function cancel():Void {}

	public function listEntries(zipPath:String):ExtractResult<Array<ZipEntryInfo>>
		return Failure(NotSupported("sys target gerekli."));

	public function extract(zipPath:String, destinationPath:String, callbacks:ExtractCallbacks):Void {
		if (callbacks != null && callbacks.onError != null)
			callbacks.onError(NotSupported("sys target gerekli."));
	}
	#end
}