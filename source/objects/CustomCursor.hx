package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.math.FlxMath;

class CustomCursor extends FlxSpriteGroup {
	static inline final COL_DOT = 0xFFFFFFFF;
	static inline final COL_RING = 0xFFA855F7;
	static inline final COL_CLICK = 0xFF22c55e;

	static inline final DOT_SIZE = 6;
	static inline final RING_SIZE = 28;

	public static var instance:CustomCursor = null;

	var dot:FlxSprite;
	var ringParts:Array<FlxSprite> = [];
	var rippleParts:Array<FlxSprite> = [];

	var _ringScale:Float = 1.0;
	var _ringTargetScale:Float = 1.0;
	var _isClicking:Bool = false;
	var _breatheTime:Float = 0;
	var _rippleAlpha:Float = 0;
	var _rippleScale:Float = 1.0;

	public function new() {
		super();
		instance = this;
		FlxG.mouse.visible = false;

		// ── Ring: 4 kenar çubukla kare halka ──
		ringParts = makeRing(RING_SIZE, 2, COL_RING);

		// ── Ripple: büyük halka ──
		rippleParts = makeRing(RING_SIZE + 14, 2, COL_CLICK);
		for (p in rippleParts)
			p.alpha = 0;

		// ── Dot: merkez kare ──
		dot = new FlxSprite();
		dot.makeGraphic(DOT_SIZE, DOT_SIZE, COL_DOT);
		dot.scrollFactor.set();
		add(dot);

		scrollFactor.set();
	}

	function makeRing(size:Int, thick:Int, color:Int):Array<FlxSprite> {
		var parts:Array<FlxSprite> = [];
		var half = Std.int(size / 2);

		// Üst
		var top = new FlxSprite();
		top.makeGraphic(size, thick, color);
		top.scrollFactor.set();
		add(top);
		parts.push(top);

		// Alt
		var bot = new FlxSprite();
		bot.makeGraphic(size, thick, color);
		bot.scrollFactor.set();
		add(bot);
		parts.push(bot);

		// Sol
		var left = new FlxSprite();
		left.makeGraphic(thick, size, color);
		left.scrollFactor.set();
		add(left);
		parts.push(left);

		// Sağ
		var right = new FlxSprite();
		right.makeGraphic(thick, size, color);
		right.scrollFactor.set();
		add(right);
		parts.push(right);

		return parts;
	}

	function positionRing(parts:Array<FlxSprite>, cx:Float, cy:Float, size:Float, thick:Int):Void {
		var half = size / 2;
		if (parts.length < 4) return;

		parts[0].x = cx - half; // üst
		parts[0].y = cy - half;
		parts[0].scale.x = size / (RING_SIZE > 0 ? RING_SIZE : 1);

		parts[1].x = cx - half; // alt
		parts[1].y = cy + half - thick;
		parts[1].scale.x = size / (RING_SIZE > 0 ? RING_SIZE : 1);

		parts[2].x = cx - half; // sol
		parts[2].y = cy - half;
		parts[2].scale.y = size / (RING_SIZE > 0 ? RING_SIZE : 1);

		parts[3].x = cx + half - thick; // sağ
		parts[3].y = cy - half;
		parts[3].scale.y = size / (RING_SIZE > 0 ? RING_SIZE : 1);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		FlxG.mouse.visible = false;

		var mx = FlxG.mouse.screenX;
		var my = FlxG.mouse.screenY;

		_breatheTime += elapsed;

		// ── Dot pozisyon ──
		if (dot != null) {
			dot.x = mx - DOT_SIZE / 2;
			dot.y = my - DOT_SIZE / 2;
		}

		// ── Tıklama ──
		if (FlxG.mouse.justPressed) {
			_isClicking = true;
			_ringTargetScale = 0.65;
			_rippleAlpha = 1.0;
			_rippleScale = 0.6;

			if (dot != null)
				dot.scale.set(0.5, 0.5);
		}

		if (FlxG.mouse.justReleased) {
			_isClicking = false;
			_ringTargetScale = 1.0;

			if (dot != null)
				dot.scale.set(1.5, 1.5);
		}

		// ── Dot scale lerp ──
		if (dot != null) {
			dot.scale.x += (1.0 - dot.scale.x) * Math.min(1, elapsed * 14);
			dot.scale.y += (1.0 - dot.scale.y) * Math.min(1, elapsed * 14);

			// Pulse
			if (!_isClicking)
				dot.alpha = 0.85 + Math.sin(_breatheTime * 3) * 0.15;
			else
				dot.alpha = 1.0;
		}

		// ── Ring scale lerp ──
		_ringScale += (_ringTargetScale - _ringScale) * Math.min(1, elapsed * 12);

		// Breathe
		var breathe = _isClicking ? 1.0 : (1.0 + Math.sin(_breatheTime * 2) * 0.06);
		var finalRingSize = RING_SIZE * _ringScale * breathe;

		// Ring pozisyon
		positionRing(ringParts, mx, my, finalRingSize, 2);

		// Ring renk
		var ringColor = _isClicking ? COL_CLICK : COL_RING;
		var ringAlpha = _isClicking ? 0.9 : 0.5;
		for (p in ringParts) {
			p.color = ringColor;
			p.alpha = ringAlpha;
		}

		// ── Ripple animasyon ──
		if (_rippleAlpha > 0) {
			_rippleAlpha -= elapsed * 3.5;
			_rippleScale += elapsed * 5;

			if (_rippleAlpha < 0) _rippleAlpha = 0;

			var rippleSize = (RING_SIZE + 14) * _rippleScale;
			positionRing(rippleParts, mx, my, rippleSize, 2);

			for (p in rippleParts)
				p.alpha = _rippleAlpha * 0.7;
		} else {
			for (p in rippleParts)
				p.alpha = 0;
		}
	}

	// ── State'e ekle ──
	public static function addToState():Void {
		FlxG.mouse.visible = false;

		if (instance != null) {
			if (FlxG.state != null && !FlxG.state.members.contains(instance))
				FlxG.state.add(instance);
			return;
		}

		instance = new CustomCursor();
		if (FlxG.state != null)
			FlxG.state.add(instance);
	}

	override function destroy():Void {
		FlxG.mouse.visible = true;
		ringParts = null;
		rippleParts = null;
		if (instance == this)
			instance = null;
		super.destroy();
	}
}