package objects;

import openfl.Lib;
import openfl.Assets;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.events.Event;

using StringTools;

enum PopupPosition
{
	TOP_LEFT;
	TOP_CENTER;
	TOP_RIGHT;
	BOTTOM_LEFT;
	BOTTOM_CENTER;
	BOTTOM_RIGHT;
	BOTTOM_RIGHT_LEFT; // FOR US CARD
}

enum PopupState
{
	SLIDING_IN;
	ACTIVE;
	FADING_OUT;
	DEAD;
}

class PopupThing extends Sprite
{
	static inline var PADDING:Float = 16;
	static inline var MIN_W:Float = 240;
	static inline var MAX_W:Float = 400;
	static inline var CORNER:Float = 6;
	static inline var BAR_H:Float = 4;
	static inline var SLIDE_DURATION:Float = 0.35;
	static inline var FADE_DURATION:Float = 0.30;
	static inline var MARGIN:Float = 14;

	var _bg:Shape;
	var _accentBar:Shape;
	var _timerBar:Shape;
	var _fields:Array<TextField> = [];

	var _accentColor:Int;
	var _totalTime:Float;
	var _elapsed:Float = 0;
	var _state:PopupState = SLIDING_IN;
	var _slideProgress:Float = 0;
	var _position:PopupPosition;
	var _isDead:Bool = false;
	var _onClick:Null<Void->Void>;
	var _onTick:Null<PopupThing->Float->Void>;
	var _slideStartX:Float = 0;
	var _slideStartY:Float = 0;
	var _restX:Float = 0;
	var _restY:Float = 0;

	// shake
	var _shakeIntensity:Float = 0;
	var _shakeDuration:Float = 0;
	var _shakeElapsed:Float = 0;
	var _shakeBaseX:Float = 0;
	var _shakeBaseY:Float = 0;
	var _isShaking:Bool = false;

	public var totalW:Float = 0;
	public var totalH:Float = 0;

	public function new()
	{
		super();
	}

	public function setup(lines:Array<PopupLine>, duration:Float = 5, accentColor:Int = 0xFF4FC3F7, position:PopupPosition = BOTTOM_RIGHT,
			?onClick:Void->Void, ?onTick:PopupThing->Float->Void):PopupThing
	{
		while (numChildren > 0)
			removeChildAt(0);
		_fields = [];

		var s:Float = _getScale();

		_accentColor = accentColor;
		_totalTime = Math.max(1, duration);
		_elapsed = 0;
		_state = SLIDING_IN;
		_slideProgress = 0;
		_isDead = false;
		_onClick = onClick;
		_onTick = onTick;
		_position = position;
		_isShaking = false;
		alpha = 1;

		var fontName:String = Assets.getFont('assets/fonts/vcr.ttf').fontName;

		var sPad:Float = PADDING * s;
		var sBarH:Float = BAR_H * s;
		var sMinW:Float = MIN_W * s;
		var sMaxW:Float = MAX_W * s;

		var maxTextW:Float = 0;
		var totalTextH:Float = 0;

		for (line in lines)
		{
			var tf = new TextField();
			tf.selectable = false;
			tf.multiline = true;
			tf.wordWrap = true;
			tf.embedFonts = true;
			tf.defaultTextFormat = new TextFormat(fontName, Std.int(line.size * s), line.color, line.bold);
			tf.antiAliasType = ADVANCED;
			tf.text = line.text;
			tf.width = sMaxW;
			var tw:Float = tf.textWidth + 8;
			if (tw > maxTextW)
				maxTextW = tw;
			_fields.push(tf);
		}

		var contentW:Float = Math.min(Math.max(maxTextW, sMinW), sMaxW);
		for (tf in _fields)
			tf.width = contentW;

		for (tf in _fields)
			totalTextH += tf.textHeight + (4 * s);

		totalTextH += (lines.length - 1) * (4 * s);

		totalW = contentW + (sPad * 2);
		totalH = sPad + totalTextH + sPad + sBarH;

		_bg = new Shape();
		_drawRoundRect(_bg, totalW, totalH, CORNER * s, 0xEE111318);
		addChild(_bg);

		_accentBar = new Shape();
		_accentBar.x = 0;
		_accentBar.y = 0;
		_drawRect(_accentBar, 4 * s, totalH - sBarH, _accentColor);
		addChild(_accentBar);

		var curY:Float = sPad;
		for (tf in _fields)
		{
			tf.x = sPad;
			tf.y = curY;
			addChild(tf);
			curY += tf.textHeight + (4 * s) + (4 * s);
		}

		_timerBar = new Shape();
		_timerBar.y = totalH - sBarH;
		addChild(_timerBar);
		_updateTimerBar(1.0);

		var hit = new Sprite();
		hit.graphics.beginFill(0x000000, 0);
		hit.graphics.drawRect(0, 0, totalW, totalH);
		hit.graphics.endFill();
		addChild(hit);
		hitArea = hit;
		buttonMode = true;
		useHandCursor = true;
		addEventListener(MouseEvent.CLICK, _handleClick);

		_calcPositions();

		x = _slideStartX;
		y = _slideStartY;

		return this;
	}

	function _calcPositions()
	{
		var s:Float = _getScale();
		var winW:Float = Lib.application.window.width;
		var winH:Float = Lib.application.window.height;
		var m:Float = MARGIN * s;

		switch (_position)
		{
			case TOP_LEFT:
				_restX = m;
				_restY = m;
				_slideStartX = _restX;
				_slideStartY = -(totalH + m);
			case TOP_CENTER:
				_restX = (winW - totalW) / 2;
				_restY = m;
				_slideStartX = _restX;
				_slideStartY = -(totalH + m);
			case TOP_RIGHT:
				_restX = winW - totalW - m;
				_restY = m;
				_slideStartX = _restX;
				_slideStartY = -(totalH + m);
			case BOTTOM_LEFT:
				_restX = m;
				_restY = winH - totalH - m;
				_slideStartX = _restX;
				_slideStartY = winH + m;
			case BOTTOM_CENTER:
				_restX = (winW - totalW) / 2;
				_restY = winH - totalH - m;
				_slideStartX = _restX;
				_slideStartY = winH + m;
			case BOTTOM_RIGHT:
				_restX = winW - totalW - m;
				_restY = winH - totalH - m;
				_slideStartX = winW + m;
				_slideStartY = _restY;
			case BOTTOM_RIGHT_LEFT:
				var upCardW:Float = 280 * s;
				_restX = winW - totalW - upCardW - m - (m * 0.5);
				_restY = winH - totalH - m;
				_slideStartX = _restX;
				_slideStartY = winH + m;
		}
	}

	override function __enterFrame(deltaTime:Int)
	{
		super.__enterFrame(deltaTime);
		if (_isDead || deltaTime > 500)
			return;

		var dt:Float = deltaTime * 0.001;

		switch (_state)
		{
			case SLIDING_IN:
				_slideProgress += dt / SLIDE_DURATION;
				if (_slideProgress >= 1)
				{
					_slideProgress = 1;
					_state = ACTIVE;
				}
				var t:Float = 1 - Math.pow(1 - _slideProgress, 3);
				x = _slideStartX + (_restX - _slideStartX) * t;
				y = _slideStartY + (_restY - _slideStartY) * t;
				alpha = t;

			case ACTIVE:
				_elapsed += dt;
				x = _restX;
				y = _restY;

				if (_onTick != null)
					_onTick(this, dt);

				var ratio:Float = 1 - (_elapsed / _totalTime);
				if (ratio < 0)
					ratio = 0;
				_updateTimerBar(ratio);

				if (_isShaking)
					_processShake(dt);

				if (_elapsed >= _totalTime)
					_beginFadeOut();

			case FADING_OUT:
				_elapsed += dt;
				var fadeRatio:Float = 1 - (_elapsed / FADE_DURATION);
				if (fadeRatio < 0)
					fadeRatio = 0;
				alpha = fadeRatio;
				if (fadeRatio <= 0)
					_die();

			case DEAD:
		}
	}

	public function shake(intensity:Float = 3, duration:Float = 0.08)
	{
		_shakeIntensity = intensity * _getScale();
		_shakeDuration = duration;
		_shakeElapsed = 0;
		_shakeBaseX = _restX;
		_shakeBaseY = _restY;
		_isShaking = true;
	}

	function _processShake(dt:Float)
	{
		_shakeElapsed += dt;
		if (_shakeElapsed >= _shakeDuration)
		{
			_isShaking = false;
			x = _restX;
			y = _restY;
			return;
		}
		var prog:Float = _shakeElapsed / _shakeDuration;
		var fade:Float = 1 - prog;
		var offX:Float = (Math.random() * 2 - 1) * _shakeIntensity * fade;
		var offY:Float = (Math.random() * 2 - 1) * _shakeIntensity * fade;
		x = _restX + offX;
		y = _restY + offY;
	}

	public function updateLine(index:Int, newText:String)
	{
		if (index >= 0 && index < _fields.length)
			_fields[index].text = newText;
	}

	public function updateLineColor(index:Int, newColor:Int)
	{
		if (index >= 0 && index < _fields.length)
			_fields[index].textColor = newColor;
	}

	function _beginFadeOut()
	{
		_elapsed = 0;
		_state = FADING_OUT;
		removeEventListener(MouseEvent.CLICK, _handleClick);
	}

	function _die()
	{
		if (_isDead)
			return;
		_isDead = true;
		_state = DEAD;
		if (parent != null)
			parent.removeChild(this);
		PopupMgr.instance._recycle(this);
	}

	function _handleClick(_:MouseEvent)
	{
		if (_onClick != null)
			_onClick();
		_beginFadeOut();
	}

	function _updateTimerBar(ratio:Float)
	{
		var s:Float = _getScale();
		_timerBar.graphics.clear();
		_timerBar.graphics.beginFill(_accentColor, 0.85);
		_timerBar.graphics.drawRect(0, 0, totalW * ratio, BAR_H * s);
		_timerBar.graphics.endFill();
	}

	function _drawRoundRect(s:Shape, w:Float, h:Float, r:Float, color:Int)
	{
		s.graphics.clear();
		s.graphics.beginFill(color & 0xFFFFFF, ((color >> 24) & 0xFF) / 255);
		if (r > 0)
			s.graphics.drawRoundRect(0, 0, w, h, r * 2, r * 2);
		else
			s.graphics.drawRect(0, 0, w, h);
		s.graphics.endFill();
	}

	function _drawRect(s:Shape, w:Float, h:Float, color:Int)
	{
		s.graphics.clear();
		s.graphics.beginFill(color & 0xFFFFFF, 1);
		s.graphics.drawRect(0, 0, w, h);
		s.graphics.endFill();
	}

	function _getScale():Float
	{
		var s:Float = Lib.application.window.width / 1280;
		return s < 1 ? 1 : s;
	}
}

class PopupLine
{
	public var text:String;
	public var size:Int;
	public var color:Int;
	public var bold:Bool;

	public function new(text:String, size:Int = 18, color:Int = 0xFFFFFF, bold:Bool = false)
	{
		this.text = text;
		this.size = size;
		this.color = color;
		this.bold = bold;
	}
}

class PopupMgr extends Sprite
{
	public static var instance:PopupMgr;

	var _pool:Array<PopupThing> = [];
	var _active:Array<PopupThing> = [];

	public function new()
	{
		super();
		instance = this;
	}

	public function spawn(lines:Array<PopupLine>, duration:Float = 5, accentColor:Int = 0xFF4FC3F7, position:PopupPosition = BOTTOM_RIGHT,
			?onClick:Void->Void, ?onTick:PopupThing->Float->Void):PopupThing
	{
		var msg:PopupThing = _pool.length > 0 ? _pool.pop() : new PopupThing();
		msg.setup(lines, duration, accentColor, position, onClick, onTick);
		addChild(msg);
		_active.push(msg);
		return msg;
	}

	public function _recycle(msg:PopupThing)
	{
		_active.remove(msg);
		_pool.push(msg);
	}
}