package objects;

#if ACHIEVEMENTS_ALLOWED
import openfl.Lib;
import openfl.Assets;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Matrix;

class AchievementPopup extends Sprite {
	public var onFinish:Void->Void = null;

	public static var DEBUG_MODE:Bool = true;
	static var _debugTriggered:Bool = false;

	public static function debugTest():Void {
		if (!DEBUG_MODE || _debugTriggered)
			return;
		_debugTriggered = true;

		var startTime:Float = Lib.getTimer();
		FlxG.stage.addEventListener(Event.ENTER_FRAME, function debugFrame1(e:Event):Void {
			var now:Float = Lib.getTimer();
			if ((now - startTime) >= 1000) {
				FlxG.stage.removeEventListener(Event.ENTER_FRAME, debugFrame1);
				Achievements.startPopup('__debug_test_1', null);

				var startTime2:Float = Lib.getTimer();
				FlxG.stage.addEventListener(Event.ENTER_FRAME, function debugFrame2(e2:Event):Void {
					var now2:Float = Lib.getTimer();
					if ((now2 - startTime2) >= 2500) {
						FlxG.stage.removeEventListener(Event.ENTER_FRAME, debugFrame2);
						Achievements.startPopup('__debug_test_2', null);
					}
				});
			}
		});
	}

	static inline var PADDING:Float = 14;
	static inline var ICON_SIZE:Float = 64;
	static inline var ICON_PADDING:Float = 14;
	static inline var MIN_CONTENT_W:Float = 200;
	static inline var MAX_CONTENT_W:Float = 340;
	static inline var CORNER:Float = 6;
	static inline var ACCENT_BAR_W:Float = 4;
	static inline var TIMER_BAR_H:Float = 4;
	static inline var SLIDE_DURATION:Float = 0.40;
	static inline var FADE_DURATION:Float = 0.30;
	static inline var DISPLAY_TIME:Float = 4.0;
	static inline var MARGIN_TOP:Float = 14;
	static inline var STACK_GAP:Float = 10;

	static inline var ACCENT_COLOR:Int = 0xFFFFD740;

	var _bg:Shape;
	var _accentBar:Shape;
	var _timerBar:Shape;
	var _iconSprite:Sprite;
	var _titleField:TextField;
	var _descField:TextField;

	var _totalTime:Float;
	var _elapsed:Float = 0;
	var _state:AchievementState = SLIDING_IN;
	var _slideProgress:Float = 0;
	var _isDead:Bool = false;
	var _lastTimerUpdate:Float = -1;

	public var intendedY:Float = 0;
	var _intendedYLerp:Float = 0;

	public var totalW:Float = 0;
	public var totalH:Float = 0;

	public function new(achieve:String, ?onFinishCb:Void->Void) {
		super();
		onFinish = onFinishCb;
		_totalTime = DISPLAY_TIME;

		var s:Float = _getScale();

		var isDebug:Bool = (achieve != null && StringTools.startsWith(achieve, '__debug_test'));

		var achName:String = 'Unknown';
		var achDesc:String = '';
		var achievement:Achievement = null;
		var graphic:flixel.graphics.FlxGraphic = null;
		var hasAntialias:Bool = ClientPrefs.data.antialiasing;

		if (isDebug) {
			achName = 'Debug Achievement';
			achDesc = 'Bu bir test popup\'idir!\nHer sey calisiyor!';
			graphic = Paths.image('unknownMod', false);
		} else {
			if (achieve != null && Achievements.exists(achieve))
				achievement = Achievements.get(achieve);

			if (achievement != null) {
				if (achievement.name != null)
					achName = Language.getPhrase('achievement_$achieve', achievement.name);
				if (achievement.description != null)
					achDesc = Language.getPhrase('description_$achieve', achievement.description);
			}

			var imagePath:String = 'achievements/$achieve';

			#if MODS_ALLOWED
			var lastMod = Mods.currentModDirectory;
			if (achievement != null)
				Mods.currentModDirectory = achievement.mod != null ? achievement.mod : '';
			#end

			if (Paths.fileExists('images/$imagePath-pixel.png', IMAGE)) {
				graphic = Paths.image('$imagePath-pixel', false);
				hasAntialias = false;
			} else {
				graphic = Paths.image(imagePath, false);
			}

			#if MODS_ALLOWED
			Mods.currentModDirectory = lastMod;
			#end

			if (graphic == null)
				graphic = Paths.image('unknownMod', false);
		}

		var fontName:String = Assets.getFont('assets/fonts/vcr.ttf').fontName;

		_titleField = _makeField(fontName, Std.int(18 * s), 0xFFFFFFFF, true);
		_titleField.text = achName;

		_descField = _makeField(fontName, Std.int(13 * s), 0xFFCCCCCC, false);
		_descField.text = achDesc;

		var hasDesc:Bool = achDesc.length > 0;

		var sPad:Float = PADDING * s;
		var sIconSize:Float = ICON_SIZE * s;
		var sIconPad:Float = ICON_PADDING * s;
		var sAccentW:Float = ACCENT_BAR_W * s;
		var sTimerH:Float = TIMER_BAR_H * s;
		var sMinW:Float = MIN_CONTENT_W * s;
		var sMaxW:Float = MAX_CONTENT_W * s;

		_titleField.width = sMaxW;
		_descField.width = sMaxW;
		var rawTW:Float = _titleField.textWidth + 8;
		var rawDW:Float = hasDesc ? (_descField.textWidth + 8) : 0;

		var contentW:Float = Math.min(Math.max(Math.max(rawTW, rawDW), sMinW), sMaxW);
		_titleField.width = contentW;
		_descField.width = contentW;

		var titleH:Float = _titleField.textHeight + (4 * s);
		var descH:Float = hasDesc ? (_descField.textHeight + (4 * s)) : 0;

		var iconAreaW:Float = sIconPad + sIconSize + sIconPad;
		var textAreaW:Float = contentW + sPad;

		totalW = sAccentW + iconAreaW + textAreaW;
		totalH = sPad + Math.max(sIconSize, titleH + (hasDesc ? (4 * s + descH) : 0)) + sPad + sTimerH;

		_bg = new Shape();
		_drawRoundRect(_bg, totalW, totalH, CORNER * s, 0xEE111318);
		addChild(_bg);

		_accentBar = new Shape();
		_drawRoundRect(_accentBar, sAccentW, totalH - sTimerH, CORNER * s, ACCENT_COLOR);
		addChild(_accentBar);

		_iconSprite = new Sprite();
		if (graphic != null) {
			var bmp:BitmapData = graphic.bitmap;
			var scaleFactorX:Float = sIconSize / bmp.width;
			var scaleFactorY:Float = sIconSize / bmp.height;
			var mat:Matrix = new Matrix(scaleFactorX, 0, 0, scaleFactorY, 0, 0);
			_iconSprite.graphics.beginBitmapFill(bmp, mat, false, hasAntialias);
			_iconSprite.graphics.drawRoundRect(0, 0, sIconSize, sIconSize, 8 * s, 8 * s);
			_iconSprite.graphics.endFill();
		}

		if (graphic == null && isDebug) {
			_iconSprite.graphics.beginFill(ACCENT_COLOR & 0x00FFFFFF, 0.3);
			_iconSprite.graphics.drawRoundRect(0, 0, sIconSize, sIconSize, 8 * s, 8 * s);
			_iconSprite.graphics.endFill();

			var qField = _makeField(fontName, Std.int(32 * s), ACCENT_COLOR & 0x00FFFFFF, true);
			qField.text = '?';
			qField.width = sIconSize;
			qField.height = sIconSize;
			var qFormat = new TextFormat();
			qFormat.align = CENTER;
			qField.setTextFormat(qFormat);
			qField.y = (sIconSize - qField.textHeight) / 2 - 4 * s;
			_iconSprite.addChild(qField);
		}

		_iconSprite.x = sAccentW + sIconPad;
		_iconSprite.y = (totalH - sTimerH - sIconSize) / 2;
		addChild(_iconSprite);

		var textX:Float = sAccentW + iconAreaW;
		var textBlockH:Float = titleH + (hasDesc ? (4 * s + descH) : 0);
		var textStartY:Float = (totalH - sTimerH - textBlockH) / 2;

		_titleField.x = textX;
		_titleField.y = textStartY;
		addChild(_titleField);

		if (hasDesc) {
			_descField.x = textX;
			_descField.y = textStartY + titleH + (4 * s);
			addChild(_descField);
		}

		_timerBar = new Shape();
		_timerBar.y = totalH - sTimerH;
		addChild(_timerBar);
		_updateTimerBar(1.0);

		intendedY = MARGIN_TOP * s;
		_intendedYLerp = intendedY;
		_repositionX();
		this.y = -(totalH + 10 * s);

		FlxG.game.addChild(this);

		_lastTimerUpdate = Lib.getTimer();
		addEventListener(Event.ENTER_FRAME, _onEnterFrame);
		FlxG.stage.addEventListener(Event.RESIZE, _onResize);

		if (isDebug)
			trace('[AchievementPopup] DEBUG popup spawned!');
	}

	function _onEnterFrame(e:Event):Void {
		if (_isDead)
			return;

		var now:Float = Lib.getTimer();
		var dt:Float = (now - _lastTimerUpdate) * 0.001;
		_lastTimerUpdate = now;

		if (dt > 0.5)
			return;

		var s:Float = _getScale();
		_intendedYLerp += (intendedY - _intendedYLerp) * Math.min(1, dt * 12);

		switch (_state) {
			case SLIDING_IN:
				_slideProgress += dt / SLIDE_DURATION;
				if (_slideProgress >= 1) {
					_slideProgress = 1;
					_state = COUNTING;
				}
				var t:Float = 1 - Math.pow(1 - _slideProgress, 3);
				var offscreenY:Float = -(totalH + 10 * s);
				this.y = offscreenY + (_intendedYLerp - offscreenY) * t;
				this.alpha = t;

			case COUNTING:
				_elapsed += dt;
				this.y = _intendedYLerp;
				var ratio:Float = 1 - (_elapsed / _totalTime);
				if (ratio < 0)
					ratio = 0;
				_updateTimerBar(ratio);
				if (_elapsed >= _totalTime)
					_beginFadeOut();

			case FADING_OUT:
				_elapsed += dt;
				var fadeRatio:Float = 1 - (_elapsed / FADE_DURATION);
				if (fadeRatio < 0)
					fadeRatio = 0;
				this.alpha = fadeRatio;
				this.y -= 60 * s * dt;
				if (fadeRatio <= 0)
					_die();

			case DEAD:
		}

		_repositionX();
	}

	function _beginFadeOut():Void {
		_elapsed = 0;
		_state = FADING_OUT;
	}

	function _die():Void {
		if (_isDead)
			return;
		_isDead = true;
		_state = DEAD;
		destroy();
	}

	function _onResize(e:Event):Void {
		_repositionX();
	}

	function _repositionX():Void {
		var winW:Float = FlxG.stage.stageWidth;
		if (winW <= 0)
			winW = Lib.application.window.width;
		this.x = (winW - totalW) / 2;
	}

	function _updateTimerBar(ratio:Float):Void {
		var s:Float = _getScale();
		_timerBar.graphics.clear();
		_timerBar.graphics.beginFill(ACCENT_COLOR & 0x00FFFFFF, 0.85);
		_timerBar.graphics.drawRect(0, 0, totalW * ratio, TIMER_BAR_H * s);
		_timerBar.graphics.endFill();
	}

	function _makeField(font:String, size:Int, color:Int, bold:Bool):TextField {
		var tf = new TextField();
		tf.selectable = false;
		tf.multiline = true;
		tf.wordWrap = true;
		tf.defaultTextFormat = new TextFormat(font, size, color, bold);
		tf.antiAliasType = ADVANCED;
		tf.embedFonts = true;
		return tf;
	}

	function _drawRoundRect(s:Shape, w:Float, h:Float, r:Float, color:Int, a:Float = 1.0):Void {
		s.graphics.clear();
		s.graphics.beginFill(color, a);
		if (r > 0)
			s.graphics.drawRoundRect(0, 0, w, h, r * 2, r * 2);
		else
			s.graphics.drawRect(0, 0, w, h);
		s.graphics.endFill();
	}

	function _getScale():Float {
		var s:Float = FlxG.stage.stageHeight / FlxG.height;
		return s < 1 ? 1 : s;
	}

	public function destroy():Void {
		Achievements._popups.remove(this);

		if (FlxG.game.contains(this))
			FlxG.game.removeChild(this);

		FlxG.stage.removeEventListener(Event.RESIZE, _onResize);
		removeEventListener(Event.ENTER_FRAME, _onEnterFrame);

		if (onFinish != null)
			onFinish();
	}
}

enum AchievementState {
	SLIDING_IN;
	COUNTING;
	FADING_OUT;
	DEAD;
}
#end