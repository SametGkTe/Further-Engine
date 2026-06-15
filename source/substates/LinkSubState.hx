package substates;

import backend.Paths;
import backend.ClientPrefs;
import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class LinkSubState extends MusicBeatSubstate {
	static inline final COL_BG = 0xFF0a0a0a;
	static inline final COL_PANEL = 0xFF1a1a1a;
	static inline final COL_ACCENT = 0xFF888888;
	static inline final COL_TEXT = 0xFFE0E0E0;
	static inline final COL_DIM = 0xFF707070;
	static inline final COL_YES = 0xFF22c55e;
	static inline final COL_NO = 0xFFef4444;
	static inline final COL_BTN = 0xFF222222;
	static inline final COL_BTN_SEL = 0xFF333333;

	static inline final PANEL_W = 480;
	static inline final PANEL_H = 240;
	static inline final BTN_W = 140;
	static inline final BTN_H = 42;

	var prompt:String;
	var url:String;
	var yesCallback:Void->Void;
	var noCallback:Void->Void;

	var coolCam:FlxCamera;
	var overlay:FlxSprite;
	var panel:FlxSprite;
	var accentLine:FlxSprite;
	var promptText:FlxText;
	var urlText:FlxText;
	var yesBg:FlxSprite;
	var noBg:FlxSprite;
	var yesLine:FlxSprite;
	var noLine:FlxSprite;
	var yesText:FlxText;
	var noText:FlxText;
	var linkIcon:FlxSprite;

	var curSelected:Int = -1;
	var _ready:Bool = false;
	var _closing:Bool = false;

	// ══════════════════════════════════
	//  STATIC
	// ══════════════════════════════════
	public static function requestURL(url:String, ?prompt:String = "Bu bağlantıyı açmak istiyor musunuz?"):Void {
		request(prompt, url, function() { FlxG.openURL(url); });
	}

	public static function request(prompt:String, url:String, yesCallback:Void->Void, ?noCallback:Void->Void):Void {
		if (FlxG.state.subState != null)
			FlxG.state.subState.close();
		FlxG.state.openSubState(new LinkSubState(prompt, url, yesCallback, noCallback));
	}

	// ══════════════════════════════════
	//  CONSTRUCTOR
	// ══════════════════════════════════
	private function new(prompt:String, url:String, yesCallback:Void->Void, noCallback:Void->Void) {
		super();
		this.prompt = prompt;
		this.url = url;
		this.yesCallback = yesCallback;
		this.noCallback = noCallback;
	}

	// ══════════════════════════════════
	//  CREATE
	// ══════════════════════════════════
	override function create() {
		super.create();

		coolCam = new FlxCamera();
		coolCam.bgColor.alpha = 0;
		FlxG.cameras.add(coolCam, false);
		cameras = [coolCam];

		var px:Float = (FlxG.width - PANEL_W) / 2;
		var py:Float = (FlxG.height - PANEL_H) / 2;

		// Overlay
		overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		overlay.scrollFactor.set(0, 0);
		overlay.alpha = 0;
		add(overlay);

		// Panel
		panel = new FlxSprite(px, py).makeGraphic(PANEL_W, PANEL_H, COL_PANEL);
		panel.scrollFactor.set(0, 0);
		panel.alpha = 0;
		add(panel);

		// Accent line
		accentLine = new FlxSprite(px, py).makeGraphic(PANEL_W, 2, COL_ACCENT);
		accentLine.scrollFactor.set(0, 0);
		accentLine.alpha = 0;
		add(accentLine);

		// Prompt
		promptText = new FlxText(px + 30, py + 30, PANEL_W - 60, prompt);
		promptText.setFormat(Paths.font("Avgardd.ttf"), 20, COL_TEXT, CENTER);
		promptText.scrollFactor.set(0, 0);
		promptText.alpha = 0;
		add(promptText);

		// Link ikonu + URL
		linkIcon = new FlxSprite();
		linkIcon.scrollFactor.set(0, 0);
		linkIcon.alpha = 0;

		try {
			linkIcon.loadGraphic(Paths.image("other/link"));
			linkIcon.setGraphicSize(18, 18);
			linkIcon.updateHitbox();
		} catch (e:Dynamic) {
			linkIcon.makeGraphic(18, 18, COL_ACCENT);
		}

		urlText = new FlxText(0, py + 75, PANEL_W - 60, url);
		urlText.setFormat(Paths.font("vcr.ttf"), 14, COL_ACCENT, CENTER);
		urlText.scrollFactor.set(0, 0);
		urlText.alpha = 0;
		urlText.screenCenter(X);

		// Metnin gerçek render genişliğini al ve center'a göre başlangıç noktasını hesapla
		var actualTextWidth:Float = urlText.width;
		if (urlText.textField != null)
			actualTextWidth = urlText.textField.textWidth;
		var textStartX:Float = urlText.x + (urlText.width - actualTextWidth) / 2;

		// Ikonu URL metninin gerçek başlangıcının soluna hizala
		linkIcon.x = textStartX - 24;
		linkIcon.y = urlText.y + (urlText.height - 18) / 2;
		linkIcon.antialiasing = ClientPrefs.data.antialiasing;

		add(linkIcon);
		add(urlText);

		// Separator
		var sep = new FlxSprite(px + 40, py + 120).makeGraphic(PANEL_W - 80, 1, COL_ACCENT);
		sep.scrollFactor.set(0, 0);
		sep.alpha = 0;
		add(sep);

		// Butonlar
		var btnY:Float = py + PANEL_H - BTN_H - 30;
		var gap:Float = 20;
		var totalW:Float = BTN_W * 2 + gap;
		var startX:Float = px + (PANEL_W - totalW) / 2;

		// Evet
		yesBg = new FlxSprite(startX, btnY).makeGraphic(BTN_W, BTN_H, COL_BTN);
		yesBg.scrollFactor.set(0, 0);
		yesBg.alpha = 0;
		add(yesBg);

		yesLine = new FlxSprite(startX, btnY).makeGraphic(BTN_W, 2, COL_YES);
		yesLine.scrollFactor.set(0, 0);
		yesLine.alpha = 0;
		add(yesLine);

		yesText = new FlxText(startX, btnY + 10, BTN_W, "Evet");
		yesText.setFormat(Paths.font("Avgardd.ttf"), 18, COL_TEXT, CENTER);
		yesText.scrollFactor.set(0, 0);
		yesText.alpha = 0;
		add(yesText);

		// Hayir
		var noX:Float = startX + BTN_W + gap;

		noBg = new FlxSprite(noX, btnY).makeGraphic(BTN_W, BTN_H, COL_BTN);
		noBg.scrollFactor.set(0, 0);
		noBg.alpha = 0;
		add(noBg);

		noLine = new FlxSprite(noX, btnY).makeGraphic(BTN_W, 2, COL_NO);
		noLine.scrollFactor.set(0, 0);
		noLine.alpha = 0;
		add(noLine);

		noText = new FlxText(noX, btnY + 10, BTN_W, "Hayır");
		noText.setFormat(Paths.font("Avgardd.ttf"), 18, COL_TEXT, CENTER);
		noText.scrollFactor.set(0, 0);
		noText.alpha = 0;
		add(noText);

		// Giris animasyonu
		FlxTween.tween(overlay, {alpha: 0.55}, 0.2);
		panel.scale.set(0.93, 0.93);
		FlxTween.tween(panel, {alpha: 1}, 0.2);
		FlxTween.tween(panel.scale, {x: 1, y: 1}, 0.25, {ease: FlxEase.backOut});
		FlxTween.tween(accentLine, {alpha: 0.8}, 0.2, {startDelay: 0.05});
		FlxTween.tween(promptText, {alpha: 1}, 0.2, {startDelay: 0.08});
		FlxTween.tween(urlText, {alpha: 0.9}, 0.2, {startDelay: 0.1});
		FlxTween.tween(linkIcon, {alpha: 0.7}, 0.2, {startDelay: 0.1});
		FlxTween.tween(sep, {alpha: 0.2}, 0.2, {startDelay: 0.12});
		FlxTween.tween(yesBg, {alpha: 1}, 0.2, {startDelay: 0.14});
		FlxTween.tween(yesLine, {alpha: 0.6}, 0.2, {startDelay: 0.14});
		FlxTween.tween(yesText, {alpha: 0.6}, 0.2, {startDelay: 0.14});
		FlxTween.tween(noBg, {alpha: 1}, 0.2, {startDelay: 0.16});
		FlxTween.tween(noLine, {alpha: 0.6}, 0.2, {startDelay: 0.16});
		FlxTween.tween(noText, {alpha: 0.6}, 0.2, {
			startDelay: 0.16,
			onComplete: function(_) { _ready = true; }
		});
	}

	// ══════════════════════════════════
	//  UPDATE
	// ══════════════════════════════════
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (!_ready || _closing) return;

		// Klavye
		if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
			curSelected = (curSelected == 0) ? 1 : 0;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			updateHighlight();
		}

		// Mouse
		if (FlxG.mouse.justMoved || FlxG.mouse.justPressed) {
			var prev = curSelected;
			if (isOver(yesBg)) curSelected = 0;
			else if (isOver(noBg)) curSelected = 1;
			else curSelected = -1;
			if (prev != curSelected) updateHighlight();
		}

		// Mobil
		#if mobile
		for (touch in FlxG.touches.list) {
			if (touch.justPressed || touch.pressed) {
				var prev = curSelected;
				if (touchOver(yesBg, touch)) curSelected = 0;
				else if (touchOver(noBg, touch)) curSelected = 1;
				if (prev != curSelected) updateHighlight();
			}
		}
		#end

		// Secim
		var doAccept = controls.ACCEPT;
		var doClick = FlxG.mouse.justPressed && curSelected >= 0;

		#if mobile
		if (!doAccept && !doClick) {
			for (touch in FlxG.touches.list) {
				if (touch.justPressed && curSelected >= 0) {
					doClick = true;
					break;
				}
			}
		}
		#end

		if (doAccept || doClick) {
			if (curSelected == 0) selectYes();
			else if (curSelected == 1) selectNo();
		}

		// Panel disi tiklama = kapat
		if (FlxG.mouse.justPressed && curSelected == -1 && !isOver(panel)) {
			selectNo();
		}

		// ESC
		if (controls.BACK) selectNo();
	}

	// ══════════════════════════════════
	//  SECIM
	// ══════════════════════════════════
	function selectYes():Void {
		if (_closing) return;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		animateClose(function() {
			if (yesCallback != null) yesCallback();
		});
	}

	function selectNo():Void {
		if (_closing) return;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		animateClose(function() {
			if (noCallback != null) noCallback();
		});
	}

	// ══════════════════════════════════
	//  HIGHLIGHT
	// ══════════════════════════════════
	function updateHighlight():Void {
		yesBg.color = (curSelected == 0) ? COL_BTN_SEL : COL_BTN;
		yesText.alpha = (curSelected == 0) ? 1 : 0.6;
		yesLine.alpha = (curSelected == 0) ? 1 : 0.6;

		noBg.color = (curSelected == 1) ? COL_BTN_SEL : COL_BTN;
		noText.alpha = (curSelected == 1) ? 1 : 0.6;
		noLine.alpha = (curSelected == 1) ? 1 : 0.6;
	}

	// ══════════════════════════════════
	//  HIT DETECTION
	// ══════════════════════════════════
	function isOver(spr:FlxSprite):Bool {
		return FlxG.mouse.screenX >= spr.x && FlxG.mouse.screenX <= spr.x + spr.width
			&& FlxG.mouse.screenY >= spr.y && FlxG.mouse.screenY <= spr.y + spr.height;
	}

	#if mobile
	function touchOver(spr:FlxSprite, touch:flixel.input.touch.FlxTouch):Bool {
		return touch.screenX >= spr.x && touch.screenX <= spr.x + spr.width
			&& touch.screenY >= spr.y && touch.screenY <= spr.y + spr.height;
	}
	#end

	// ══════════════════════════════════
	//  ANIMASYONLU KAPANMA
	// ══════════════════════════════════
	function animateClose(?callback:Void->Void):Void {
		if (_closing) return;
		_closing = true;
		_ready = false;

		FlxTween.tween(overlay, {alpha: 0}, 0.15);
		FlxTween.tween(panel, {alpha: 0}, 0.12);
		FlxTween.tween(accentLine, {alpha: 0}, 0.1);
		FlxTween.tween(promptText, {alpha: 0}, 0.1);
		FlxTween.tween(urlText, {alpha: 0}, 0.1);
		FlxTween.tween(yesBg, {alpha: 0}, 0.1);
		FlxTween.tween(yesLine, {alpha: 0}, 0.1);
		FlxTween.tween(yesText, {alpha: 0}, 0.1);
		FlxTween.tween(noBg, {alpha: 0}, 0.1);
		FlxTween.tween(noLine, {alpha: 0}, 0.1);
		FlxTween.tween(noText, {alpha: 0}, 0.1);
		FlxTween.tween(linkIcon, {alpha: 0}, 0.1);

		new flixel.util.FlxTimer().start(0.18, function(_) {
			if (callback != null) callback();
			FlxG.cameras.remove(coolCam);
			forceClose();
		});
	}

	function forceClose():Void {
		super.close();
	}

	override function close() {
		if (!_closing) animateClose(null);
	}

	override function destroy() {
		if (coolCam != null) {
			if (FlxG.cameras.list.contains(coolCam))
				FlxG.cameras.remove(coolCam);
			coolCam = null;
		}
		super.destroy();
	}
}