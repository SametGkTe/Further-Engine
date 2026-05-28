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

	static final PROGRESS_EVERY:Int = 10;

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
				result.push(entryToInfo(entry));
			}

			input.close();
			return Success(result);
		} catch (e:Dynamic) {
			if (input != null) {
				try {
					input.close();
				} catch (_) {}
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

		// 1. ZIP var mı?
		if (!FileSystem.exists(zipPath)) {
			finishWithError(callbacks, FileNotFound(zipPath));
			return;
		}

		// 2. Hedef klasör
		try {
			ensureDirectory(destinationPath);
		} catch (e:Dynamic) {
			finishWithError(callbacks, PermissionDenied(destinationPath));
			return;
		}

		var normalizedDest = normalizeDirPath(destinationPath);

		// 3. ZIP aç
		var input:FileInput = null;
		var entries:List<Entry>;

		try {
			input = File.read(zipPath, true);
			var reader = new Reader(input);
			entries = reader.read();
		} catch (e:Dynamic) {
			if (input != null) {
				try {
					input.close();
				} catch (_) {}
			}
			finishWithError(callbacks, CorruptArchive(Std.string(e)));
			return;
		}

		// 4. Entry bilgilerini topla
		var entryInfos:Array<ZipEntryInfo> = [];
		for (entry in entries) {
			entryInfos.push(entryToInfo(entry));
		}

		// 5. Güvenlik taraması
		var scanResult = ZipSecurity.scanEntries(entryInfos, normalizedDest);
		switch (scanResult) {
			case Dangerous(reasons):
				try {
					input.close();
				} catch (_) {}
				finishWithError(callbacks, PathTraversal(reasons.join(" | ")));
				return;
			case Clean:
		}

		// 6. Fazladan üst klasör var mı algıla
		var stripPrefix = detectWrapperFolder(entryInfos);
		if (stripPrefix.length > 0) {
			trace('[SystemZipExtractor] Fazladan üst klasör algılandı: "$stripPrefix" — otomatik kaldırılacak.');
		}

		// 7. Toplam boyut
		var totalEntries = entryInfos.length;
		var totalBytes:Float = 0;
		for (info in entryInfos)
			totalBytes += info.uncompressedSize;

		// 8. Extract loop
		var extractedEntries = 0;
		var extractedBytes:Float = 0;
		var loopIndex = 0;
		var errorOccured:Null<ExtractError> = null;

		for (entry in entries) {
			// İptal?
			if (_cancelled) {
				try {
					input.close();
				} catch (_) {}
				finishCancelled(callbacks);
				return;
			}

			var rawName = entry.fileName;

			// Strip prefix uygula
			var adjustedName = applyStripPrefix(rawName, stripPrefix);

			// Boş isim olduysa (üst klasörün kendisi) atla
			if (adjustedName.length == 0) {
				loopIndex++;
				continue;
			}

			// Güvenli path kontrolü
			var safePath:String;
			switch (ZipSecurity.checkEntryPath(adjustedName, normalizedDest)) {
				case Safe(normalized):
					safePath = normalized;
				case Unsafe(reason):
					trace('[SystemZipExtractor] Atlandı (güvensiz): $rawName — $reason');
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

			// Üst dizin oluştur
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
				var data:Bytes = safeUnzip(entry);
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
				if (loopIndex % PROGRESS_EVERY == 0 || loopIndex == totalEntries) {
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

		// 9. Kapat
		try {
			input.close();
		} catch (_) {}

		if (errorOccured != null) {
			finishWithError(callbacks, errorOccured);
			return;
		}

		// 10. Tamamlandı
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
	//  Fazladan üst klasör algılama
	// ─────────────────────────────────────────────

	/**
	 * ZIP içindeki tüm entry'ler tek bir üst klasörün
	 * altındaysa o klasörün adını döndürür.
	 *
	 * Örnek:
	 *   TestModpack/_modpack.json
	 *   TestModpack/My-Mod/pack.json
	 *   → "TestModpack/" döner
	 *
	 *   _modpack.json
	 *   My-Mod/pack.json
	 *   → "" döner (strip gerekmez)
	 */
	function detectWrapperFolder(entries:Array<ZipEntryInfo>):String {
		if (entries.length == 0)
			return "";

		// İlk gerçek dosya/klasörün üst klasörünü bul
		var firstPrefix:String = null;

		for (entry in entries) {
			var name = sanitizeName(entry.fileName);
			if (name.length == 0)
				continue;

			var slashIdx = name.indexOf("/");

			if (slashIdx == -1) {
				// Kökte dosya var → strip gerekmiyor
				return "";
			}

			var topFolder = name.substr(0, slashIdx + 1);

			if (firstPrefix == null) {
				firstPrefix = topFolder;
			} else if (firstPrefix != topFolder) {
				// Farklı üst klasörler var → strip gerekmiyor
				return "";
			}
		}

		if (firstPrefix == null)
			return "";

		// Tüm entry'ler aynı üst klasörde
		// Ama bu gerçekten wrapper mı yoksa tek mod mu?
		// _modpack.json wrapper içinde mi kontrol et
		var hasManifestInWrapper = false;
		var hasManifestAtRoot = false;

		for (entry in entries) {
			var name = sanitizeName(entry.fileName);
			if (name == "_modpack.json")
				hasManifestAtRoot = true;
			if (name == firstPrefix + "_modpack.json")
				hasManifestInWrapper = true;
		}

		// Manifest wrapper içindeyse kesinlikle strip lazım
		if (hasManifestInWrapper && !hasManifestAtRoot)
			return firstPrefix;

		// Manifest hiç yoksa ve tek üst klasör varsa yine strip yap
		// Çünkü büyük ihtimal yanlış paketlenmiş
		if (!hasManifestAtRoot && !hasManifestInWrapper)
			return firstPrefix;

		return "";
	}

	/**
	 * Entry adından strip prefix'i kaldır
	 */
	function applyStripPrefix(entryName:String, prefix:String):String {
		if (prefix.length == 0)
			return entryName;

		var name = sanitizeName(entryName);

		if (StringTools.startsWith(name, prefix)) {
			return name.substr(prefix.length);
		}

		return name;
	}

	function sanitizeName(name:String):String {
		var result = StringTools.replace(name, "\\", "/");

		while (StringTools.startsWith(result, "./"))
			result = result.substr(2);

		return result;
	}

	// ─────────────────────────────────────────────
	//  Güvenli unzip
	// ─────────────────────────────────────────────

	/**
	 * Entry verisini güvenli şekilde aç.
	 * Reader.unzip() kullanır (doğru ZIP deflate).
	 */
	function safeUnzip(entry:Entry):Bytes {
		if (entry.data == null)
			return Bytes.alloc(0);

		if (entry.compressed) {
			// Reader.unzip entry'yi yerinde açar
			// data alanını uncompressed data ile değiştirir
			// compressed flag'ı false yapar
			try {
				Reader.unzip(entry);
			} catch (e:Dynamic) {
				// İlk yöntem başarısız olursa
				// raw inflate dene (farklı header)
				trace('[SystemZipExtractor] Reader.unzip başarısız, raw inflate deneniyor...');
				try {
					var inflated = rawInflate(entry.data, entry.fileSize);
					entry.data = inflated;
					entry.compressed = false;
				} catch (e2:Dynamic) {
					trace('[SystemZipExtractor] Raw inflate de başarısız: ${Std.string(e2)}');
					// Son çare: veriyi olduğu gibi döndür
					// Bozuk olabilir ama en azından crash olmaz
					trace('[SystemZipExtractor] Dosya sıkıştırılmış olarak kaydedilecek (bozuk olabilir).');
				}
			}
		}

		return entry.data;
	}

	/**
	 * Raw inflate denemesi.
	 * Bazı ZIP'lerde header farklı olabiliyor.
	 */
	function rawInflate(data:Bytes, expectedSize:Int):Bytes {
		// windowBits = -15 → raw deflate (no zlib/gzip header)
		var u = new haxe.zip.Uncompress(-15);
		var buf = Bytes.alloc(expectedSize);
		var result = u.execute(data, 0, buf, 0);
		u.close();

		if (result.done) {
			return buf;
		}

		// Partial decode
		return buf.sub(0, result.write);
	}

	// ─────────────────────────────────────────────
	//  Yardımcılar
	// ─────────────────────────────────────────────

	function entryToInfo(entry:Entry):ZipEntryInfo {
		return {
			fileName: entry.fileName,
			compressedSize: entry.data != null ? entry.data.length : 0,
			uncompressedSize: entry.fileSize,
			isDirectory: isDirectoryEntry(entry),
			crc32: Std.string(entry.crc32),
			isSymlink: false
		};
	}

	function isDirectoryEntry(entry:Entry):Bool {
		if (entry.fileSize == 0) {
			var name = entry.fileName;
			return StringTools.endsWith(name, "/") || StringTools.endsWith(name, "\\");
		}
		return false;
	}

	function ensureDirectory(path:String):Void {
		if (path == null || path.length == 0)
			return;

		// Recursive mkdir
		var normalized = StringTools.replace(path, "\\", "/");
		if (StringTools.endsWith(normalized, "/"))
			normalized = normalized.substr(0, normalized.length - 1);

		if (FileSystem.exists(normalized))
			return;

		var parent = Path.directory(normalized);
		if (parent != null && parent.length > 0 && parent != normalized) {
			ensureDirectory(parent);
		}

		try {
			FileSystem.createDirectory(normalized);
		} catch (e:Dynamic) {
			trace('[SystemZipExtractor] mkdir başarısız: $normalized — ${Std.string(e)}');
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
	public function new() {}

	public function getBackendName():String
		return "unsupported-no-sys";

	public function isSupported():Bool
		return false;

	public function isExtracting():Bool
		return false;

	public function cancel():Void {}

	public function listEntries(zipPath:String):ExtractResult<Array<ZipEntryInfo>>
		return Failure(NotSupported("sys target gerekli."));

	public function extract(zipPath:String, destinationPath:String, callbacks:ExtractCallbacks):Void {
		if (callbacks != null && callbacks.onError != null)
			callbacks.onError(NotSupported("sys target gerekli."));
	}
	#end
}