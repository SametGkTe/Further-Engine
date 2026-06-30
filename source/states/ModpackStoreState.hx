package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import backend.update.UpdateChecker;
import backend.update.UpdateConfig;
import backend.modpack.ModpackPaths;
import backend.modpack.ModpackInstaller;
import backend.modpack.ModpackTypes;
import backend.modpack.DownloadManager;

enum StoreScreenState {
	Loading;
	Browse;
	Detail;
	Downloading;
	Installing;
	Complete;
	Error;
}

class ModpackStoreState extends MusicBeatState {
	// ─── Veri ───
	var allPacks:Array<Dynamic> = [];
	var selectedIndex:Int = 0;
	var scrollOffset:Int = 0;
	var maxVisible:Int = 8;

	// ─── Sistemler ───
	var downloader:DownloadManager;
	var installer:ModpackInstaller;

	// ─── Durum ───
	var screenState:StoreScreenState = Loading;
	var currentProgress:Float = 0.0;
	var targetProgress:Float = 0.0;

	// ─── UI ───
	var bg:FlxSprite;
	var headerBg:FlxSprite;
	var headerLine:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var listTexts:Array<FlxText> = [];
	var statusIndicators:Array<FlxText> = [];

	// Detay paneli
	var detailBg:FlxSprite;
	var detailName:FlxText;
	var detailAuthor:FlxText;
	var detailDesc:FlxText;
	var detailVersion:FlxText;
	var detailSize:FlxText;
	var detailModCount:FlxText;
	var detailChangelog:FlxText;
	var detailStatus:FlxText;
	var detailControls:FlxText;

	// Progress
	var barBg:FlxSprite;
	var barFill:FlxSprite;
	var barBorder:FlxSprite;
	var percentText:FlxText;
	var sizeText:FlxText;
	var speedText:FlxText;
	var phaseText:FlxText;

	// Yükleniyor
	var loadingText:FlxText;
	var loadingDots:Int = 0;
	var loadingTimer:Float = 0;

	// Kontrol bilgisi
	var controlsText:FlxText;

	// Hata
	var errorText:FlxText;

	static inline final ACCENT:Int = 0xFF14B8A6;
	static inline final INSTALLED_COLOR:Int = 0xFF22C55E;
	static inline final UPDATE_COLOR:Int = 0xFFEAB308;
	static inline final NEW_COLOR:Int = 0xFF3B82F6;
	static inline final BAR_HEIGHT:Int = 8;
	static inline final BAR_MARGIN:Int = 60;
	static inline final ITEM_HEIGHT:Int = 50;
	static inline final LIST_START_Y:Int = 90;

	// ─────────────────────────────────────────────
	//  Create
	// ─────────────────────────────────────────────

	override function create() {
		super.create();

		downloader = new DownloadManager();
		installer = new ModpackInstaller();

		// ── Arkaplan ──
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		add(bg);

		// ── Header ──
		headerBg = new FlxSprite(0, 0).makeGraphic(FlxG.width, 70, 0xFF0A0A0A);
		add(headerBg);

		headerLine = new FlxSprite(0, 68).makeGraphic(FlxG.width, 2, ACCENT);
		headerLine.alpha = 0.6;
		add(headerLine);

		titleText = new FlxText(30, 12, FlxG.width - 60, "Modpack Mağazası", 28);
		titleText.setFormat("VCR OSD Mono", 28, FlxColor.WHITE, LEFT);
		add(titleText);

		subtitleText = new FlxText(30, 45, FlxG.width - 60, "Yükleniyor...", 13);
		subtitleText.setFormat("VCR OSD Mono", 13, 0xFF666666, LEFT);
		add(subtitleText);

		// ── Yükleniyor ekranı ──
		loadingText = new FlxText(0, 0, FlxG.width, "Modpackler yükleniyor...", 20);
		loadingText.setFormat("VCR OSD Mono", 20, 0xFF888888, CENTER);
		loadingText.screenCenter();
		add(loadingText);

		// ── Hata ekranı ──
		errorText = new FlxText(60, 0, FlxG.width - 120, "", 16);
		errorText.setFormat("VCR OSD Mono", 16, 0xFFEF4444, CENTER);
		errorText.screenCenter();
		errorText.visible = false;
		add(errorText);

		// ── Alt kontrol bilgisi ──
		controlsText = new FlxText(0, FlxG.height - 40, FlxG.width, "", 13);
		controlsText.setFormat("VCR OSD Mono", 13, 0xFF555555, CENTER);
		add(controlsText);

		// ── Progress bar (başlangıçta gizli) ──
		var barY:Int = FlxG.height - 90;

		barBorder = new FlxSprite(BAR_MARGIN - 1, barY - 1).makeGraphic(FlxG.width - (BAR_MARGIN * 2) + 2, BAR_HEIGHT + 2, 0xFF333333);
		barBorder.visible = false;
		add(barBorder);

		barBg = new FlxSprite(BAR_MARGIN, barY).makeGraphic(FlxG.width - (BAR_MARGIN * 2), BAR_HEIGHT, 0xFF1A1A1A);
		barBg.visible = false;
		add(barBg);

		barFill = new FlxSprite(BAR_MARGIN, barY).makeGraphic(1, BAR_HEIGHT, ACCENT);
		barFill.visible = false;
		add(barFill);

		percentText = new FlxText(0, barY - 20, FlxG.width, "", 13);
		percentText.setFormat("VCR OSD Mono", 13, FlxColor.WHITE, CENTER);
		percentText.visible = false;
		add(percentText);

		sizeText = new FlxText(0, barY + BAR_HEIGHT + 4, FlxG.width - BAR_MARGIN, "", 11);
		sizeText.setFormat("VCR OSD Mono", 11, 0xFF555555, RIGHT);
		sizeText.visible = false;
		add(sizeText);

		speedText = new FlxText(BAR_MARGIN, barY + BAR_HEIGHT + 4, FlxG.width / 2, "", 11);
		speedText.setFormat("VCR OSD Mono", 11, 0xFF555555, LEFT);
		speedText.visible = false;
		add(speedText);

		phaseText = new FlxText(0, 0, FlxG.width, "", 24);
		phaseText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER);
		phaseText.screenCenter();
		phaseText.y -= 30;
		phaseText.visible = false;
		add(phaseText);

		// ── Detay paneli sprite'ları ──
		createDetailPanel();

		// ── Giriş ──
		FlxG.camera.fade(FlxColor.BLACK, 0.3, true);

		// ── Veri çek ──
		fetchStore();
	}

	// ─────────────────────────────────────────────
	//  Detay Paneli Oluştur
	// ─────────────────────────────────────────────

	function createDetailPanel():Void {
		detailBg = new FlxSprite(40, 80).makeGraphic(FlxG.width - 80, FlxG.height - 180, 0xFF0D0D0D);
		detailBg.visible = false;
		add(detailBg);

		var dx:Int = 60;
		var dw:Int = FlxG.width - 120;

		detailName = new FlxText(dx, 100, dw, "", 26);
		detailName.setFormat("VCR OSD Mono", 26, FlxColor.WHITE, LEFT);
		detailName.visible = false;
		add(detailName);

		detailAuthor = new FlxText(dx, 135, dw, "", 14);
		detailAuthor.setFormat("VCR OSD Mono", 14, ACCENT, LEFT);
		detailAuthor.visible = false;
		add(detailAuthor);

		detailVersion = new FlxText(dx, 158, dw / 2, "", 13);
		detailVersion.setFormat("VCR OSD Mono", 13, 0xFF888888, LEFT);
		detailVersion.visible = false;
		add(detailVersion);

		detailSize = new FlxText(dx + Std.int(dw / 2), 158, dw / 2, "", 13);
		detailSize.setFormat("VCR OSD Mono", 13, 0xFF888888, RIGHT);
		detailSize.visible = false;
		add(detailSize);

		detailModCount = new FlxText(dx, 178, dw, "", 13);
		detailModCount.setFormat("VCR OSD Mono", 13, 0xFF666666, LEFT);
		detailModCount.visible = false;
		add(detailModCount);

		detailDesc = new FlxText(dx, 210, dw, "", 15);
		detailDesc.setFormat("VCR OSD Mono", 15, 0xFFCCCCCC, LEFT);
		detailDesc.visible = false;
		add(detailDesc);

		detailChangelog = new FlxText(dx, 280, dw, "", 13);
		detailChangelog.setFormat("VCR OSD Mono", 13, 0xFF777777, LEFT);
		detailChangelog.visible = false;
		add(detailChangelog);

		detailStatus = new FlxText(dx, FlxG.height - 150, dw, "", 16);
		detailStatus.setFormat("VCR OSD Mono", 16, INSTALLED_COLOR, CENTER);
		detailStatus.visible = false;
		add(detailStatus);

		detailControls = new FlxText(0, FlxG.height - 120, FlxG.width, "", 13);
		detailControls.setFormat("VCR OSD Mono", 13, 0xFF555555, CENTER);
		detailControls.visible = false;
		add(detailControls);
	}

	// ─────────────────────────────────────────────
	//  Veri Çekme
	// ─────────────────────────────────────────────

	function fetchStore():Void {
		screenState = Loading;

		var checker = UpdateChecker.instance;
		checker.onError = function(err) {
			showError('Bağlantı hatası:\n$err');
		};

		checker.fetchStoreList(function(packs) {
			if (packs == null || packs.length == 0) {
				showError("Hiç modpack bulunamadı.");
				return;
			}

			allPacks = cast packs;
			loadingText.visible = false;
			showBrowse();
		});
	}

	// ─────────────────────────────────────────────
	//  Liste Ekranı
	// ─────────────────────────────────────────────

	function showBrowse():Void {
		screenState = Browse;
		hideDetail();
		hideProgress();

		subtitleText.text = '${allPacks.length} modpack mevcut';
		controlsText.text = "[↑/↓] Seç  |  [ENTER] Detay  |  [ESC] Geri";

		refreshList();
	}

	function refreshList():Void {
		// Eski text'leri temizle
		for (t in listTexts) {
			remove(t, true);
			t.destroy();
		}
		listTexts = [];

		for (t in statusIndicators) {
			remove(t, true);
			t.destroy();
		}
		statusIndicators = [];

		// Scroll sınırları
		if (selectedIndex < scrollOffset)
			scrollOffset = selectedIndex;
		if (selectedIndex >= scrollOffset + maxVisible)
			scrollOffset = selectedIndex - maxVisible + 1;

		var endIdx:Int = Std.int(Math.min(allPacks.length, scrollOffset + maxVisible));

		for (i in scrollOffset...endIdx) {
			var mp:Dynamic = allPacks[i];
			var isSelected:Bool = (i == selectedIndex);
			var slotY:Int = LIST_START_Y + (i - scrollOffset) * ITEM_HEIGHT;

			// Modpack adı
			var name:String = mp.displayName != null ? mp.displayName : mp.id;
			var ver:String = mp.versionLabel != null ? mp.versionLabel : mp.version;
			var prefix:String = isSelected ? "► " : "  ";

			var nameText = new FlxText(50, slotY, FlxG.width - 250, '$prefix$name', 18);
			nameText.setFormat("VCR OSD Mono", 18, isSelected ? FlxColor.WHITE : 0xFF999999, LEFT);
			add(nameText);
			listTexts.push(nameText);

			// Versiyon
			var verText = new FlxText(50, slotY + 22, FlxG.width - 250, '   $ver', 12);
			verText.setFormat("VCR OSD Mono", 12, 0xFF555555, LEFT);
			add(verText);
			listTexts.push(verText);

			var statusStr:String = "";
			var statusColor:Int = 0xFF555555;
			var packStatus = getPackStatus(mp);
			var mode:String = mp.downloadMode != null ? mp.downloadMode : "direct";

			switch (packStatus) {
				case "installed":
					statusStr = "KURULU";
					statusColor = INSTALLED_COLOR;
				case "update":
					statusStr = "GÜNCELLEME VAR";
					statusColor = UPDATE_COLOR;
				case "new":
					statusStr = "YENİ";
					statusColor = NEW_COLOR;
			}

			// External modpack ek işareti
			if (mode == "external") {
				statusStr += " [MANUEL]";
			}

			var statText = new FlxText(FlxG.width - 200, slotY + 8, 170, statusStr, 13);
			statText.setFormat("VCR OSD Mono", 13, statusColor, RIGHT);
			add(statText);
			statusIndicators.push(statText);
		}

		// Scroll göstergesi
		if (allPacks.length > maxVisible) {
			var scrollInfo = '${scrollOffset + 1}-$endIdx / ${allPacks.length}';
			subtitleText.text = '${allPacks.length} modpack  •  $scrollInfo';
		}
	}

	function getPackStatus(mp:Dynamic):String {
		var packId:String = mp.id;
		if (packId == null) return "new";

		if (installer.isInstalled(packId)) {
			var manifest = installer.getInstalledManifest(packId);
			if (manifest != null && mp.version != null) {
				if (UpdateChecker.isRemoteNewer(manifest.version, mp.version))
					return "update";
			}
			return "installed";
		}

		return "new";
	}

	// ─────────────────────────────────────────────
	//  Detay Ekranı
	// ─────────────────────────────────────────────

	function showDetail():Void {
		if (selectedIndex < 0 || selectedIndex >= allPacks.length) return;

		screenState = Detail;
		var mp:Dynamic = allPacks[selectedIndex];

		// Liste text'lerini gizle
		for (t in listTexts) t.visible = false;
		for (t in statusIndicators) t.visible = false;

		// Detay panelini göster
		detailBg.visible = true;
		detailName.visible = true;
		detailAuthor.visible = true;
		detailVersion.visible = true;
		detailSize.visible = true;
		detailModCount.visible = true;
		detailDesc.visible = true;
		detailChangelog.visible = true;
		detailStatus.visible = true;
		detailControls.visible = true;

		// Doldur
		detailName.text = mp.displayName != null ? mp.displayName : mp.id;
		detailAuthor.text = mp.author != null ? 'Yapımcı: ${mp.author}' : "";
		detailVersion.text = 'Sürüm: ${mp.versionLabel != null ? mp.versionLabel : mp.version}';
		detailSize.text = mp.fileSize != null ? 'Boyut: ${mp.fileSize}' : "";
		detailModCount.text = mp.modCount != null ? '${mp.modCount} mod içerir' : "";
		detailDesc.text = mp.description != null ? mp.description : "Açıklama yok.";
		detailChangelog.text = mp.changelog != null ? 'Değişiklikler: ${mp.changelog}' : "";

		var mode:String = mp.downloadMode != null ? mp.downloadMode : "direct";
		var status = getPackStatus(mp);

		if (mode == "external") {
			// External modpack
			switch (status) {
				case "installed":
					detailStatus.text = "✓ KURULU (Manuel İndirme)";
					detailStatus.color = INSTALLED_COLOR;
					detailControls.text = "[ENTER] Tarayıcıda Aç  |  [ESC] Geri";
				case "update":
					detailStatus.text = "↑ GÜNCELLEME MEVCUT (Manuel İndirme)";
					detailStatus.color = UPDATE_COLOR;
					detailControls.text = "[ENTER] Tarayıcıda Aç  |  [ESC] Geri";
				case "new":
					detailStatus.text = "Manuel İndirme Gerekli";
					detailStatus.color = 0xFFFF8800;
					detailControls.text = "[ENTER] Tarayıcıda Aç  |  [ESC] Geri";
			}
		} else {
			// Direct modpack
			switch (status) {
				case "installed":
					detailStatus.text = "✓ KURULU";
					detailStatus.color = INSTALLED_COLOR;
					detailControls.text = "[ENTER] Yeniden Kur  |  [ESC] Geri";
				case "update":
					detailStatus.text = "↑ GÜNCELLEME MEVCUT";
					detailStatus.color = UPDATE_COLOR;
					detailControls.text = "[ENTER] Güncelle  |  [ESC] Geri";
				case "new":
					detailStatus.text = "Henüz kurulmamış";
					detailStatus.color = NEW_COLOR;
					detailControls.text = "[ENTER] İndir ve Kur  |  [ESC] Geri";
			}
		}

		controlsText.text = "";
	}

	function hideDetail():Void {
		detailBg.visible = false;
		detailName.visible = false;
		detailAuthor.visible = false;
		detailVersion.visible = false;
		detailSize.visible = false;
		detailModCount.visible = false;
		detailDesc.visible = false;
		detailChangelog.visible = false;
		detailStatus.visible = false;
		detailControls.visible = false;

		for (t in listTexts) t.visible = true;
		for (t in statusIndicators) t.visible = true;
	}

	// ─────────────────────────────────────────────
	//  İndirme/Kurulum
	// ─────────────────────────────────────────────

	function startPackDownload():Void {
		if (selectedIndex < 0 || selectedIndex >= allPacks.length) return;

		var mp:Dynamic = allPacks[selectedIndex];
		var mode:String = mp.downloadMode != null ? mp.downloadMode : "direct";

		// External mode → tarayıcıda aç
		if (mode == "external") {
			var pageUrl:String = mp.externalPageUrl != null ? mp.externalPageUrl : "";
			if (pageUrl.length > 0) {
				FlxG.openURL(pageUrl);
				FlxG.sound.play(Paths.sound('confirmMenu'));

				// Bilgilendirme göster
				hideDetail();
				for (t in listTexts) t.visible = false;
				for (t in statusIndicators) t.visible = false;

				phaseText.text = "Tarayıcıda Açıldı";
				phaseText.color = 0xFFFF8800;
				phaseText.visible = true;

				subtitleText.text = "İndirdikten sonra ZIP dosyasını mods/ klasörüne çıkarın.";
				controlsText.text = "[ENTER] Listeye Dön  |  [ESC] Ana Menü";
				screenState = Complete;
			} else {
				showError("Harici indirme linki bulunamadı.");
			}
			return;
		}

		// Direct mode → otomatik indir
		var directUrl:String = mp.directDownloadUrl != null ? mp.directDownloadUrl : "";

		if (directUrl.length == 0) {
			showError("İndirme linki bulunamadı.");
			return;
		}

		hideDetail();
		for (t in listTexts) t.visible = false;
		for (t in statusIndicators) t.visible = false;

		var packId:String = mp.id != null ? mp.id : "unknown";
		var version:String = mp.version != null ? mp.version : "0";
		var displayName:String = mp.displayName != null ? mp.displayName : packId;
		var fileName = '$packId-v$version.zip';
		var savePath = ModpackPaths.getDownloadDirectory() + fileName;

		// UI
		screenState = Downloading;
		showProgress();
		phaseText.text = "İndiriliyor...";
		phaseText.color = FlxColor.WHITE;
		phaseText.visible = true;
		subtitleText.text = displayName;
		targetProgress = 0;
		currentProgress = 0;
		controlsText.text = "[ESC] İptal";

		downloader.download(directUrl, savePath, {
			onProgress: function(progress:DownloadProgress) {
				targetProgress = progress.percent;
				var dlMB = progress.downloadedBytes / (1024 * 1024);
				var totMB = progress.totalBytes > 0 ? progress.totalBytes / (1024 * 1024) : 0;

				if (totMB > 0)
					sizeText.text = '${formatMB(dlMB)} / ${formatMB(totMB)} MB';
				else
					sizeText.text = '${formatMB(dlMB)} MB';

				if (progress.speed > 0) {
					if (progress.speed > 1024 * 1024)
						speedText.text = '${formatMB(progress.speed / (1024 * 1024))} MB/s';
					else
						speedText.text = '${Math.round(progress.speed / 1024)} KB/s';
				}
			},
			onComplete: function(path:String) {
				startPackInstall(path, packId, displayName);
			},
			onError: function(error:String) {
				showError('İndirme hatası:\n$error');
			},
			onCancelled: function() {
				showBrowse();
			}
		});
	}

	function startPackInstall(zipPath:String, packId:String, displayName:String):Void {
		screenState = Installing;
		phaseText.text = "Kuruluyor...";
		phaseText.color = FlxColor.WHITE;
		subtitleText.text = displayName;
		targetProgress = 0;
		currentProgress = 0;
		speedText.text = "";

		installer.install(zipPath, packId, {
			onProgress: function(progress:ModpackInstallProgress) {
				targetProgress = progress.overallProgress;
				sizeText.text = progress.message;
			},
			onComplete: function(manifest:ModpackManifest) {
				#if sys
				try {
					if (sys.FileSystem.exists(zipPath))
						sys.FileSystem.deleteFile(zipPath);
				} catch (_) {}
				#end

				showPackComplete(manifest);
			},
			onError: function(error:String) {
				showError('Kurulum hatası:\n$error');
			},
			onWarning: function(warning:String) {
				trace('[ModpackStore] Uyarı: $warning');
			},
			onCancelled: function() {
				showBrowse();
			}
		});
	}

	function showPackComplete(manifest:ModpackManifest):Void {
		screenState = Complete;
		FlxG.sound.play(Paths.sound('confirmMenu'));

		phaseText.text = "Tamamlandı!";
		phaseText.color = 0xFF22C55E;
		subtitleText.text = '${manifest.displayName} v${manifest.version} kuruldu';

		targetProgress = 1.0;
		currentProgress = 1.0;
		var barWidth:Int = FlxG.width - (BAR_MARGIN * 2);
		barFill.makeGraphic(barWidth, BAR_HEIGHT, 0xFF22C55E);
		percentText.text = "100%";
		sizeText.text = '${manifest.modFolders.length} mod kuruldu';
		speedText.text = "";
		controlsText.text = "[ENTER] Listeye Dön  |  [ESC] Ana Menü";
	}

	// ─────────────────────────────────────────────
	//  Hata
	// ─────────────────────────────────────────────

	function showError(msg:String):Void {
		screenState = Error;
		loadingText.visible = false;
		hideDetail();
		hideProgress();

		for (t in listTexts) t.visible = false;
		for (t in statusIndicators) t.visible = false;

		phaseText.text = "Hata!";
		phaseText.color = 0xFFEF4444;
		phaseText.visible = true;

		errorText.text = msg;
		errorText.screenCenter();
		errorText.y = phaseText.y + 50;
		errorText.visible = true;

		controlsText.text = "[ENTER] Tekrar Dene  |  [ESC] Geri";
	}

	// ─────────────────────────────────────────────
	//  Progress UI
	// ─────────────────────────────────────────────

	function showProgress():Void {
		barBorder.visible = true;
		barBg.visible = true;
		barFill.visible = true;
		percentText.visible = true;
		sizeText.visible = true;
		speedText.visible = true;
	}

	function hideProgress():Void {
		barBorder.visible = false;
		barBg.visible = false;
		barFill.visible = false;
		percentText.visible = false;
		sizeText.visible = false;
		speedText.visible = false;
		phaseText.visible = false;
		errorText.visible = false;
	}

	// ─────────────────────────────────────────────
	//  Update
	// ─────────────────────────────────────────────

	override function update(elapsed:Float) {
		super.update(elapsed);

		// Loading animasyonu
		if (screenState == Loading) {
			loadingTimer += elapsed;
			if (loadingTimer >= 0.4) {
				loadingTimer = 0;
				loadingDots = (loadingDots + 1) % 4;
				var dots = "";
				for (i in 0...loadingDots) dots += ".";
				loadingText.text = 'Modpackler yükleniyor$dots';
			}
		}

		// Progress bar animasyonu
		if (barFill.visible) {
			currentProgress += (targetProgress - currentProgress) * elapsed * 8;
			if (Math.abs(currentProgress - targetProgress) < 0.001)
				currentProgress = targetProgress;

			var barWidth:Int = FlxG.width - (BAR_MARGIN * 2);
			var fillW:Int = Std.int(Math.max(1, barWidth * currentProgress));
			var barColor:Int = screenState == Installing ? 0xFF3B82F6 : ACCENT;
			barFill.makeGraphic(fillW, BAR_HEIGHT, barColor);
			percentText.text = '${Math.round(currentProgress * 100)}%';
		}

		// Girdi
		switch (screenState) {
			case Loading:
				if (controls.BACK) goToMainMenu();

			case Browse:
				if (controls.BACK) {
					goToMainMenu();
					return;
				}
				if (controls.UI_UP_P && allPacks.length > 0) {
					selectedIndex--;
					if (selectedIndex < 0) selectedIndex = allPacks.length - 1;
					refreshList();
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if (controls.UI_DOWN_P && allPacks.length > 0) {
					selectedIndex++;
					if (selectedIndex >= allPacks.length) selectedIndex = 0;
					refreshList();
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if (controls.ACCEPT && allPacks.length > 0) {
					showDetail();
				}

			case Detail:
				if (controls.BACK) {
					showBrowse();
				}
				if (controls.ACCEPT) {
					startPackDownload();
				}

			case Downloading | Installing:
				if (controls.BACK) {
					downloader.cancel();
					installer.cancel();
					showBrowse();
				}

			case Complete:
				if (controls.ACCEPT) {
					hideProgress();
					showBrowse();
				}
				if (controls.BACK) {
					goToMainMenu();
				}

			case Error:
				if (controls.ACCEPT) {
					hideProgress();
					errorText.visible = false;
					if (allPacks.length > 0)
						showBrowse();
					else
						fetchStore();
				}
				if (controls.BACK) {
					goToMainMenu();
				}
		}
	}

	// ─────────────────────────────────────────────
	//  Geçiş
	// ─────────────────────────────────────────────

	function goToMainMenu():Void {
		FlxG.camera.fade(FlxColor.BLACK, 0.4, false, function() {
			MusicBeatState.switchState(new MainMenuState());
		});
	}

	// ─────────────────────────────────────────────
	//  Yardımcılar
	// ─────────────────────────────────────────────

	function formatMB(mb:Float):String {
		if (mb >= 100)
			return '${Math.round(mb)}';
		else if (mb >= 10)
			return '${FlxMath.roundDecimal(mb, 1)}';
		else
			return '${FlxMath.roundDecimal(mb, 2)}';
	}
}