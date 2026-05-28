package states;

import backend.AuthManager;
import backend.SupabaseClient;
import backend.ui.PsychUIInputText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;

class LoginState extends MusicBeatState {
	// Renkler
	static inline final C_BG = 0xFF08080f;
	static inline final C_CARD = 0xFF0e0e1a;
	static inline final C_BORDER = 0xFF1c1c30;
	static inline final C_FIELD = 0xFF0a0a14;
	static inline final C_ACCENT = 0xFFA855F7;
	static inline final C_TEXT = 0xFFe2e2f0;
	static inline final C_MUTED = 0xFF555570;
	static inline final C_RED = 0xFFef4444;
	static inline final C_GREEN = 0xFF22c55e;

	// Boyutlar
	static inline final CARD_W = 380;
	static inline final CARD_H = 420;
	static inline final FIELD_W = 320;
	static inline final FIELD_H = 38;

	var cardX:Float;
	var cardY:Float;
	var fieldX:Float;

	var titleText:FlxText;
	var subtitleText:FlxText;
	var statusText:FlxText;
	var emailLabel:FlxText;
	var passLabel:FlxText;
	var userLabel:FlxText;
	var emailInput:PsychUIInputText;
	var passInput:PsychUIInputText;
	var userInput:PsychUIInputText;
	var loginBtn:FlxSprite;
	var loginBtnText:FlxText;
	var toggleText:FlxText;
	var skipText:FlxText;

	var _isRegister:Bool = false;
	var _busy:Bool = false;

	var regElements:Array<flixel.FlxBasic> = [];

	override function create() {
		super.create();

		cardX = (1280 - CARD_W) / 2;
		cardY = (720 - CARD_H) / 2;
		fieldX = cardX + (CARD_W - FIELD_W) / 2;

		// ── Arka plan ──
		add(new FlxSprite().makeGraphic(1280, 720, C_BG));

		// ── Kart ──
		add(new FlxSprite(cardX, cardY).makeGraphic(CARD_W, CARD_H, C_CARD));

		// Üst accent çizgi
		var accent = new FlxSprite(cardX, cardY).makeGraphic(CARD_W, 3, C_ACCENT);
		accent.alpha = 0.8;
		add(accent);

		// ── İçerik ──
		var curY:Float = cardY + 28;

		titleText = txt(cardX, curY, CARD_W, "Giris Yap", 22, CENTER);
		add(titleText);
		curY += 30;

		subtitleText = txt(cardX, curY, CARD_W, "Hesabiniza baglanin", 10, CENTER);
		subtitleText.color = C_MUTED;
		add(subtitleText);
		curY += 36;

		// ── Username (register only) ──
		userLabel = txt(fieldX, curY, FIELD_W, "KULLANICI ADI", 8);
		userLabel.color = C_MUTED;
		regElements.push(userLabel);
		add(userLabel);

		var uBg = field(fieldX, curY + 14);
		regElements.push(uBg);

		userInput = new PsychUIInputText(Std.int(fieldX + 10), Std.int(curY + 22), Std.int(FIELD_W - 20), "", 12);
		userInput.maxLength = 20;
		regElements.push(userInput);
		add(userInput);
		curY += FIELD_H + 26;

		// ── Email ──
		emailLabel = txt(fieldX, curY, FIELD_W, "E-POSTA VEYA KULLANICI ADI", 8);
		emailLabel.color = C_MUTED;
		add(emailLabel);

		field(fieldX, curY + 14);

		emailInput = new PsychUIInputText(Std.int(fieldX + 10), Std.int(curY + 22), Std.int(FIELD_W - 20), "", 12);
		emailInput.maxLength = 50;
		add(emailInput);
		curY += FIELD_H + 26;

		// ── Password ──
		passLabel = txt(fieldX, curY, FIELD_W, "SIFRE", 8);
		passLabel.color = C_MUTED;
		add(passLabel);

		field(fieldX, curY + 14);

		passInput = new PsychUIInputText(Std.int(fieldX + 10), Std.int(curY + 22), Std.int(FIELD_W - 20), "", 12);
		passInput.maxLength = 50;
		passInput.passwordMask = true;
		add(passInput);
		curY += FIELD_H + 22;

		// ── Buton ──
		loginBtn = new FlxSprite(fieldX, curY).makeGraphic(FIELD_W, 40, C_ACCENT);
		add(loginBtn);

		loginBtnText = txt(fieldX, curY + 12, FIELD_W, "GIRIS YAP", 12, CENTER);
		loginBtnText.color = 0xFF0a0a14;
		add(loginBtnText);
		curY += 52;

		// ── Toggle ──
		toggleText = txt(cardX, curY, CARD_W, "Hesabin yok mu? Kayit ol", 9, CENTER);
		toggleText.color = C_ACCENT;
		add(toggleText);
		curY += 22;

		// ── Skip ──
		skipText = txt(cardX, curY, CARD_W, "Atla", 9, CENTER);
		skipText.color = C_MUTED;
		add(skipText);
		curY += 24;

		// ── Status ──
		statusText = txt(cardX, curY, CARD_W, "", 9, CENTER);
		statusText.color = C_RED;
		add(statusText);

		// ── Başlangıç ──
		setRegisterVisible(false);
	}

	// ══════════════════════════════════
	//  HELPERS
	// ══════════════════════════════════
	function txt(x:Float, y:Float, w:Float, s:String, size:Int, ?align:FlxTextAlign):FlxText {
		var t = new FlxText(x, y, w, s, size);
		t.setFormat(Paths.font("vcr.ttf"), size, C_TEXT, align != null ? align : LEFT);
		return t;
	}

	function field(x:Float, y:Float):FlxSprite {
		var bg = new FlxSprite(x, y).makeGraphic(FIELD_W, FIELD_H, C_FIELD);
		add(bg);

		// Alt çizgi
		var line = new FlxSprite(x, y + FIELD_H - 2).makeGraphic(FIELD_W, 2, C_ACCENT);
		line.alpha = 0.3;
		add(line);

		return bg;
	}

	function setRegisterVisible(show:Bool):Void {
		for (el in regElements)
			el.visible = show;

		userInput.active = show;
		emailLabel.text = show ? "E-POSTA" : "E-POSTA VEYA KULLANICI ADI";
	}

	// ══════════════════════════════════
	//  UPDATE
	// ══════════════════════════════════
	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (_busy) return;

		if (FlxG.keys.justPressed.ENTER) {
			doSubmit();
			return;
		}

		if (FlxG.keys.justPressed.ESCAPE) {
			goBack();
			return;
		}

		if (!FlxG.mouse.justPressed) return;
		var mx = FlxG.mouse.x;
		var my = FlxG.mouse.y;

		if (hit(loginBtn, mx, my)) { doSubmit(); return; }
		if (hit(toggleText, mx, my)) { toggleMode(); return; }
		if (hit(skipText, mx, my)) { goBack(); return; }
	}

	function hit(obj:FlxSprite, mx:Float, my:Float):Bool {
		return mx >= obj.x && mx <= obj.x + obj.width
			&& my >= obj.y && my <= obj.y + obj.height;
	}

	// ══════════════════════════════════
	//  TOGGLE
	// ══════════════════════════════════
	function toggleMode():Void {
		_isRegister = !_isRegister;

		titleText.text = _isRegister ? "Kayit Ol" : "Giris Yap";
		subtitleText.text = _isRegister ? "Yeni hesap olusturun" : "Hesabiniza baglanin";
		loginBtnText.text = _isRegister ? "KAYIT OL" : "GIRIS YAP";
		toggleText.text = _isRegister ? "Zaten hesabin var? Giris yap" : "Hesabin yok mu? Kayit ol";

		setRegisterVisible(_isRegister);
		statusText.text = '';
	}

	// ══════════════════════════════════
	//  SUBMIT
	// ══════════════════════════════════
	function doSubmit():Void {
		if (_busy) return;

		var email = emailInput.text.trim();
		var pass = passInput.text;

		if (_isRegister) {
			var user = userInput.text.trim();
			if (user.length < 4) { err('Kullanici adi en az 4 karakter'); return; }
			if (email == '' || email.indexOf('@') == -1) { err('Gecerli bir e-posta girin'); return; }
			if (pass.length < 6) { err('Sifre en az 6 karakter'); return; }

			_busy = true;
			info('Kayit olunuyor...');
			loginBtn.color = C_MUTED;

			AuthManager.register(email, pass, user, "Unknown", function(ok:Bool, msg:String) {
				_busy = false;
				loginBtn.color = C_ACCENT;
				if (ok) {
					showOk('Kayit basarili!');
					#if ACHIEVEMENTS_ALLOWED
					backend.AchievementSync.flushQueue();
					#end
					new FlxTimer().start(0.6, function(_) { goBack(); });
				} else err(msg);
			});
		} else {
			if (email == '') { err('E-posta veya kullanici adi girin'); return; }
			if (pass.length < 1) { err('Sifre girin'); return; }

			_busy = true;
			info('Giris yapiliyor...');
			loginBtn.color = C_MUTED;

			var callback = function(success:Bool, msg:String) {
				_busy = false;
				loginBtn.color = C_ACCENT;
				if (success) {
					showOk('Giris basarili!');
					#if ACHIEVEMENTS_ALLOWED
					backend.AchievementSync.flushQueue();
					#end
					new FlxTimer().start(0.6, function(_) { goBack(); });
				} else err(msg);
			};

			if (email.indexOf('@') != -1)
				AuthManager.login(email, pass, callback);
			else
				AuthManager.loginWithUsername(email, pass, callback);
		}
	}

	// ══════════════════════════════════
	//  STATUS
	// ══════════════════════════════════
	function err(msg:String):Void {
		statusText.text = msg;
		statusText.color = C_RED;
	}

	function info(msg:String):Void {
		statusText.text = msg;
		statusText.color = C_MUTED;
	}

	function showOk(msg:String):Void {
		statusText.text = msg;
		statusText.color = C_GREEN;
	}

	function goBack():Void {
		PsychUIInputText.focusOn = null;
		MusicBeatState.switchState(new MainMenuState());
	}
}