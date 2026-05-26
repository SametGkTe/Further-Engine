package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import backend.modpack.ModpackTypes;
import backend.modpack.ModpackPaths;
import backend.modpack.ModpackInstaller;
import backend.modpack.DownloadManager;

enum UpdateScreen {
	ModpackList;
	Downloading;
	Installing;
	Complete;
	Error;
}

class UpdateSubState extends MusicBeatSubstate {

	// ─── State ───
	var currentScreen:UpdateScreen = ModpackList;
	var selectedIndex:Int = 0;

	// ─── Modpack bilgileri ───
	var modpackUpdates:Array<{packId:String, displayName:String, version:String, downloadUrl:String}> = [];

	// ─── Sistemler ───
	var downloader:DownloadManager;
	var installer:ModpackInstaller;

	// ─── UI ───
	var bg:FlxSprite;
	var titleText:FlxText;
	var contentText:FlxText;
	var statusText:FlxText;
	var controlsText:FlxText;
	var progressBarBg:FlxSprite;
	var progressBar:FlxSprite;
	var progressPercent:FlxText;

	// ─── İlerleme ───
	var currentProgress:Float = 0.0;
	var targetProgress:Float = 0.0;

	// ─────────────────────────────────────────────
	//  Constructor
	// ─────────────────────────────────────────────

	public function new(
		modpacks:Array<{packId:String, displayName:String, version:String, downloadUrl:String}>
	) {
		super();

		if (modpacks != null)
			modpackUpdates = modpacks;

		downloader = new DownloadManager();
		installer = new ModpackInstaller();
	}

	// ─────────────────────────────────────────────
	//  Create
	// ─────────────────────────────────────────────

	override function create() {
		super.create();

		// Arkaplan
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		add(bg);
		FlxTween.tween(bg, {alpha: 0.85}, 0.3);

		// Başlık
		titleText = new FlxText(0, 30, FlxG.width, "");
		titleText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER);
		titleText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(titleText);

		// İçerik
		contentText = new FlxText(40, 100, FlxG.width - 80, "");
		contentText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		contentText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		add(contentText);

		// Progress bar arka plan
		progressBarBg = new FlxSprite(40, FlxG.height - 160);
		progressBarBg.makeGraphic(FlxG.width - 80, 24, FlxColor.fromRGB(30, 30, 30));
		progressBarBg.visible = false;
		add(progressBarBg);

		// Progress bar
		progressBar = new FlxSprite(40, FlxG.height - 160);
		progressBar.makeGraphic(1, 24, FlxColor.LIME);
		progressBar.visible = false;
		add(progressBar);

		// Yüzde
		progressPercent = new FlxText(0, FlxG.height - 158, FlxG.width, "0%");
		progressPercent.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
		progressPercent.visible = false;
		add(progressPercent);

		// Durum
		statusText = new FlxText(0, FlxG.height - 120, FlxG.width, "");
		statusText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.GRAY, CENTER);
		add(statusText);

		// Kontroller
		controlsText = new FlxText(0, FlxG.height - 50, FlxG.width, "");
		controlsText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.LIME, CENTER);
		add(controlsText);

		showModpackList();
	}

	// ─────────────────────────────────────────────
	//  Update
	// ─────────────────────────────────────────────

	override function update(elapsed:Float) {
		super.update(elapsed);

		// Progress bar yumuşak animasyon
		if (progressBar.visible) {
			currentProgress += (targetProgress - currentProgress) * elapsed * 6;
			var barWidth:Int = Std.int(Math.max(1, Math.round((FlxG.width - 80) * currentProgress)));
			progressBar.makeGraphic(barWidth, 24, FlxColor.LIME);
			progressPercent.text = '${Math.round(currentProgress * 100)}%';
		}

		switch (currentScreen) {
			case ModpackList:
				handleModpackListInput();
			case Downloading | Installing:
				handleProgressInput();
			case Complete:
				handleCompleteInput();
			case Error:
				handleErrorInput();
		}
	}

	// ─────────────────────────────────────────────
	//  Ekranlar
	// ─────────────────────────────────────────────

	function showModpackList():Void {
		currentScreen = ModpackList;
		selectedIndex = 0;

		titleText.text = "Modpack Güncellemeleri";
		titleText.color = FlxColor.YELLOW;

		hideProgress();
		refreshModpackListDisplay();

		controlsText.text = "[↑/↓] Seç  |  [ENTER] Kur  |  [ESC] Kapat";
	}

	function showDownloading(fileName:String):Void {
		currentScreen = Downloading;

		titleText.text = "İndiriliyor...";
		titleText.color = FlxColor.WHITE;

		contentText.text = 'Dosya: $fileName\n\nLütfen bekleyin...';

		showProgress();
		currentProgress = 0.0;
		targetProgress = 0.0;

		statusText.text = "";
		controlsText.text = "[ESC] İptal";
	}

	function showInstalling(displayName:String):Void {
		currentScreen = Installing;

		titleText.text = "Kuruluyor...";
		titleText.color = FlxColor.WHITE;

		contentText.text = 'Kuruluyor: $displayName\n\nLütfen bekleyin...';

		showProgress();
		currentProgress = 0.0;
		targetProgress = 0.0;

		statusText.text = "";
		controlsText.text = "[ESC] İptal";
	}

	function showComplete(message:String):Void {
		currentScreen = Complete;

		titleText.text = "Tamamlandı!";
		titleText.color = FlxColor.LIME;

		contentText.text = message;

		hideProgress();
		statusText.text = "";
		controlsText.text = "[ENTER] Tamam";
	}

	function showError(message:String):Void {
		currentScreen = Error;

		titleText.text = "Hata!";
		titleText.color = FlxColor.RED;

		contentText.text = message;

		hideProgress();
		statusText.text = "";
		controlsText.text = "[ENTER] Tekrar Dene  |  [ESC] Kapat";
	}

	// ─────────────────────────────────────────────
	//  Girdi
	// ─────────────────────────────────────────────

	function handleModpackListInput():Void {
		if (modpackUpdates.length == 0) {
			if (FlxG.keys.justPressed.ESCAPE)
				close();
			return;
		}

		if (FlxG.keys.justPressed.UP) {
			selectedIndex = (selectedIndex - 1 + modpackUpdates.length) % modpackUpdates.length;
			refreshModpackListDisplay();
		}

		if (FlxG.keys.justPressed.DOWN) {
			selectedIndex = (selectedIndex + 1) % modpackUpdates.length;
			refreshModpackListDisplay();
		}

		if (FlxG.keys.justPressed.ENTER)
			startDownload(selectedIndex);

		if (FlxG.keys.justPressed.ESCAPE)
			close();
	}

	function handleProgressInput():Void {
		if (FlxG.keys.justPressed.ESCAPE) {
			downloader.cancel();
			installer.cancel();
			showModpackList();
		}
	}

	function handleCompleteInput():Void {
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE)
			close();
	}

	function handleErrorInput():Void {
		if (FlxG.keys.justPressed.ENTER)
			showModpackList();

		if (FlxG.keys.justPressed.ESCAPE)
			close();
	}

	// ─────────────────────────────────────────────
	//  Aksiyon
	// ─────────────────────────────────────────────

	function startDownload(index:Int):Void {
		if (index < 0 || index >= modpackUpdates.length) return;

		var mp = modpackUpdates[index];

		if (mp.downloadUrl == null || mp.downloadUrl.length == 0) {
			showError('${mp.displayName} için indirme linki bulunamadı.');
			return;
		}

		var fileName = '${mp.packId}-v${mp.version}.zip';
		var savePath = ModpackPaths.getDownloadDirectory() + fileName;

		showDownloading(fileName);

		downloader.downloadFromGitHub(mp.downloadUrl, savePath, {
			onProgress: function(progress) {
				targetProgress = progress.percent;
				statusText.text = 'İndiriliyor: ${formatBytes(progress.downloadedBytes)} / ${formatBytes(progress.totalBytes)}';
			},

			onComplete: function(path) {
				startInstall(path, mp.packId, mp.displayName);
			},

			onError: function(error) {
				showError('İndirme başarısız:\n\n$error');
			},

			onCancelled: function() {
				showModpackList();
			}
		});
	}

	function startInstall(zipPath:String, packId:String, displayName:String):Void {
		showInstalling(displayName);

		installer.install(zipPath, packId, {
			onProgress: function(progress:ModpackInstallProgress) {
				targetProgress = progress.overallProgress;
				contentText.text = 'Kuruluyor: $displayName\n\n'
					+ 'Aşama: ${phaseToString(progress.phase)}\n'
					+ (progress.currentFile.length > 0 ? 'Dosya: ${progress.currentFile}' : '');
				statusText.text = progress.message;
			},

			onComplete: function(manifest:ModpackManifest) {
				// ZIP temizle
				#if sys
				try {
					if (sys.FileSystem.exists(zipPath))
						sys.FileSystem.deleteFile(zipPath);
				} catch (_) {}
				#end

				showComplete(
					'${manifest.displayName} başarıyla kuruldu!\n\n'
					+ 'Sürüm: v${manifest.version}\n'
					+ 'Kurulan mod sayısı: ${manifest.modFolders.length}'
				);
			},

			onError: function(error) {
				showError('Kurulum başarısız:\n\n$error');
			},

			onWarning: function(warning) {
				trace('[UpdateSubState] Uyarı: $warning');
			},

			onCancelled: function() {
				showModpackList();
			}
		});
	}

	// ─────────────────────────────────────────────
	//  UI Yardımcıları
	// ─────────────────────────────────────────────

	function refreshModpackListDisplay():Void {
		if (modpackUpdates.length == 0) {
			contentText.text = "Modpack güncellemesi bulunamadı.";
			return;
		}

		var content = "";
		for (i in 0...modpackUpdates.length) {
			var mp = modpackUpdates[i];
			var prefix = i == selectedIndex ? "► " : "  ";
			content += '$prefix${mp.displayName}  →  v${mp.version}\n';
		}

		contentText.text = content;
	}

	function showProgress():Void {
		progressBarBg.visible = true;
		progressBar.visible = true;
		progressPercent.visible = true;
	}

	function hideProgress():Void {
		progressBarBg.visible = false;
		progressBar.visible = false;
		progressPercent.visible = false;
	}

	function phaseToString(phase:ModpackInstallPhase):String {
		return switch (phase) {
			case Validating: "Doğrulanıyor";
			case Extracting: "Çıkarılıyor";
			case Verifying: "Kontrol ediliyor";
			case InstallingMods: "Kuruluyor";
			case Cleanup: "Temizleniyor";
			case Complete: "Tamamlandı";
			case Failed: "Hata";
		};
	}

	function formatBytes(bytes:Float):String {
		if (bytes <= 0) return "0 B";
		if (bytes < 1024) return '${Math.round(bytes)} B';
		if (bytes < 1024 * 1024) return '${Math.round(bytes / 1024)} KB';
		if (bytes < 1024 * 1024 * 1024) return '${Math.round(bytes / (1024 * 1024))} MB';
		return '${Math.round(bytes / (1024 * 1024 * 1024) * 10) / 10} GB';
	}
}