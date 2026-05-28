package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxGradient;
import haxe.Json;
import backend.update.UpdateChecker;
import backend.update.UpdateConfig;
import backend.modpack.ModpackPaths;
import backend.modpack.ModpackInstaller;
import backend.modpack.ModpackTypes;
import backend.modpack.DownloadManager;

enum UpdateScreenState {
	Browse;
	Downloading;
	Installing;
	Complete;
	Error;
}

class UpdateState extends MusicBeatState {
	// ─── Veri ───
	var modpackUpdates:Array<Dynamic> = [];
	var selectedIndex:Int = 0;

	// ─── Sistemler ───
	var downloader:DownloadManager;
	var installer:ModpackInstaller;

	// ─── Durum ───
	var screenState:UpdateScreenState = Browse;
	var currentProgress:Float = 0.0;
	var targetProgress:Float = 0.0;

	// ─── UI ───
	var bg:FlxSprite;
	var bgGradient:FlxSprite;
	var headerPanel:FlxSprite;
	var headerGlow:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var contentText:FlxText;
	var statusText:FlxText;
	var controlsText:FlxText;
	var progressBarBg:FlxSprite;
	var progressBar:FlxSprite;
	var progressPercent:FlxText;

	static inline final ACCENT:Int = 0xFF0D9488;

	// ─────────────────────────────────────────────
	//  Constructor - güncellemeler dışarıdan verilir
	// ─────────────────────────────────────────────

	public function new(updates:Array<Dynamic>) {
		super();
		modpackUpdates = updates != null ? updates : [];
	}

	// ─────────────────────────────────────────────
	//  Create
	// ─────────────────────────────────────────────

	override function create() {
		super.create();

		downloader = new DownloadManager();
		installer = new ModpackInstaller();

		// Arka plan
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF080812);
		add(bg);

		bgGradient = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[0xFF0d1117, 0xFF0a0e1a, 0xFF070b14],
			1, 120
		);
		bgGradient.alpha = 0.97;
		add(bgGradient);

		// Header
		headerPanel = new FlxSprite(0, 0).makeGraphic(FlxG.width, 80, 0xEE000000);
		add(headerPanel);

		headerGlow = new FlxSprite(0, 77).makeGraphic(FlxG.width, 3, ACCENT);
		headerGlow.alpha = 0.8;
		add(headerGlow);

		titleText = new FlxText(30, 10, FlxG.width - 60, "Modpack Güncellemeleri", 28);
		titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.YELLOW, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		subtitleText = new FlxText(30, 48, FlxG.width - 60, '${modpackUpdates.length} güncelleme mevcut', 14);
		subtitleText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFAABBBB, LEFT);
		add(subtitleText);

		// İçerik
		contentText = new FlxText(40, 100, FlxG.width - 80, "", 16);
		contentText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		contentText.borderSize = 1;
		add(contentText);

		// Progress bar
		progressBarBg = new FlxSprite(40, FlxG.height - 140).makeGraphic(FlxG.width - 80, 24, 0xFF1A1A2E);
		progressBarBg.visible = false;
		add(progressBarBg);

		progressBar = new FlxSprite(40, FlxG.height - 140).makeGraphic(1, 24, ACCENT);
		progressBar.visible = false;
		add(progressBar);

		progressPercent = new FlxText(40, FlxG.height - 138, FlxG.width - 80, "0%", 14);
		progressPercent.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
		progressPercent.visible = false;
		add(progressPercent);

		// Status
		statusText = new FlxText(0, FlxG.height - 110, FlxG.width, "", 14);
		statusText.setFormat(Paths.font("vcr.ttf"), 14, 0xFF667788, CENTER);
		add(statusText);

		// Controls
		controlsText = new FlxText(0, FlxG.height - 50, FlxG.width, "", 14);
		controlsText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.LIME, CENTER);
		add(controlsText);

		// Giriş
		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);

		showBrowse();
	}

	// ─────────────────────────────────────────────
	//  Update
	// ─────────────────────────────────────────────

	override function update(elapsed:Float) {
		super.update(elapsed);

		// Progress animasyonu
		if (progressBar.visible) {
			currentProgress += (targetProgress - currentProgress) * elapsed * 6;
			var pw = FlxG.width - 80;
			var barW:Int = Std.int(Math.max(1, pw * currentProgress));
			progressBar.makeGraphic(barW, 24, ACCENT);
			progressPercent.text = '${Math.round(currentProgress * 100)}%';
		}

		switch (screenState) {
			case Browse:
				handleBrowseInput();
			case Downloading | Installing:
				if (FlxG.keys.justPressed.ESCAPE) {
					downloader.cancel();
					installer.cancel();
					screenState = Browse;
					hideProgress();
					showBrowse();
				}
			case Complete:
				handleCompleteInput();
			case Error:
				handleErrorInput();
		}
	}

	// ─────────────────────────────────────────────
	//  Ekranlar
	// ─────────────────────────────────────────────

	function showBrowse():Void {
		screenState = Browse;
		hideProgress();
		refreshList();
		controlsText.text = "[↑/↓] Seç  |  [ENTER] Kur  |  [ESC] Atla (Ana Menü)";
	}

	function refreshList():Void {
		if (modpackUpdates.length == 0) {
			contentText.text = "Güncelleme bulunamadı.";
			return;
		}

		var content = "";

		for (i in 0...modpackUpdates.length) {
			var mp:Dynamic = modpackUpdates[i];
			var prefix = i == selectedIndex ? "► " : "  ";
			var name:String = mp.displayName != null ? mp.displayName : mp.id;
			var ver:String = mp.versionLabel != null ? mp.versionLabel : mp.version;
			var mode:String = mp.downloadMode != null ? mp.downloadMode : "direct";
			var modeTag = mode == "external" ? " [Tarayıcı]" : "";

			content += '$prefix$name  →  v$ver$modeTag\n';
		}

		contentText.text = content;
	}

	function showDownloading(fileName:String):Void {
		screenState = Downloading;
		showProgress();
		currentProgress = 0;
		targetProgress = 0;
		contentText.text = 'İndiriliyor: $fileName\n\nLütfen bekleyin...';
		controlsText.text = "[ESC] İptal";
	}

	function showInstalling(displayName:String):Void {
		screenState = Installing;
		contentText.text = 'Kuruluyor: $displayName\n\nLütfen bekleyin...';
		controlsText.text = "[ESC] İptal";
	}

	function showComplete(message:String):Void {
		screenState = Complete;
		hideProgress();
		titleText.text = "Tamamlandı!";
		titleText.color = FlxColor.LIME;
		contentText.text = message;
		controlsText.text = "[ENTER] Ana Menü";
	}

	function showError(message:String):Void {
		screenState = Error;
		hideProgress();
		titleText.text = "Hata!";
		titleText.color = FlxColor.RED;
		contentText.text = message;
		controlsText.text = "[ENTER] Tekrar Dene  |  [ESC] Ana Menü";
	}

	// ─────────────────────────────────────────────
	//  Girdi
	// ─────────────────────────────────────────────

	function handleBrowseInput():Void {
		if (FlxG.keys.justPressed.ESCAPE) {
			goToMainMenu();
			return;
		}

		if (modpackUpdates.length == 0) return;

		if (FlxG.keys.justPressed.UP) {
			selectedIndex--;
			if (selectedIndex < 0) selectedIndex = modpackUpdates.length - 1;
			refreshList();
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if (FlxG.keys.justPressed.DOWN) {
			selectedIndex++;
			if (selectedIndex >= modpackUpdates.length) selectedIndex = 0;
			refreshList();
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if (FlxG.keys.justPressed.ENTER) {
			startAction(selectedIndex);
		}
	}

	function handleCompleteInput():Void {
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE) {
			goToMainMenu();
		}
	}

	function handleErrorInput():Void {
		if (FlxG.keys.justPressed.ENTER) {
			titleText.text = "Modpack Güncellemeleri";
			titleText.color = FlxColor.YELLOW;
			showBrowse();
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			goToMainMenu();
		}
	}

	// ─────────────────────────────────────────────
	//  Aksiyon
	// ─────────────────────────────────────────────

	function startAction(index:Int):Void {
		if (index < 0 || index >= modpackUpdates.length) return;

		var mp:Dynamic = modpackUpdates[index];
		var mode:String = mp.downloadMode != null ? mp.downloadMode : "direct";

		if (mode == "external") {
			var pageUrl:String = mp.externalPageUrl != null ? mp.externalPageUrl : "";
			if (pageUrl.length > 0) {
				FlxG.openURL(pageUrl);
				showComplete('${mp.displayName} tarayıcıda açıldı.');
			} else {
				showError("Harici indirme linki bulunamadı.");
			}
			return;
		}

		var directUrl:String = mp.directDownloadUrl != null ? mp.directDownloadUrl : "";
		if (directUrl.length == 0) {
			showError('${mp.displayName} için indirme linki bulunamadı.');
			return;
		}

		startDownload(mp.id, mp.version, mp.displayName, directUrl);
	}

	function startDownload(packId:String, version:String, displayName:String, url:String):Void {
		var fileName = '$packId-v$version.zip';
		var savePath = ModpackPaths.getDownloadDirectory() + fileName;

		showDownloading(fileName);

		downloader.download(url, savePath, {
			onProgress: function(progress) {
				targetProgress = progress.percent;
			},
			onComplete: function(path) {
				startInstall(path, packId, displayName);
			},
			onError: function(error) {
				showError('İndirme hatası:\n\n$error');
			},
			onCancelled: function() {
				showBrowse();
			}
		});
	}

	function startInstall(zipPath:String, packId:String, displayName:String):Void {
		showInstalling(displayName);

		installer.install(zipPath, packId, {
			onProgress: function(progress:ModpackInstallProgress) {
				targetProgress = progress.overallProgress;
				statusText.text = progress.message;
			},
			onComplete: function(manifest:ModpackManifest) {
				#if sys
				try {
					if (sys.FileSystem.exists(zipPath))
						sys.FileSystem.deleteFile(zipPath);
				} catch (_) {}
				#end

				showComplete(
					'${manifest.displayName} v${manifest.version} başarıyla kuruldu!\n\n' +
					'Kurulan mod sayısı: ${manifest.modFolders.length}'
				);
			},
			onError: function(error) {
				showError('Kurulum hatası:\n\n$error');
			},
			onWarning: function(warning) {
				trace('[UpdateState] Uyarı: $warning');
			},
			onCancelled: function() {
				showBrowse();
			}
		});
	}

	// ─────────────────────────────────────────────
	//  Geçiş
	// ─────────────────────────────────────────────

	function goToMainMenu():Void {
		FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function() {
			MusicBeatState.switchState(new MainMenuState());
		});
	}

	// ─────────────────────────────────────────────
	//  UI Yardımcı
	// ─────────────────────────────────────────────

	function showProgress():Void {
		progressBarBg.visible = true;
		progressBar.visible = true;
		progressPercent.visible = true;
	}

	function hideProgress():Void {
		progressBarBg.visible = false;
		progressBar.visible = false;
		progressPercent.visible = false;
		statusText.text = "";
	}
}