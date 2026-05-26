package backend.modpack;

#if sys
import haxe.io.Path;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;
import backend.modpack.ModpackTypes;
import backend.modpack.ModpackPaths;
import backend.modpack.zip.ZipExtractorFactory;
import backend.modpack.zip.ZipSecurity;
import backend.modpack.zip.ZipTypes;
import backend.modpack.zip.IZipExtractor;
#end

class ModpackInstaller {
	// ─────────────────────────────────────────────
	//  Sabitler
	// ─────────────────────────────────────────────

	static final MANIFEST_FILE:String = "_modpack.json";

	// Faz ağırlıkları (toplam 1.0 olmalı)
	static final WEIGHT_VALIDATING:Float = 0.05;
	static final WEIGHT_EXTRACTING:Float = 0.60;
	static final WEIGHT_VERIFYING:Float = 0.05;
	static final WEIGHT_INSTALLING:Float = 0.25;
	static final WEIGHT_CLEANUP:Float = 0.05;

	// ─────────────────────────────────────────────
	//  State
	// ─────────────────────────────────────────────

	#if sys
	var _extractor:IZipExtractor;
	var _installing:Bool = false;
	var _cancelled:Bool = false;

	// ─────────────────────────────────────────────
	//  Constructor
	// ─────────────────────────────────────────────

	public function new() {
		_extractor = ZipExtractorFactory.createSafe();
		trace('[ModpackInstaller] Oluşturuldu. Backend: ${_extractor.getBackendName()}');
	}

	// ─────────────────────────────────────────────
	//  Public API
	// ─────────────────────────────────────────────

	/**
	 * Modpack kurulumunu başlat.
	 *
	 * @param zipPath   İndirilen ZIP dosyasının tam yolu
	 * @param packId    Modpack kimliği ("minimal", "medium", "high")
	 * @param callbacks İlerleme ve sonuç callback'leri
	 */
	public function install(zipPath:String, packId:String, callbacks:ModpackInstallCallbacks):Void {
		if (_installing) {
			warn(callbacks, "Zaten bir kurulum devam ediyor.");
			return;
		}

		if (!_extractor.isSupported()) {
			fail(callbacks, "Bu platformda ZIP çıkarma desteklenmiyor.");
			return;
		}

		if (packId == null || packId.length == 0) {
			fail(callbacks, "Geçersiz packId.");
			return;
		}

		_installing = true;
		_cancelled = false;

		trace('[ModpackInstaller] Kurulum başladı. packId=$packId zipPath=$zipPath');

		ModpackPaths.ensureDirectories();

		step_validate(zipPath, packId, callbacks);
	}

	/**
	 * Devam eden kurulumu iptal et.
	 */
	public function cancel():Void {
		if (!_installing) return;
		_cancelled = true;
		_extractor.cancel();
		trace('[ModpackInstaller] İptal isteği gönderildi.');
	}

	public function isInstalling():Bool {
		return _installing;
	}

	/**
	 * Kurulu bir modpack'in manifest'ini oku.
	 * Kurulu değilse null döner.
	 */
	public function getInstalledManifest(packId:String):Null<ModpackManifest> {
		var manifestPath = ModpackPaths.getInstalledManifestPath(packId);

		if (!FileSystem.exists(manifestPath))
			return null;

		try {
			var raw = File.getContent(manifestPath);
			return (Json.parse(raw) : ModpackManifest);
		} catch (e:Dynamic) {
			trace('[ModpackInstaller] Manifest okunamadı: ${e.message}');
			return null;
		}
	}

	/**
	 * Bir modpack kurulu mu?
	 */
	public function isInstalled(packId:String):Bool {
		return getInstalledManifest(packId) != null;
	}

	// ─────────────────────────────────────────────
	//  Adım 1 — Doğrulama
	// ─────────────────────────────────────────────

	function step_validate(zipPath:String, packId:String, callbacks:ModpackInstallCallbacks):Void {
		reportPhase(callbacks, Validating, 0.0, "", "ZIP dosyası kontrol ediliyor...");

		if (checkCancelled(callbacks)) return;

		// ZIP var mı?
		if (!FileSystem.exists(zipPath)) {
			fail(callbacks, 'ZIP dosyası bulunamadı: $zipPath');
			return;
		}

		// ZIP boyutu sıfır mı?
		var stat = FileSystem.stat(zipPath);
		if (stat.size <= 0) {
			fail(callbacks, 'ZIP dosyası boş: $zipPath');
			return;
		}

		// Hedef temp klasörünü hazırla
		var tempDir = ModpackPaths.getTempPackDirectory(packId);
		try {
			deleteDirectory(tempDir);
			FileSystem.createDirectory(tempDir);
		} catch (e:Dynamic) {
			fail(callbacks, 'Temp klasörü hazırlanamadı: ${e.message}');
			return;
		}

		reportPhase(callbacks, Validating, 0.5, "", "ZIP içeriği taranıyor...");

		if (checkCancelled(callbacks)) return;

		// Entry listesi al
		var entriesResult = _extractor.listEntries(zipPath);

		switch (entriesResult) {
			case Success(entries):
				if (entries.length == 0) {
					fail(callbacks, 'ZIP dosyası boş görünüyor.');
					return;
				}

				// Güvenlik taraması
				var scanResult = ZipSecurity.scanEntries(entries, tempDir);
				switch (scanResult) {
					case Dangerous(reasons):
						fail(callbacks, 'Güvenlik ihlali:\n${reasons.join("\n")}');
						return;

					case Clean:
						// devam
				}

				reportPhase(callbacks, Validating, 1.0, "", "Doğrulama tamamlandı.");
				step_extract(zipPath, packId, tempDir, callbacks);

			case Failure(error):
				fail(callbacks, 'ZIP okunamadı: ${formatError(error)}');
		}
	}

	// ─────────────────────────────────────────────
	//  Adım 2 — Temp'e Extract
	// ─────────────────────────────────────────────

	function step_extract(
		zipPath:String, packId:String, tempDir:String,
		callbacks:ModpackInstallCallbacks
	):Void {
		reportPhase(callbacks, Extracting, 0.0, "", "Dosyalar çıkarılıyor...");

		if (checkCancelled(callbacks)) return;

		_extractor.extract(zipPath, tempDir, {
			onProgress: function(info:ExtractProgressInfo) {
				if (checkCancelled(callbacks)) return;

				var pct = info.totalEntries > 0 ? info.currentEntries / info.totalEntries : 0.0;

				reportPhase(
					callbacks,
					Extracting,
					pct,
					info.currentFile,
					'Çıkarılıyor: ${info.currentEntries} / ${info.totalEntries}'
				);
			},

			onComplete: function(info:ExtractCompleteInfo) {
				trace('[ModpackInstaller] Extract tamamlandı. ${info.extractedEntries} dosya.');
				step_verify(packId, tempDir, callbacks);
			},

			onError: function(error:ExtractError) {
				deleteDirectory(tempDir);
				fail(callbacks, 'Çıkarma hatası: ${formatError(error)}');
			},

			onCancelled: function() {
				deleteDirectory(tempDir);
				handleCancel(callbacks);
			}
		});
	}

	// ─────────────────────────────────────────────
	//  Adım 3 — Manifest Doğrulama
	// ─────────────────────────────────────────────

	function step_verify(
		packId:String, tempDir:String,
		callbacks:ModpackInstallCallbacks
	):Void {
		reportPhase(callbacks, Verifying, 0.0, "", "Modpack doğrulanıyor...");

		if (checkCancelled(callbacks)) return;

		var manifestPath = Path.join([tempDir, MANIFEST_FILE]);
		var manifest:ModpackManifest;

		if (!FileSystem.exists(manifestPath)) {
			// Manifest yok, otomatik oluştur
			warn(callbacks, '_modpack.json bulunamadı. Modpack otomatik taranacak.');
			manifest = buildAutoManifest(packId, tempDir);

			if (manifest.modFolders.length == 0) {
				fail(callbacks, 'Modpack içinde hiç mod klasörü bulunamadı.');
				return;
			}
		} else {
			// Manifest'i oku
			try {
				var raw = File.getContent(manifestPath);
				manifest = (Json.parse(raw) : ModpackManifest);
			} catch (e:Dynamic) {
				fail(callbacks, '_modpack.json okunamadı: ${e.message}');
				return;
			}

			// packId kontrolü
			if (manifest.packId != packId) {
				warn(callbacks, 'Manifest packId uyuşmuyor. '
					+ 'Beklenen: $packId, Gelen: ${manifest.packId}. '
					+ 'Devam ediliyor.');
				// Override et, kullanıcının seçtiği packId doğru kabul edilir
				manifest = overridePackId(manifest, packId);
			}

			// Mod klasörleri gerçekten var mı?
			for (folder in manifest.modFolders) {
				var folderPath = Path.join([tempDir, folder]);
				if (!FileSystem.exists(folderPath)) {
					warn(callbacks, 'Manifest\'te "$folder" var ama ZIP\'te yok. Atlanacak.');
				}
			}

			// Engine sürüm uyumluluğu
			if (manifest.minEngineVersion != null) {
				// Basit string karşılaştırma, VersionParser entegre edilebilir
				trace('[ModpackInstaller] minEngineVersion: ${manifest.minEngineVersion}');
			}
		}

		reportPhase(callbacks, Verifying, 1.0, "", "Doğrulama tamamlandı.");

		step_detectOldMods(packId, tempDir, manifest, callbacks);
	}

	// ─────────────────────────────────────────────
	//  Adım 4 — Eski Modları Tespit Et
	// ─────────────────────────────────────────────

	function step_detectOldMods(
		packId:String, tempDir:String,
		newManifest:ModpackManifest,
		callbacks:ModpackInstallCallbacks
	):Void {
		reportPhase(callbacks, InstallingMods, 0.0, "", "Eski modlar kontrol ediliyor...");

		if (checkCancelled(callbacks)) return;

		var foldersToRemove:Array<String> = [];
		var oldManifest = getInstalledManifest(packId);

		if (oldManifest != null) {
			trace('[ModpackInstaller] Önceki kurulum bulundu: v${oldManifest.version}');

			for (oldFolder in oldManifest.modFolders) {
				// Yeni modFolders listesinde yoksa silinecek
				if (newManifest.modFolders.indexOf(oldFolder) == -1) {
					foldersToRemove.push(oldFolder);
					trace('[ModpackInstaller] Kaldırılacak: $oldFolder');
				}
			}
		} else {
			trace('[ModpackInstaller] İlk kurulum, eski mod silinmeyecek.');
		}

		step_install(packId, tempDir, newManifest, foldersToRemove, callbacks);
	}

	// ─────────────────────────────────────────────
	//  Adım 5 — Mods Klasörüne Kur
	// ─────────────────────────────────────────────

	function step_install(
		packId:String, tempDir:String,
		manifest:ModpackManifest,
		foldersToRemove:Array<String>,
		callbacks:ModpackInstallCallbacks
	):Void {
		var modsDir = ModpackPaths.getModsDirectory();

		// mods/ klasörü yoksa oluştur
		try {
			if (!FileSystem.exists(modsDir))
				FileSystem.createDirectory(modsDir);
		} catch (e:Dynamic) {
			fail(callbacks, 'mods/ klasörü oluşturulamadı: ${e.message}');
			return;
		}

		var totalSteps = foldersToRemove.length + manifest.modFolders.length;
		var currentStep = 0;

		// ── a) Eski mod klasörlerini kaldır

		for (folder in foldersToRemove) {
			if (checkCancelled(callbacks)) return;

			var oldPath = Path.join([modsDir, folder]);
			if (FileSystem.exists(oldPath)) {
				reportPhase(
					callbacks, InstallingMods,
					totalSteps > 0 ? currentStep / totalSteps : 0.0,
					folder,
					'Kaldırılıyor: $folder'
				);
				deleteDirectory(oldPath);
				trace('[ModpackInstaller] Kaldırıldı: $oldPath');
			}
			currentStep++;
		}

		// ── b) Yeni mod klasörlerini kopyala

		for (folder in manifest.modFolders) {
			if (checkCancelled(callbacks)) return;

			var srcPath = Path.join([tempDir, folder]);
			var dstPath = Path.join([modsDir, folder]);

			if (!FileSystem.exists(srcPath)) {
				warn(callbacks, '"$folder" temp klasöründe bulunamadı, atlandı.');
				currentStep++;
				continue;
			}

			reportPhase(
				callbacks, InstallingMods,
				totalSteps > 0 ? currentStep / totalSteps : 0.0,
				folder,
				'Kuruluyor: $folder'
			);

			// Varsa üzerine yaz (önce sil)
			if (FileSystem.exists(dstPath)) {
				deleteDirectory(dstPath);
			}

			try {
				copyDirectory(srcPath, dstPath);
				trace('[ModpackInstaller] Kuruldu: $folder');
			} catch (e:Dynamic) {
				fail(callbacks, '"$folder" kopyalanamadı: ${e.message}');
				return;
			}

			currentStep++;
		}

		// ── c) Manifest'i kaydet

		try {
			var installedPath = ModpackPaths.getInstalledManifestPath(packId);
			var installedDir = ModpackPaths.getInstalledDirectory();

			if (!FileSystem.exists(installedDir))
				FileSystem.createDirectory(installedDir);

			File.saveContent(installedPath, Json.stringify(manifest, null, "  "));
			trace('[ModpackInstaller] Manifest kaydedildi: $installedPath');
		} catch (e:Dynamic) {
			// Manifest kaydedilemese bile kurulum başarılı sayılır
			// ama uyarı ver
			warn(callbacks, 'Manifest kaydedilemedi: ${e.message}');
		}

		reportPhase(callbacks, InstallingMods, 1.0, "", "Kurulum tamamlandı.");

		step_cleanup(packId, tempDir, manifest, callbacks);
	}

	// ─────────────────────────────────────────────
	//  Adım 6 — Temizlik
	// ─────────────────────────────────────────────

	function step_cleanup(
		packId:String, tempDir:String,
		manifest:ModpackManifest,
		callbacks:ModpackInstallCallbacks
	):Void {
		reportPhase(callbacks, Cleanup, 0.0, "", "Geçici dosyalar temizleniyor...");

		// Temp klasörünü sil
		try {
			deleteDirectory(tempDir);
			trace('[ModpackInstaller] Temp temizlendi: $tempDir');
		} catch (e:Dynamic) {
			// Kritik değil, sadece logla
			trace('[ModpackInstaller] Temp silinemedi: ${e.message}');
		}

		reportPhase(callbacks, Cleanup, 1.0, "", "Temizlik tamamlandı.");

		step_complete(manifest, callbacks);
	}

	// ─────────────────────────────────────────────
	//  Adım 7 — Tamamlandı
	// ─────────────────────────────────────────────

	function step_complete(manifest:ModpackManifest, callbacks:ModpackInstallCallbacks):Void {
		_installing = false;
		_cancelled = false;

		reportPhase(
			callbacks, Complete, 1.0, "",
			'${manifest.displayName} v${manifest.version} başarıyla kuruldu!'
		);

		trace('[ModpackInstaller] ✓ Kurulum başarılı: ${manifest.packId} v${manifest.version}');

		if (callbacks != null && callbacks.onComplete != null)
			callbacks.onComplete(manifest);
	}

	// ─────────────────────────────────────────────
	//  Progress Yardımcıları
	// ─────────────────────────────────────────────

	function reportPhase(
		callbacks:ModpackInstallCallbacks,
		phase:ModpackInstallPhase,
		phaseProgress:Float,
		currentFile:String,
		message:String
	):Void {
		if (callbacks == null || callbacks.onProgress == null) return;

		var overall = calcOverallProgress(phase, phaseProgress);

		callbacks.onProgress({
			phase: phase,
			phaseProgress: phaseProgress,
			overallProgress: overall,
			currentFile: currentFile != null ? currentFile : "",
			message: message != null ? message : ""
		});
	}

	function calcOverallProgress(phase:ModpackInstallPhase, phaseProgress:Float):Float {
		var base:Float = 0.0;

		switch (phase) {
			case Validating:
				base = 0.0;
				return base + WEIGHT_VALIDATING * phaseProgress;

			case Extracting:
				base = WEIGHT_VALIDATING;
				return base + WEIGHT_EXTRACTING * phaseProgress;

			case Verifying:
				base = WEIGHT_VALIDATING + WEIGHT_EXTRACTING;
				return base + WEIGHT_VERIFYING * phaseProgress;

			case InstallingMods:
				base = WEIGHT_VALIDATING + WEIGHT_EXTRACTING + WEIGHT_VERIFYING;
				return base + WEIGHT_INSTALLING * phaseProgress;

			case Cleanup:
				base = WEIGHT_VALIDATING + WEIGHT_EXTRACTING + WEIGHT_VERIFYING + WEIGHT_INSTALLING;
				return base + WEIGHT_CLEANUP * phaseProgress;

			case Complete:
				return 1.0;

			case Failed:
				return 0.0;
		}
	}

	// ─────────────────────────────────────────────
	//  Hata ve Durum Yardımcıları
	// ─────────────────────────────────────────────

	function fail(callbacks:ModpackInstallCallbacks, message:String):Void {
		_installing = false;
		_cancelled = false;

		trace('[ModpackInstaller] ✗ Hata: $message');

		reportPhase(callbacks, Failed, 0.0, "", message);

		if (callbacks != null && callbacks.onError != null)
			callbacks.onError(message);
	}

	function warn(callbacks:ModpackInstallCallbacks, message:String):Void {
		trace('[ModpackInstaller] ⚠ Uyarı: $message');

		if (callbacks != null && callbacks.onWarning != null)
			callbacks.onWarning(message);
	}

	function handleCancel(callbacks:ModpackInstallCallbacks):Void {
		_installing = false;
		_cancelled = false;

		trace('[ModpackInstaller] Kurulum iptal edildi.');

		if (callbacks != null && callbacks.onCancelled != null)
			callbacks.onCancelled();
	}

	function checkCancelled(callbacks:ModpackInstallCallbacks):Bool {
		if (_cancelled) {
			handleCancel(callbacks);
			return true;
		}
		return false;
	}

	function formatError(error:ExtractError):String {
		return switch (error) {
			case FileNotFound(path): 'Dosya bulunamadı: $path';
			case CorruptArchive(detail): 'Bozuk arşiv: $detail';
			case DiskFull(req, avail): 'Disk dolu. Gerekli: ${req} B, Mevcut: ${avail} B';
			case PermissionDenied(path): 'İzin reddedildi: $path';
			case PathTraversal(entry): 'Güvenlik ihlali: $entry';
			case UnsupportedFormat(detail): 'Desteklenmeyen format: $detail';
			case NotSupported(detail): 'Desteklenmiyor: $detail';
			case CommandFailed(cmd, code, err): 'Komut hatası ($cmd, exit $code): $err';
			case Cancelled: 'İptal edildi.';
			case Unknown(msg): 'Bilinmeyen hata: $msg';
		}
	}

	// ─────────────────────────────────────────────
	//  Manifest Yardımcıları
	// ─────────────────────────────────────────────

	/**
	 * _modpack.json yoksa temp klasörünü tarayıp
	 * otomatik manifest oluşturur.
	 */
	function buildAutoManifest(packId:String, tempDir:String):ModpackManifest {
		var folders:Array<String> = [];

		try {
			for (entry in FileSystem.readDirectory(tempDir)) {
				// Gizli ve sistem klasörlerini atla
				if (StringTools.startsWith(entry, ".")) continue;
				if (StringTools.startsWith(entry, "_")) continue;

				var fullPath = Path.join([tempDir, entry]);
				if (FileSystem.isDirectory(fullPath)) {
					folders.push(entry);
				}
			}
		} catch (e:Dynamic) {
			trace('[ModpackInstaller] Auto manifest tarama hatası: ${e.message}');
		}

		trace('[ModpackInstaller] Auto manifest oluşturuldu. Klasörler: $folders');

		return {
			packId: packId,
			displayName: capitalize(packId) + " Modpack",
			version: "unknown",
			engineVersion: "unknown",
			modFolders: folders
		};
	}

	function overridePackId(manifest:ModpackManifest, packId:String):ModpackManifest {
		return {
			packId: packId,
			displayName: manifest.displayName,
			version: manifest.version,
			engineVersion: manifest.engineVersion,
			modFolders: manifest.modFolders,
			author: manifest.author,
			description: manifest.description,
			totalFileCount: manifest.totalFileCount,
			totalSizeBytes: manifest.totalSizeBytes,
			minEngineVersion: manifest.minEngineVersion,
			maxEngineVersion: manifest.maxEngineVersion,
			checksum: manifest.checksum,
			changelog: manifest.changelog
		};
	}

	function capitalize(s:String):String {
		if (s == null || s.length == 0) return s;
		return s.charAt(0).toUpperCase() + s.substr(1);
	}

	// ─────────────────────────────────────────────
	//  Dosya Sistemi Yardımcıları
	// ─────────────────────────────────────────────

	function deleteDirectory(path:String):Void {
		if (path == null || !FileSystem.exists(path)) return;

		try {
			if (FileSystem.isDirectory(path)) {
				for (entry in FileSystem.readDirectory(path)) {
					var fullPath = Path.join([path, entry]);
					if (FileSystem.isDirectory(fullPath))
						deleteDirectory(fullPath);
					else
						FileSystem.deleteFile(fullPath);
				}
				FileSystem.deleteDirectory(path);
			} else {
				FileSystem.deleteFile(path);
			}
		} catch (e:Dynamic) {
			trace('[ModpackInstaller] Silme hatası: $path — ${e.message}');
		}
	}

	function copyDirectory(src:String, dst:String):Void {
		if (!FileSystem.exists(dst))
			FileSystem.createDirectory(dst);

		for (entry in FileSystem.readDirectory(src)) {
			var srcPath = Path.join([src, entry]);
			var dstPath = Path.join([dst, entry]);

			if (FileSystem.isDirectory(srcPath))
				copyDirectory(srcPath, dstPath);
			else
				File.copy(srcPath, dstPath);
		}
	}

	#else
	// ─────────────────────────────────────────────
	//  sys yoksa stub
	// ─────────────────────────────────────────────

	public function new() {}

	public function install(zipPath:String, packId:String, callbacks:ModpackInstallCallbacks):Void {
		if (callbacks != null && callbacks.onError != null)
			callbacks.onError("Bu platformda kurulum desteklenmiyor.");
	}

	public function cancel():Void {}
	public function isInstalling():Bool return false;
	public function isInstalled(packId:String):Bool return false;
	public function getInstalledManifest(packId:String):Null<ModpackManifest> return null;
	#end
}