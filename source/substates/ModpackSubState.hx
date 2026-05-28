package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import haxe.Json;
import backend.update.UpdateChecker;
import backend.modpack.ModpackPaths;
import backend.modpack.ModpackInstaller;
import backend.modpack.ModpackTypes;
import backend.modpack.DownloadManager;

class ModpackSubState extends MusicBeatSubstate {

	static inline final FONT:String = "vcr.ttf";
	static inline final SIDE_MARGIN:Float = 48;
	static inline final ITEM_HEIGHT:Float = 56;
	static inline final ITEM_GAP:Float = 8;
	static inline final LIST_TOP:Float = 110;
	static inline final SELECTED_ALPHA:Float = 1.0;
	static inline final UNSELECTED_ALPHA:Float = 0.5;
	static inline final INTRO_TIME:Float = 0.3;
	static inline final ACCENT:Int = 0xFF0D9488;

	// ─── State ───
	var screenMode:Int = 0; // 0=loading, 1=browse, 2=downloading, 3=installing, 4=complete, 5=error
	var selectedIndex:Int = 0;
	var allowInput:Bool = false;
	var currentProgress:Float = 0.0;
	var targetProgress:Float = 0.0;

	// ─── Veri ───
	var allModpacks:Array<Dynamic> = [];
	var displayList:Array<Dynamic> = [];

	// ─── Sistemler ───
	var downloader:DownloadManager;
	var installer:ModpackInstaller;

	// ─── UI ───
	var bg:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var itemTexts:Array<FlxText> = [];
	var selector:FlxSprite;
	var detailName:FlxText;
	var detailInfo:FlxText;
	var detailDesc:FlxText;
	var detailStatus:FlxText;
	var progressBarBg:FlxSprite;
	var progressBar:FlxSprite;
	var progressPercent:FlxText;
	var statusText:FlxText;
	var hintText:FlxText;

	// ─────────────────────────────────────────────
	//  Create
	// ─────────────────────────────────────────────

	override function create() {
		super.create();

		downloader = new DownloadManager();
		installer = new ModpackInstaller();

		createUI();
		playIntro();
		fetchModpacks();
	}

	function createUI():Void {
		// Arka plan
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		add(bg);

		// Başlık
		titleText = new FlxText(SIDE_MARGIN, 24, FlxG.width - SIDE_MARGIN * 2, "Modpack Arşivleri", 32);
		titleText.setFormat(Paths.font(FONT), 32, FlxColor.WHITE, CENTER);
		titleText.alpha = 0;
		add(titleText);

		// Alt başlık
		subtitleText = new FlxText(SIDE_MARGIN, 64, FlxG.width - SIDE_MARGIN * 2, "Yükleniyor...", 16);
		subtitleText.setFormat(Paths.font(FONT), 16, 0xFFBFBFBF, CENTER);
		subtitleText.alpha = 0;
		add(subtitleText);

		// Selector
		selector = new FlxSprite(SIDE_MARGIN - 4, LIST_TOP);
		selector.makeGraphic(Std.int(FlxG.width * 0.42), Std.int(ITEM_HEIGHT), FlxColor.WHITE);
		selector.alpha = 0;
		add(selector);

		// Detay paneli
		var dx = FlxG.width * 0.52;
		var dw = FlxG.width - dx - SIDE_MARGIN;

		detailName = new FlxText(dx, LIST_TOP, dw, "", 24);
		detailName.setFormat(Paths.font(FONT), 24, FlxColor.WHITE, LEFT);
		detailName.alpha = 0;
		add(detailName);

		detailInfo = new FlxText(dx, LIST_TOP + 34, dw, "", 14);
		detailInfo.setFormat(Paths.font(FONT), 14, ACCENT, LEFT);
		detailInfo.alpha = 0;
		add(detailInfo);

		detailDesc = new FlxText(dx, LIST_TOP + 60, dw, "", 14);
		detailDesc.setFormat(Paths.font(FONT), 14, 0xFF9A9A9A, LEFT);
		detailDesc.alpha = 0;
		add(detailDesc);

		detailStatus = new FlxText(dx, LIST_TOP + 140, dw, "", 18);
		detailStatus.setFormat(Paths.font(FONT), 18, FlxColor.YELLOW, LEFT);
		detailStatus.alpha = 0;
		add(detailStatus);

		// Progress
		var pw = Std.int(dw);
		progressBarBg = new FlxSprite(dx, LIST_TOP + 180);
		progressBarBg.makeGraphic(pw, 16, 0xFF222222);
		progressBarBg.visible = false;
		add(progressBarBg);

		progressBar = new FlxSprite(dx, LIST_TOP + 180);
		progressBar.makeGraphic(1, 16, ACCENT);
		progressBar.visible = false;
		add(progressBar);

		progressPercent = new FlxText(dx, LIST_TOP + 182, pw, "0%", 12);
		progressPercent.setFormat(Paths.font(FONT), 12, FlxColor.WHITE, CENTER);
		progressPercent.visible = false;
		add(progressPercent);

		statusText = new FlxText(dx, LIST_TOP + 200, dw, "", 12);
		statusText.setFormat(Paths.font(FONT), 12, 0xFF8F8F8F, LEFT);
		add(statusText);

		// Alt bilgi
		hintText = new FlxText(0, FlxG.height - 48, FlxG.width,
			"[↑/↓] Seç   [ENTER] Kur   [TAB] Filtre   [ESC] Geri");
		hintText.setFormat(Paths.font(FONT), 14, 0xFF8F8F8F, CENTER);
		hintText.alpha = 0;
		add(hintText);
	}

	function playIntro():Void {
		FlxTween.tween(bg, {alpha: 0.92}, INTRO_TIME, {ease: FlxEase.quadOut});
		animateIn(titleText, 0.05);
		animateIn(subtitleText, 0.12);
		animateIn(hintText, 0.20, function() {
			allowInput = true;
		});
	}

	function animateIn(spr:FlxSprite, delay:Float, ?onDone:Void->Void):Void {
		var targetY = spr.y;
		spr.y += 14;
		spr.alpha = 0;
		FlxTween.tween(spr, {alpha: 1, y: targetY}, INTRO_TIME, {
			startDelay: delay,
			ease: FlxEase.quadOut,
			onComplete: function(_) {
				if (onDone != null) onDone();
			}
		});
	}

	// ─────────────────────────────────────────────
	//  Veri
	// ─────────────────────────────────────────────

	function fetchModpacks():Void {
		screenMode = 0;
		subtitleText.text = "Yükleniyor...";

		UpdateChecker.instance.fetchModpackList(function(result) {
			if (result == null || result.allModpacks == null || result.allModpacks.length == 0) {
				screenMode = 5;
				subtitleText.text = "Modpack bulunamadı veya bağlantı hatası.";
				hintText.text = "[ENTER] Tekrar Dene   [ESC] Kapat";
				return;
			}

			allModpacks = cast result.allModpacks;
			displayList = allModpacks.copy();
			screenMode = 1;

			subtitleText.text = '${displayList.length} modpack bulundu';
			rebuildList();
			updateDetail();
		});
	}

	// ─────────────────────────────────────────────
	//  Liste oluşturma
	// ─────────────────────────────────────────────

	function rebuildList():Void {
		for (txt in itemTexts) {
			remove(txt, true);
			txt.destroy();
		}
		itemTexts = [];

		var listW = FlxG.width * 0.42;

		for (i in 0...displayList.length) {
			var mp:Dynamic = displayList[i];
			var name:String = mp.displayName != null ? mp.displayName : mp.id;
			var status = getPackStatus(mp.id);
			var dot = switch (status) {
				case "installed": "●";
				case "update": "▲";
				default: "○";
			};

			var txt = new FlxText(SIDE_MARGIN + 8, LIST_TOP + i * (ITEM_HEIGHT + ITEM_GAP) + 12, listW - 16, '$dot  $name', 16);
			txt.setFormat(Paths.font(FONT), 16, FlxColor.WHITE, LEFT);
			txt.alpha = i == selectedIndex ? SELECTED_ALPHA : UNSELECTED_ALPHA;
			add(txt);
			itemTexts.push(txt);
		}

		updateSelector(true);
	}

	function updateSelector(?instant:Bool = false):Void {
		if (displayList.length == 0) {
			selector.alpha = 0;
			return;
		}

		var targetY = LIST_TOP + selectedIndex * (ITEM_HEIGHT + ITEM_GAP);
		selector.alpha = 0.12;

		if (instant) {
			selector.y = targetY;
		} else {
			FlxTween.cancelTweensOf(selector);
			FlxTween.tween(selector, {y: targetY}, 0.15, {ease: FlxEase.quadOut});
		}

		for (i in 0...itemTexts.length) {
			itemTexts[i].alpha = i == selectedIndex ? SELECTED_ALPHA : UNSELECTED_ALPHA;
		}
	}

	// ─────────────────────────────────────────────
	//  Detay paneli
	// ─────────────────────────────────────────────

	function updateDetail():Void {
		if (displayList.length == 0) {
			detailName.text = "";
			detailInfo.text = "";
			detailDesc.text = "";
			detailStatus.text = "";
			return;
		}

		var mp:Dynamic = displayList[selectedIndex];
		var status = getPackStatus(mp.id);

		detailName.text = mp.displayName != null ? mp.displayName : "?";
		detailName.alpha = 1;

		var ver = mp.versionLabel != null ? mp.versionLabel : mp.version;
		var author = mp.author != null ? mp.author : "";
		var size = mp.fileSize != null ? mp.fileSize : "";
		var count = mp.modCount != null ? '${mp.modCount} mod' : "";
		detailInfo.text = 'v$ver  •  $author  •  $size  •  $count';
		detailInfo.alpha = 1;

		detailDesc.text = mp.description != null ? mp.description : "";
		detailDesc.alpha = 1;

		switch (status) {
			case "installed":
				detailStatus.text = "✓ Kurulu";
				detailStatus.color = FlxColor.LIME;
			case "update":
				var installedVer = getInstalledVersion(mp.id);
				detailStatus.text = '↑ Güncelleme: v$installedVer → v$ver';
				detailStatus.color = FlxColor.YELLOW;
			default:
				detailStatus.text = "Kurulmamış";
				detailStatus.color = 0xFF8F8F8F;
		}
		detailStatus.alpha = 1;

		var mode:String = mp.downloadMode != null ? mp.downloadMode : "direct";
		if (mode == "external") {
			hintText.text = "[ENTER] Tarayıcıda Aç   [ESC] Kapat";
		} else {
			hintText.text = "[↑/↓] Seç   [ENTER] Kur   [ESC] Kapat";
		}
	}

	// ─────────────────────────────────────────────
	//  Durum kontrolleri
	// ─────────────────────────────────────────────

	function getPackStatus(packId:String):String {
		#if sys
		var path = ModpackPaths.getInstalledManifestPath(packId);
		if (!sys.FileSystem.exists(path)) return "not_installed";

		try {
			var raw = sys.io.File.getContent(path);
			var m:Dynamic = Json.parse(raw);

			for (mp in allModpacks) {
				if (mp.id == packId) {
					if (UpdateChecker.isRemoteNewer(m.version, mp.version))
						return "update";
					return "installed";
				}
			}
			return "installed";
		} catch (_) {
			return "not_installed";
		}
		#else
		return "not_installed";
		#end
	}

	function getInstalledVersion(packId:String):String {
		#if sys
		var path = ModpackPaths.getInstalledManifestPath(packId);
		if (!sys.FileSystem.exists(path)) return "?";
		try {
			var m:Dynamic = Json.parse(sys.io.File.getContent(path));
			return m.version != null ? m.version : "?";
		} catch (_) {
			return "?";
		}
		#else
		return "?";
		#end
	}

	// ─────────────────────────────────────────────
	//  Update
	// ─────────────────────────────────────────────

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (progressBar.visible) {
			currentProgress += (targetProgress - currentProgress) * elapsed * 6;
			var pw = FlxG.width - FlxG.width * 0.52 - SIDE_MARGIN;
			var barW:Int = Std.int(Math.max(1, pw * currentProgress));
			progressBar.makeGraphic(barW, 16, ACCENT);
			progressPercent.text = '${Math.round(currentProgress * 100)}%';
		}

		if (!allowInput) return;

		switch (screenMode) {
			case 0: // loading
			case 1: handleBrowse();
			case 2 | 3: handleProgress();
			case 4: handleComplete();
			case 5: handleError();
		}
	}

	// ─────────────────────────────────────────────
	//  Girdi
	// ─────────────────────────────────────────────

	function handleBrowse():Void {
		if (controls.BACK) {
			exitSubState();
			return;
		}

		if (displayList.length == 0) return;

		if (controls.UI_UP_P) {
			selectedIndex--;
			if (selectedIndex < 0) selectedIndex = displayList.length - 1;
			updateSelector();
			updateDetail();
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if (controls.UI_DOWN_P) {
			selectedIndex++;
			if (selectedIndex >= displayList.length) selectedIndex = 0;
			updateSelector();
			updateDetail();
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if (controls.ACCEPT) {
			startAction(selectedIndex);
		}
	}

	function handleProgress():Void {
		if (controls.BACK) {
			downloader.cancel();
			installer.cancel();
			screenMode = 1;
			hideProgress();
			updateDetail();
			hintText.text = "[↑/↓] Seç   [ENTER] Kur   [ESC] Kapat";
		}
	}

	function handleComplete():Void {
		if (controls.ACCEPT || controls.BACK) {
			screenMode = 1;
			hideProgress();
			rebuildList();
			updateDetail();
			titleText.text = "Modpack Mağazası";
			titleText.color = FlxColor.WHITE;
			hintText.text = "[↑/↓] Seç   [ENTER] Kur   [ESC] Kapat";
		}
	}

	function handleError():Void {
		if (controls.ACCEPT) {
			titleText.text = "Modpack Mağazası";
			titleText.color = FlxColor.WHITE;
			fetchModpacks();
		}
		if (controls.BACK) {
			exitSubState();
		}
	}

	function exitSubState():Void {
		FlxG.sound.play(Paths.sound('cancelMenu'));
		FlxTween.tween(bg, {alpha: 0}, 0.25, {ease: FlxEase.quadOut});

		for (txt in itemTexts)
			FlxTween.tween(txt, {alpha: 0}, 0.2);

		var uiElements:Array<FlxSprite> = [
			titleText, subtitleText, selector, detailName,
			detailInfo, detailDesc, detailStatus, statusText, hintText
		];

		for (el in uiElements)
			FlxTween.tween(el, {alpha: 0}, 0.2);

		FlxTween.tween(bg, {alpha: 0}, 0.25, {
			ease: FlxEase.quadOut,
			onComplete: function(_) {
				close();
			}
		});
	}

	// ─────────────────────────────────────────────
	//  Aksiyon
	// ─────────────────────────────────────────────

	function startAction(index:Int):Void {
		if (index < 0 || index >= displayList.length) return;

		var mp:Dynamic = displayList[index];
		var mode:String = mp.downloadMode != null ? mp.downloadMode : "direct";

		if (mode == "external") {
			var url:String = mp.externalPageUrl != null ? mp.externalPageUrl : "";
			if (url.length > 0) {
				FlxG.openURL(url);
			}
			return;
		}

		var url:String = mp.directDownloadUrl != null ? mp.directDownloadUrl : "";
		if (url.length == 0) {
			showError('İndirme linki bulunamadı.');
			return;
		}

		startDownload(mp.id, mp.version, mp.displayName, url);
	}

	function startDownload(packId:String, version:String, displayName:String, url:String):Void {
		screenMode = 2;
		showProgress();
		currentProgress = 0;
		targetProgress = 0;
		detailStatus.text = "İndiriliyor...";
		detailStatus.color = FlxColor.WHITE;
		hintText.text = "[ESC] İptal";

		var savePath = ModpackPaths.getDownloadDirectory() + '$packId-v$version.zip';

		downloader.download(url, savePath, {
			onProgress: function(p) {
				targetProgress = p.percent;
			},
			onComplete: function(path) {
				startInstall(path, packId, displayName);
			},
			onError: function(err) {
				showError('İndirme hatası: $err');
			},
			onCancelled: function() {
				screenMode = 1;
				hideProgress();
				updateDetail();
			}
		});
	}

	function startInstall(zipPath:String, packId:String, displayName:String):Void {
		screenMode = 3;
		currentProgress = 0;
		targetProgress = 0;
		detailStatus.text = "Kuruluyor...";

		installer.install(zipPath, packId, {
			onProgress: function(p:ModpackInstallProgress) {
				targetProgress = p.overallProgress;
				statusText.text = p.message;
			},
			onComplete: function(manifest:ModpackManifest) {
				#if sys
				try {
					if (sys.FileSystem.exists(zipPath))
						sys.FileSystem.deleteFile(zipPath);
				} catch (_) {}
				#end

				screenMode = 4;
				targetProgress = 1.0;
				titleText.text = "Tamamlandı!";
				titleText.color = FlxColor.LIME;
				detailStatus.text = '✓ ${manifest.displayName} kuruldu!';
				detailStatus.color = FlxColor.LIME;
				statusText.text = '${manifest.modFolders.length} mod kuruldu';
				hintText.text = "[ENTER] Tamam";
			},
			onError: function(err) {
				showError('Kurulum hatası: $err');
			},
			onWarning: function(w) {
				trace('[ModpackSubState] Uyarı: $w');
			},
			onCancelled: function() {
				screenMode = 1;
				hideProgress();
				updateDetail();
			}
		});
	}

	// ─────────────────────────────────────────────
	//  Hata
	// ─────────────────────────────────────────────

	function showError(msg:String):Void {
		screenMode = 5;
		hideProgress();
		titleText.text = "Hata";
		titleText.color = FlxColor.RED;
		detailStatus.text = msg;
		detailStatus.color = FlxColor.RED;
		hintText.text = "[ENTER] Tekrar Dene   [ESC] Kapat";
	}

	// ─────────────────────────────────────────────
	//  Progress UI
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