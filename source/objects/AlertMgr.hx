package objects;

import openfl.Lib;
import openfl.Assets;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.geom.ColorTransform;

using StringTools;

class AlertMessage extends Sprite
{
    public static inline var COLOR_INFO:Int    = 0xFF4FC3F7;
    public static inline var COLOR_SUCCESS:Int = 0xFF69F0AE;
    public static inline var COLOR_WARNING:Int = 0xFFFFD740;
    public static inline var COLOR_ERROR:Int   = 0xFFFF5252;

    static inline var PADDING:Float       = 16;
    static inline var COUNTER_W:Float     = 52;
    static inline var MIN_CONTENT_W:Float = 220;
    static inline var MAX_CONTENT_W:Float = 380;
    static inline var CORNER:Float        = 6;
    static inline var BAR_H:Float         = 4;
    static inline var SLIDE_DURATION:Float = 0.38;
    static inline var FADE_DURATION:Float  = 0.28;

    var _bg:Shape;
    var _accentBar:Shape;
    var _timerBar:Shape;
    var _counterBg:Shape;
    var _counterField:TextField;
    var _titleField:TextField;
    var _contentField:TextField;

    var _accentColor:Int;
    var _totalTime:Float;
    var _elapsed:Float        = 0;
    var _state:AlertState    = SLIDING_IN;
    var _slideProgress:Float = 0;
    var _targetY:Float       = 0;
    var _currentY:Float      = 0;
    var _onYChanged:Float->Void;
    var _onClick:Null<Void->Void>;
    var _isDead:Bool         = false;

    public var totalW:Float = 0;
    public var totalH:Float = 0;

    public function new() { super(); }

    public function setup(titleText:String, ?messageText:String, duration:Float = 5,
                          accentColor:Int = 0xFF4FC3F7, ?onClick:Void->Void):AlertMessage
    {
        while (numChildren > 0) removeChildAt(0);

        var s:Float = getScale();

        _accentColor   = accentColor;
        _totalTime     = Math.max(1, duration);
        _elapsed       = 0;
        _state         = SLIDING_IN;
        _slideProgress = 0;
        _isDead        = false;
        _onClick       = onClick;
        alpha          = 1;

        var fontName:String = Assets.getFont('assets/fonts/vcr.ttf').fontName;

        _titleField = _makeField(fontName, Std.int(20 * s), 0xFFFFFFFF, true);
        _titleField.text = titleText ?? '';

        _contentField = _makeField(fontName, Std.int(15 * s), 0xFFCCCCCC, false);
        _contentField.text = messageText ?? '';

        var hasContent:Bool = (messageText ?? '').trim().length > 0;

        var rawTW:Float    = _measureTextWidth(_titleField);
        var rawCW:Float    = hasContent ? _measureTextWidth(_contentField) : 0;
        
        var sPadding:Float = PADDING * s;
        var sMinW:Float = MIN_CONTENT_W * s;
        var sMaxW:Float = MAX_CONTENT_W * s;
        var sBarH:Float = BAR_H * s;

        var contentW:Float = Math.min(Math.max(Math.max(rawTW, rawCW), sMinW), sMaxW);

        _titleField.width   = contentW;
        _contentField.width = contentW;

        var titleH:Float   = _titleField.textHeight + (4 * s);
        var contentH:Float = hasContent ? (_contentField.textHeight + (4 * s)) : 0;
        var innerH:Float   = sPadding + titleH + (hasContent ? (6 * s + contentH) : 0) + sPadding + sBarH;

        totalW = (COUNTER_W * s) + contentW + (sPadding * 2);
        totalH = innerH;

        _bg = new Shape();
        _drawRoundRect(_bg, totalW, totalH, CORNER * s, 0xEE111318);
        addChild(_bg);

        _accentBar = new Shape();
        _drawRoundRect(_accentBar, 4 * s, totalH - sBarH, CORNER * s, _accentColor);
        addChild(_accentBar);

        _counterBg = new Shape();
        _drawRoundRect(_counterBg, COUNTER_W * s, totalH - sBarH, 0, _dimColor(_accentColor, 0.18));
        _counterBg.x = 4 * s;
        addChild(_counterBg);

        _counterField = _makeField(fontName, Std.int(22 * s), _accentColor, true);
        _counterField.width  = COUNTER_W * s;
        _counterField.height = totalH - sBarH;
        _counterField.x = 4 * s;
        _updateCounter();
        addChild(_counterField);

        var textX:Float = (COUNTER_W * s) + (4 * s) + sPadding;
        _titleField.x = textX;
        _titleField.y = sPadding;
        addChild(_titleField);

        if (hasContent)
        {
            _contentField.x = textX;
            _contentField.y = sPadding + titleH + (6 * s);
            addChild(_contentField);
        }

        _timerBar = new Shape();
        _timerBar.y = totalH - sBarH;
        addChild(_timerBar);
        
        _updateTimerBar(1.0); 

        var hit:Sprite = new Sprite();
        hit.graphics.beginFill(0x000000, 0);
        hit.graphics.drawRect(0, 0, totalW, totalH);
        hit.graphics.endFill();
        addChild(hit);
        hitArea = hit;
        buttonMode = true;
        useHandCursor = true;
        addEventListener(MouseEvent.CLICK, _onMouseClick);
        addEventListener(MouseEvent.MOUSE_OVER, _onOver);
        addEventListener(MouseEvent.MOUSE_OUT, _onOut);

        return this;
    }

    override function __enterFrame(deltaTime:Int)
    {
        super.__enterFrame(deltaTime);
        if (_isDead || deltaTime > 500) return;

        var dt:Float = deltaTime * 0.001;

        switch (_state)
        {
            case SLIDING_IN:
                _slideProgress += dt / SLIDE_DURATION;
                if (_slideProgress >= 1)
                {
                    _slideProgress = 1;
                    _state = COUNTING;
                }
                var t:Float = 1 - Math.pow(1 - _slideProgress, 3);
                y = _currentY + (-totalH - (10 * getScale())) * (1 - t);
                alpha = t;

            case COUNTING:
                _elapsed += dt;
                y = _currentY;
                var ratio:Float = 1 - (_elapsed / _totalTime);
                if (ratio < 0) ratio = 0;
                _updateTimerBar(ratio);
                _updateCounter();
                if (_elapsed >= _totalTime)
                    _beginFadeOut();

            case FADING_OUT:
                _elapsed += dt;
                var fadeRatio:Float = 1 - (_elapsed / FADE_DURATION);
                if (fadeRatio < 0) fadeRatio = 0;
                alpha = fadeRatio;
                if (fadeRatio <= 0)
                    _die();

            case DEAD:
        }
    }

    public function setTargetY(ty:Float)
    {
        _targetY  = ty;
        _currentY = ty;
        if (_state == COUNTING) y = ty;
    }

    function _beginFadeOut()
    {
        _elapsed = 0;
        _state   = FADING_OUT;
        removeEventListener(MouseEvent.CLICK, _onMouseClick);
        removeEventListener(MouseEvent.MOUSE_OVER, _onOver);
        removeEventListener(MouseEvent.MOUSE_OUT, _onOut);
    }

    function _die()
    {
        if (_isDead) return;
        _isDead = true;
        _state  = DEAD;
        if (parent != null) parent.removeChild(this);
        AlertMgr.instance._recycle(this);
    }

    function _onMouseClick(_:MouseEvent)
    {
        if (_onClick != null) _onClick();
        _beginFadeOut();
    }

    function _onOver(_:MouseEvent) { if(_state == COUNTING) alpha = 0.92; }
    function _onOut(_:MouseEvent)  { alpha = 1.0; }

    function _updateTimerBar(ratio:Float)
    {
        var s:Float = getScale();
        _timerBar.graphics.clear();
        _timerBar.graphics.beginFill(_accentColor, 0.85);
        _timerBar.graphics.drawRect(0, 0, totalW * ratio, BAR_H * s);
        _timerBar.graphics.endFill();
    }

    function _updateCounter()
    {
        var remaining:Int = Math.ceil(_totalTime - _elapsed);
        if (remaining < 0) remaining = 0;
        _counterField.text = Std.string(remaining);
        var ratio:Float = 1 - (_elapsed / _totalTime);
        _counterField.textColor = _blendColor(_dimColor(_accentColor, 0.4), _accentColor, ratio);
    }

    function _makeField(font:String, size:Int, color:Int, bold:Bool):TextField
    {
        var tf = new TextField();
        tf.selectable  = false;
        tf.multiline   = true;
        tf.wordWrap    = true;
        tf.defaultTextFormat = new TextFormat(font, size, color, bold);
        tf.antiAliasType = ADVANCED;
        tf.embedFonts  = true;
        return tf;
    }

    function _drawRoundRect(s:Shape, w:Float, h:Float, r:Float, color:Int, alpha:Float = 1.0)
    {
        s.graphics.clear();
        s.graphics.beginFill(color, alpha);
        if (r > 0)
            s.graphics.drawRoundRect(0, 0, w, h, r * 2, r * 2);
        else
            s.graphics.drawRect(0, 0, w, h);
        s.graphics.endFill();
    }
    
    function getScale():Float {
        var s:Float = Lib.application.window.width / 1280;
        return s < 1 ? 1 : s;
    }

    function _measureTextWidth(tf:TextField):Float
    {
        tf.width = MAX_CONTENT_W * getScale();
        return tf.textWidth + 8;
    }

    static function _dimColor(color:Int, alpha:Float):Int
    {
        var r:Int = Std.int(((color >> 16) & 0xFF) * alpha);
        var g:Int = Std.int(((color >> 8)  & 0xFF) * alpha);
        var b:Int = Std.int(( color        & 0xFF) * alpha);
        return (r << 16) | (g << 8) | b;
    }

    static function _blendColor(a:Int, b:Int, t:Float):Int
    {
        var ar:Int = (a >> 16) & 0xFF; var br:Int = (b >> 16) & 0xFF;
        var ag:Int = (a >> 8)  & 0xFF; var bg:Int = (b >> 8)  & 0xFF;
        var ab:Int =  a        & 0xFF; var bb:Int =  b        & 0xFF;
        var r:Int  = Std.int(ar + (br - ar) * t);
        var g:Int  = Std.int(ag + (bg - ag) * t);
        var bv:Int = Std.int(ab + (bb - ab) * t);
        return (r << 16) | (g << 8) | bv;
    }
}

enum AlertState { SLIDING_IN; COUNTING; FADING_OUT; DEAD; }

class AlertMgr extends Sprite
{
    public static var instance:AlertMgr;

    static inline var MARGIN_TOP:Float = 12;
    static inline var GAP:Float        = 8;

    var _pool:Array<AlertMessage>   = [];
    var _active:Array<AlertMessage> = [];

    public function new()
    {
        super();
        instance = this;
        if (stage != null) _init();
        else addEventListener(Event.ADDED_TO_STAGE, _init);
    }

    function _init(?_:Event)
    {
        removeEventListener(Event.ADDED_TO_STAGE, _init);
    }

    public function _spawn(title:String, ?message:String, duration:Float,
                           color:Int, ?onClick:Void->Void)
    {
        var msg:AlertMessage = _pool.length > 0 ? _pool.pop() : new AlertMessage();
        msg.setup(title, message, duration, color, onClick);
        msg.x = (Lib.application.window.width - msg.totalW) / 2;
        msg.y = -(msg.totalH + 10);
        addChild(msg);
        _active.push(msg);
        _relayout();
    }

    public function _recycle(msg:AlertMessage)
    {
        _active.remove(msg);
        _pool.push(msg);
        _relayout();
    }

    function _relayout()
    {
        var s:Float = Lib.application.window.width / 1280;
        var curY:Float = MARGIN_TOP * s;
        for (msg in _active)
        {
            msg.setTargetY(curY);
            curY += msg.totalH + (GAP * s);
        }
    }

    override function __enterFrame(deltaTime:Int)
    {
        super.__enterFrame(deltaTime);
        var winW:Float = Lib.application.window.width;
        for (msg in _active)
            msg.x = (winW - msg.totalW) / 2;
    }
}

class AlertMsg
{
    public static inline var COLOR_INFO:Int    = 0xFF4FC3F7;
    public static inline var COLOR_SUCCESS:Int = 0xFF69F0AE;
    public static inline var COLOR_WARNING:Int = 0xFFFFD740;
    public static inline var COLOR_ERROR:Int   = 0xFFFF5252;

    public static function show(title:String, ?message:String,
                                duration:Float = 5,
                                color:Int = 0xFF4FC3F7,
                                ?onClick:Void->Void):Void
    {
        if (AlertMgr.instance == null) return;
        AlertMgr.instance._spawn(title, message, duration, color, onClick);
    }
}