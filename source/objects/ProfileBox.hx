package objects;

import backend.AuthManager;
import backend.SupabaseClient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class ProfileBox extends FlxSpriteGroup {

	static inline final COL_BG = 0xDD0a0a16;
	static inline final COL_ACCENT = 0xFFA855F7;
	static inline final COL_GREEN = 0xFF22c55e;
	static inline final COL_MUTED = 0xFF6b6b88;
	static inline final COL_GOLD = 0xFFFBBF24;
	static inline final COL_CYAN = 0xFF22D3EE;
	static inline final COL_PINK = 0xFFF472B6;
	static inline final COL_RED = 0xFFef4444;
	static inline final COL_BORDER = 0xFF1c1c30;

	static inline final BOX_W = 320;
	static inline final BOX_H = 100;
	static inline final BOX_H_GUEST = 60;
	static inline final AVATAR_SIZE = 60;
	static inline final XP_BAR_H = 5;

	static inline final CACHE_FILE = "profile_cache.json";

	var bg:FlxSprite;
	var accentBar:FlxSprite;
	var borderBottom:FlxSprite;
	var avatarBg:FlxSprite;
	var avatarLetter:FlxText;
	var onlineDot:FlxSprite;
	var usernameText:FlxText;
	var levelText:FlxText;
	var rankText:FlxText;
	var achievementText:FlxText;
	var xpBarBg:FlxSprite;
	var xpBarFill:FlxSprite;
	var guestText:FlxText;
	var guestSubText:FlxText;
	var guestIcon:FlxText;

	var _pulseTime:Float = 0;
	var _built:Bool = false;
	var _isGuest:Bool = true;

	public static var instance:ProfileBox = null;

	public function new(?xPos:Float = 0, ?yPos:Float = 0) {
		super(xPos, yPos);
		instance = this;

		if (AuthManager.isLoggedIn)
			buildLoggedIn();
		else
			buildGuest();
	}

	// ══════════════════════════════════
	//  GİRİŞ YAPILMAMIŞ
	// ══════════════════════════════════
	function buildGuest():Void {
		_isGuest = true;
		_built = true;

		// Arka plan
		bg = new FlxSprite(0, 0);
		bg.makeGraphic(BOX_W, BOX_H_GUEST, COL_BG);
		bg.alpha = 0.95;
		add(bg);

		// Sol accent
		accentBar = new FlxSprite(0, 0);
		accentBar.makeGraphic(4, BOX_H_GUEST, COL_RED);
		add(accentBar);

		// Alt border
		borderBottom = new FlxSprite(0, BOX_H_GUEST - 1);
		borderBottom.makeGraphic(BOX_W, 1, COL_BORDER);
		add(borderBottom);

		// İkon
		guestIcon = new FlxText(16, 14, 34, "👤");
		guestIcon.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		add(guestIcon);

		// Metin
		guestText = new FlxText(56, 10, BOX_W - 70, "Giris Yapilmadi");
		guestText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(guestText);

		guestSubText = new FlxText(56, 32, BOX_W - 70, "Tikla ve giris yap >");
		guestSubText.setFormat(Paths.font("vcr.ttf"), 11, COL_MUTED, LEFT);
		add(guestSubText);

		// Animasyon
		alpha = 0;
		var startX = x;
		x += 25;
		FlxTween.tween(this, {alpha: 1, x: startX}, 0.4, {
			ease: FlxEase.backOut,
			startDelay: 0.15
		});
	}

	// ══════════════════════════════════
	//  GİRİŞ YAPILMIŞ
	// ══════════════════════════════════
	function buildLoggedIn():Void {
		_isGuest = false;
		_built = true;

		// Arka plan
		bg = new FlxSprite(0, 0);
		bg.makeGraphic(BOX_W, BOX_H, COL_BG);
		bg.alpha = 0.95;
		add(bg);

		// Sol accent
		accentBar = new FlxSprite(0, 0);
		accentBar.makeGraphic(4, BOX_H, COL_ACCENT);
		add(accentBar);

		// Alt border
		borderBottom = new FlxSprite(0, BOX_H - 1);
		borderBottom.makeGraphic(BOX_W, 1, COL_BORDER);
		add(borderBottom);

		// Online dot
		onlineDot = new FlxSprite(BOX_W - 16, 10);
		onlineDot.makeGraphic(10, 10, COL_GREEN);
		add(onlineDot);

		// Avatar arka plan
		avatarBg = new FlxSprite(14, 12);
		avatarBg.makeGraphic(AVATAR_SIZE, AVATAR_SIZE, 0xFF1a1a30);
		add(avatarBg);

		// Avatar border
		var avBorder = new FlxSprite(13, 11);
		avBorder.makeGraphic(AVATAR_SIZE + 2, AVATAR_SIZE + 2, COL_ACCENT);
		avBorder.alpha = 0.4;
		add(avBorder);

		// Avatar tekrar üste (border'ın üstünde)
		avatarBg = new FlxSprite(14, 12);
		avatarBg.makeGraphic(AVATAR_SIZE, AVATAR_SIZE, 0xFF1a1a30);
		add(avatarBg);

		// Avatar harf
		var username = AuthManager.currentUsername ?? "P";
		avatarLetter = new FlxText(14, 24, AVATAR_SIZE, username.charAt(0).toUpperCase());
		avatarLetter.setFormat(Paths.font("vcr.ttf"), 28, COL_ACCENT, CENTER);
		add(avatarLetter);

		// Text alanı
		var textX = 14 + AVATAR_SIZE + 12;
		var textW = BOX_W - textX - 18;

		// Username
		usernameText = new FlxText(textX, 10, textW, AuthManager.currentUsername ?? "Player");
		usernameText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(usernameText);

		// Level + UP
		var level = AuthManager.currentLevel ?? 1;
		var up = AuthManager.currentUltraPoints ?? 0.0;

		levelText = new FlxText(textX, 30, textW, 'Lv.$level  |  ${formatNumber(up)} UP');
		levelText.setFormat(Paths.font("vcr.ttf"), 11, COL_MUTED, LEFT);
		add(levelText);

		// Rank + Achievement (yan yana)
		var rank = getRankFromUP(up);
		rankText = new FlxText(textX, 48, Std.int(textW * 0.55), getRankTitle(rank));
		rankText.setFormat(Paths.font("vcr.ttf"), 11, getRankColor(rank), LEFT);
		add(rankText);

		#if ACHIEVEMENTS_ALLOWED
		var achCount = Achievements.achievementsUnlocked.length;
		achievementText = new FlxText(textX + Std.int(textW * 0.55), 48, Std.int(textW * 0.45), '⭐ $achCount');
		achievementText.setFormat(Paths.font("vcr.ttf"), 11, COL_GOLD, LEFT);
		add(achievementText);
		#end

		// XP Bar
		var xpBarY = BOX_H - XP_BAR_H - 10;

		xpBarBg = new FlxSprite(textX, xpBarY);
		xpBarBg.makeGraphic(Std.int(textW), XP_BAR_H, 0xFF1A1A2E);
		add(xpBarBg);

		var xp = getXPProgress();
		var fillWidth = Std.int(Math.max(3, textW * xp));
		xpBarFill = new FlxSprite(textX, xpBarY);
		xpBarFill.makeGraphic(fillWidth, XP_BAR_H, COL_ACCENT);
		add(xpBarFill);

		// Animasyon
		alpha = 0;
		var startX = x;
		x += 25;
		FlxTween.tween(this, {alpha: 1, x: startX}, 0.4, {
			ease: FlxEase.backOut,
			startDelay: 0.15
		});

		saveCache();
	}

	// ══════════════════════════════════
	//  REBUILD
	// ══════════════════════════════════
	public function rebuild():Void {
		while (members.length > 0) {
			var m = members[0];
			remove(m, true);
			if (m != null)
				m.destroy();
		}

		bg = null;
		accentBar = null;
		borderBottom = null;
		avatarBg = null;
		avatarLetter = null;
		onlineDot = null;
		usernameText = null;
		levelText = null;
		rankText = null;
		achievementText = null;
		xpBarBg = null;
		xpBarFill = null;
		guestText = null;
		guestSubText = null;
		guestIcon = null;
		_built = false;

		if (AuthManager.isLoggedIn)
			buildLoggedIn();
		else
			buildGuest();
	}

	// ══════════════════════════════════
	//  UPDATE
	// ══════════════════════════════════
	override function update(elapsed:Float):Void {
		if (!_built)
			return;

		super.update(elapsed);

		_pulseTime += elapsed;

		// Online dot pulse
		if (onlineDot != null)
			onlineDot.alpha = 0.6 + Math.sin(_pulseTime * 3) * 0.4;

		// Guest alt yazı yanıp sönme
		if (_isGuest && guestSubText != null)
			guestSubText.alpha = 0.4 + Math.sin(_pulseTime * 2) * 0.4;

		// Hover
		var hovered = FlxG.mouse.overlaps(this);
		if (bg != null)
			bg.alpha = hovered ? 1.0 : 0.95;
		if (accentBar != null)
			accentBar.scale.x = hovered ? 1.8 : 1.0;

		// Tıklama
		if (hovered && FlxG.mouse.justPressed)
			onClick();
	}

	function onClick():Void {
		FlxTween.tween(scale, {x: 0.95, y: 0.95}, 0.08, {
			ease: FlxEase.sineOut,
			onComplete: function(_) {
				FlxTween.tween(scale, {x: 1, y: 1}, 0.12, {ease: FlxEase.backOut});
			}
		});

		if (_isGuest) {
			MusicBeatState.switchState(new states.LoginState());
		}
	}

	// ══════════════════════════════════
	//  REFRESH
	// ══════════════════════════════════
	public function refresh():Void {
		if (!AuthManager.isLoggedIn && !_isGuest) {
			rebuild();
			return;
		}

		if (AuthManager.isLoggedIn && _isGuest) {
			rebuild();
			return;
		}

		if (!_isGuest) {
			if (usernameText != null)
				usernameText.text = AuthManager.currentUsername ?? "Player";

			if (avatarLetter != null) {
				var username = AuthManager.currentUsername ?? "P";
				avatarLetter.text = username.charAt(0).toUpperCase();
			}

			if (levelText != null) {
				var level = AuthManager.currentLevel ?? 1;
				var up = AuthManager.currentUltraPoints ?? 0.0;
				levelText.text = 'Lv.$level  |  ${formatNumber(up)} UP';
			}

			if (rankText != null) {
				var up = AuthManager.currentUltraPoints ?? 0.0;
				var rank = getRankFromUP(up);
				rankText.text = getRankTitle(rank);
				rankText.color = getRankColor(rank);
			}

			#if ACHIEVEMENTS_ALLOWED
			if (achievementText != null) {
				var achCount = Achievements.achievementsUnlocked.length;
				achievementText.text = '⭐ $achCount';
			}
			#end

			updateXPBar();
			saveCache();
		}
	}

	function updateXPBar():Void {
		if (xpBarFill == null || xpBarBg == null)
			return;
		var xp = getXPProgress();
		var fillWidth = Std.int(Math.max(3, xpBarBg.width * xp));
		xpBarFill.makeGraphic(fillWidth, XP_BAR_H, COL_ACCENT);
	}

	// ══════════════════════════════════
	//  RANK
	// ══════════════════════════════════
	function getRankFromUP(up:Float):String {
		if (up >= 100000) return "legend";
		if (up >= 50000) return "grandmaster";
		if (up >= 25000) return "master";
		if (up >= 10000) return "diamond";
		if (up >= 5000) return "platinum";
		if (up >= 2000) return "gold";
		if (up >= 500) return "silver";
		return "bronze";
	}

	function getRankTitle(rank:String):String {
		return switch (rank.toLowerCase()) {
			case "bronze": "Bronze";
			case "silver": "Silver";
			case "gold": "Gold";
			case "platinum": "Platinum";
			case "diamond": "Diamond";
			case "master": "Master";
			case "grandmaster": "Grandmaster";
			case "legend": "LEGEND";
			default: rank;
		};
	}

	function getRankColor(rank:String):FlxColor {
		return switch (rank.toLowerCase()) {
			case "bronze": 0xFFCD7F32;
			case "silver": 0xFFC0C0C0;
			case "gold": COL_GOLD;
			case "platinum": 0xFFE5E4E2;
			case "diamond": COL_CYAN;
			case "master": COL_ACCENT;
			case "grandmaster": COL_PINK;
			case "legend": 0xFFFF6B6B;
			default: COL_MUTED;
		};
	}

	function getXPProgress():Float {
		var level = AuthManager.currentLevel ?? 1;
		var score = AuthManager.currentScore ?? 0;
		var xpForCurrentLevel = getXPForLevel(level);
		var xpForNextLevel = getXPForLevel(level + 1);
		var xpNeeded = xpForNextLevel - xpForCurrentLevel;
		var xpProgress = score - xpForCurrentLevel;
		if (xpNeeded <= 0)
			return 1.0;
		return Math.max(0, Math.min(1, xpProgress / xpNeeded));
	}

	function getXPForLevel(level:Int):Int {
		return Std.int(100 * Math.pow(1.15, level - 1));
	}

	function formatNumber(num:Float):String {
		if (num >= 1000000)
			return Std.string(FlxMath.roundDecimal(num / 1000000, 1)) + "M";
		if (num >= 1000)
			return Std.string(FlxMath.roundDecimal(num / 1000, 1)) + "K";
		return Std.string(Std.int(num));
	}

	// ══════════════════════════════════
	//  CACHE
	// ══════════════════════════════════
	function saveCache():Void {
		#if sys
		try {
			var data = {
				username: AuthManager.currentUsername,
				level: AuthManager.currentLevel,
				score: AuthManager.currentScore,
				ultraPoints: AuthManager.currentUltraPoints,
				country: AuthManager.currentCountry,
				avatar: AuthManager.currentAvatar,
				timestamp: Date.now().toString()
			};
			var json = haxe.Json.stringify(data);
			File.saveContent(getCachePath(), json);
		} catch (e:Dynamic) {
			trace('[ProfileBox] Cache save failed: $e');
		}
		#end
	}

	public static function loadCache():Bool {
		#if sys
		try {
			var path = getCachePath();
			if (!FileSystem.exists(path))
				return false;
			var content = File.getContent(path);
			var data:Dynamic = haxe.Json.parse(content);
			AuthManager.currentUsername = data.username ?? "Player";
			AuthManager.currentLevel = data.level ?? 1;
			AuthManager.currentScore = data.score ?? 0;
			AuthManager.currentUltraPoints = data.ultraPoints ?? 0.0;
			AuthManager.currentCountry = data.country ?? "";
			trace('[ProfileBox] Cache loaded: ${data.username}');
			return true;
		} catch (e:Dynamic) {
			trace('[ProfileBox] Cache load failed: $e');
		}
		#end
		return false;
	}

	public static function clearCache():Void {
		#if sys
		try {
			var path = getCachePath();
			if (FileSystem.exists(path))
				FileSystem.deleteFile(path);
		} catch (e:Dynamic) {}
		#end
	}

	static function getCachePath():String {
		#if android
		return StorageUtil.getExternalStorageDirectory() + CACHE_FILE;
		#elseif sys
		return Sys.getCwd() + CACHE_FILE;
		#else
		return CACHE_FILE;
		#end
	}

	public static function syncFromAuth():Void {
		if (!AuthManager.isLoggedIn)
			return;

		#if sys
		try {
			var data = {
				username: AuthManager.currentUsername,
				level: AuthManager.currentLevel,
				score: AuthManager.currentScore,
				ultraPoints: AuthManager.currentUltraPoints,
				country: AuthManager.currentCountry,
				timestamp: Date.now().toString()
			};
			var json = haxe.Json.stringify(data);
			sys.io.File.saveContent(getStaticCachePath(), json);
		} catch (e:Dynamic) {
			trace('[ProfileBox] syncFromAuth failed: $e');
		}
		#end

		if (instance != null)
			instance.rebuild();
	}

	private static function getStaticCachePath():String {
		#if android
		return StorageUtil.getExternalStorageDirectory() + "profile_cache.json";
		#elseif sys
		return Sys.getCwd() + "profile_cache.json";
		#else
		return "profile_cache.json";
		#end
	}

	public static function getCachedProfile():Dynamic {
		#if sys
		try {
			var path = getStaticCachePath();
			if (!sys.FileSystem.exists(path))
				return null;
			var content = sys.io.File.getContent(path);
			return haxe.Json.parse(content);
		} catch (e:Dynamic) {
			trace('[ProfileBox] getCachedProfile failed: $e');
		}
		#end
		return null;
	}

	public static function onLogin():Void {
		if (instance != null)
			instance.rebuild();
	}

	public static function onLogout():Void {
		clearCache();
		AuthManager.logout();
		if (instance != null)
			instance.rebuild();
	}

	override function destroy():Void {
		if (instance == this)
			instance = null;
		super.destroy();
	}
}