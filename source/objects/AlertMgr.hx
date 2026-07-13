package objects;

import openfl.Lib;
import openfl.Assets;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
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
    static inline var MAX_ACTION_CONTENT_W:Float = 760;
    static inline var CORNER:Float        = 6;
    static inline var BAR_H:Float         = 4;
    static inline var SLIDE_DURATION:Float = 0.38;
    static inline var FADE_DURATION:Float  = 0.28;
    static inline var ACTION_H:Float      = 44;
    static inline var ACTION_GAP:Float    = 10;

    var _bg:Shape;
    var _accentBar:Shape;
    var _timerBar:Shape;
    var _counterBg:Shape;
    var _counterField:TextField;
    var _titleField:TextField;
    var _contentField:TextField;

    var _fullHit:Sprite;

    var _primaryButton:Sprite;
    var _secondaryButton:Sprite;
    var _primaryButtonField:TextField;
    var _secondaryButtonField:TextField;

    var _primaryAction:Null<Void->Void>;
    var _secondaryAction:Null<Void->Void>;

    var _primaryLabelBase:String;
    var _secondaryLabelBase:String;

    var _autoTriggerPrimary:Bool = false;
    var _useActionButtons:Bool   = false;

    var _primaryBtnW:Float = 0;
    var _primaryBtnH:Float = 0;

    var _accentColor:Int;
    var _totalTime:Float;
    var _elapsed:Float        = 0;
    var _state:AlertState     = SLIDING_IN;
    var _slideProgress:Float  = 0;
    var _targetY:Float        = 0;
    var _currentY:Float       = 0;
    var _onYChanged:Float->Void;
    var _onClick:Null<Void->Void>;
    var _isDead:Bool          = false;

    public var totalW:Float = 0;
    public var totalH:Float = 0;

    public function new() { super(); }

    public function setup(titleText:String, ?messageText:String, duration:Float = 5,
                          accentColor:Int = 0xFF4FC3F7, ?onClick:Void->Void,
                          ?primaryText:String, ?onPrimary:Void->Void,
                          ?secondaryText:String, ?onSecondary:Void->Void,
                          autoTriggerPrimary:Bool = false):AlertMessage
    {
        _removeInputListeners();
        hitArea = null;

        while (numChildren > 0) removeChildAt(0);

        _fullHit = null;
        _primaryButton = null;
        _secondaryButton = null;
        _primaryButtonField = null;
        _secondaryButtonField = null;

        var s:Float = getScale();

        _accentColor       = accentColor;
        _totalTime         = Math.max(1, duration);
        _elapsed           = 0;
        _state             = SLIDING_IN;
        _slideProgress     = 0;
        _isDead            = false;
        _primaryAction     = onPrimary;
        _secondaryAction   = onSecondary;
        _primaryLabelBase  = primaryText;
        _secondaryLabelBase = secondaryText;
        _autoTriggerPrimary = autoTriggerPrimary;
        _useActionButtons  = _hasText(primaryText) || _hasText(secondaryText);
        _onClick           = _useActionButtons ? null : onClick;
        alpha              = 1;

        buttonMode     = false;
        useHandCursor  = false;
        mouseChildren  = true;

        var fontName:String = Assets.getFont('assets/fonts/vcr.ttf').fontName;

        _titleField = _makeField(fontName, Std.int(20 * s), 0xFFFFFFFF, true);
        _titleField.text = titleText ?? '';

        _contentField = _makeField(fontName, Std.int(15 * s), 0xFFCCCCCC, false);
        _contentField.text = messageText ?? '';

        var hasContent:Bool = (messageText ?? '').trim().length > 0;

        var sPadding:Float = PADDING * s;
        var sBarH:Float    = BAR_H * s;
        var sMinW:Float    = MIN_CONTENT_W * s;
        var sMaxW:Float    = (_useActionButtons ? MAX_ACTION_CONTENT_W : MAX_CONTENT_W) * s;

        var rawTW:Float = _measureTextWidthLimit(_titleField, sMaxW);
        var rawCW:Float = hasContent ? _measureTextWidthLimit(_contentField, sMaxW) : 0;

        var contentW:Float = Math.min(Math.max(Math.max(rawTW, rawCW), sMinW), sMaxW);

        if (_useActionButtons)
        {
            var measurePrimary:Float = 0;
            var measureSecondary:Float = 0;

            if (_hasText(_primaryLabelBase))
            {
                var tmpP = _makeCenteredField(fontName, Std.int(12 * s), _getReadableTextColor(_accentColor), true);
                tmpP.text = _formatPrimaryLabel(Std.int(Math.ceil(_totalTime)));
                measurePrimary = _measureTextWidthLimit(tmpP, sMaxW) + (20 * s);
            }

            if (_hasText(_secondaryLabelBase))
            {
                var tmpS = _makeCenteredField(fontName, Std.int(12 * s), 0xFFEAEAEA, true);
                tmpS.text = _secondaryLabelBase;
                measureSecondary = _measureTextWidthLimit(tmpS, sMaxW) + (20 * s);
            }

            var needButtonsW:Float = measurePrimary + measureSecondary;
            if (_hasText(_primaryLabelBase) && _hasText(_secondaryLabelBase))
                needButtonsW += ACTION_GAP * s;

            contentW = Math.min(Math.max(contentW, Math.max(520 * s, needButtonsW)), sMaxW);
        }

        _titleField.width   = contentW;
        _contentField.width = contentW;

        var titleH:Float   = _titleField.textHeight + (4 * s);
        var contentH:Float = hasContent ? (_contentField.textHeight + (4 * s)) : 0;
        var actionsH:Float = _useActionButtons ? ((10 * s) + (ACTION_H * s)) : 0;

        var innerH:Float = sPadding + titleH + (hasContent ? (6 * s + contentH) : 0) + actionsH + sPadding + sBarH;

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

        var nextY:Float = sPadding + titleH;

        if (hasContent)
        {
            _contentField.x = textX;
            _contentField.y = nextY + (6 * s);
            addChild(_contentField);
            nextY = _contentField.y + contentH;
        }

        if (_useActionButtons)
            _buildActionButtons(fontName, textX, nextY + (10 * s), contentW, s);

        _timerBar = new Shape();
        _timerBar.y = totalH - sBarH;
        addChild(_timerBar);

        _updateTimerBar(1.0);
        _updatePrimaryButtonLabel();

        if (!_useActionButtons)
        {
            _fullHit = new Sprite();
            _fullHit.graphics.beginFill(0x000000, 0);
            _fullHit.graphics.drawRect(0, 0, totalW, totalH);
            _fullHit.graphics.endFill();
            addChild(_fullHit);

            hitArea = _fullHit;
            buttonMode = true;
            useHandCursor = true;

            addEventListener(MouseEvent.CLICK, _onMouseClick);
            addEventListener(MouseEvent.MOUSE_OVER, _onOver);
            addEventListener(MouseEvent.MOUSE_OUT, _onOut);
        }

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
                _updatePrimaryButtonLabel();

                if (_elapsed >= _totalTime)
                {
                    if (_useActionButtons && _autoTriggerPrimary && _hasText(_primaryLabelBase) && _primaryAction != null)
                        _primaryAction();

                    _beginFadeOut();
                }

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
        _removeInputListeners();
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

    function _onOver(_:MouseEvent) { if (_state == COUNTING) alpha = 0.92; }
    function _onOut(_:MouseEvent)  { alpha = 1.0; }

    // ── Action Buttons ──

    function _buildActionButtons(fontName:String, rowX:Float, rowY:Float, rowW:Float, s:Float):Void
    {
        var btnGap:Float = ACTION_GAP * s;
        var btnH:Float   = ACTION_H * s;

        var count:Int = 0;
        if (_hasText(_primaryLabelBase)) count++;
        if (_hasText(_secondaryLabelBase)) count++;

        if (count <= 0) return;

        var btnW:Float   = (count >= 2) ? ((rowW - btnGap) / 2) : rowW;
        var nextX:Float  = rowX;

        if (_hasText(_primaryLabelBase))
        {
            _primaryBtnW = btnW;
            _primaryBtnH = btnH;

            _primaryButton = _createActionButton(
                true,
                btnW,
                btnH,
                _accentColor,
                _getReadableTextColor(_accentColor),
                fontName,
                Std.int(12 * s),
                _formatPrimaryLabel(Std.int(Math.ceil(_totalTime)))
            );
            _primaryButton.x = nextX;
            _primaryButton.y = rowY;
            _primaryButton.addEventListener(MouseEvent.CLICK, _onPrimaryClick);
            _primaryButton.addEventListener(MouseEvent.MOUSE_OVER, _onPrimaryOver);
            _primaryButton.addEventListener(MouseEvent.MOUSE_OUT, _onPrimaryOut);
            addChild(_primaryButton);

            nextX += btnW + (count >= 2 ? btnGap : 0);
        }

        if (_hasText(_secondaryLabelBase))
        {
            _secondaryButton = _createActionButton(
                false,
                (count >= 2) ? btnW : rowW,
                btnH,
                0xFF2A3038,
                0xFFEAEAEA,
                fontName,
                Std.int(12 * s),
                _secondaryLabelBase
            );
            _secondaryButton.x = nextX;
            _secondaryButton.y = rowY;
            _secondaryButton.addEventListener(MouseEvent.CLICK, _onSecondaryClick);
            _secondaryButton.addEventListener(MouseEvent.MOUSE_OVER, _onSecondaryOver);
            _secondaryButton.addEventListener(MouseEvent.MOUSE_OUT, _onSecondaryOut);
            addChild(_secondaryButton);
        }
    }

    function _createActionButton(isPrimary:Bool, w:Float, h:Float, bgColor:Int, textColor:Int,
        fontName:String, fontSize:Int, label:String):Sprite
    {
        var spr = new Sprite();

        var bg = new Shape();
        _drawRoundRect(bg, w, h, 4 * getScale(), bgColor, 0.95);
        spr.addChild(bg);

        var tf = _makeCenteredField(fontName, fontSize, textColor, true);
        tf.width  = w - (12 * getScale());
        tf.height = h;
        tf.text   = label;
        tf.x = (w - tf.width) / 2;
        tf.y = Math.max(0, (h - (tf.textHeight + 4)) / 2 - (1 * getScale()));
        spr.addChild(tf);

        spr.buttonMode    = true;
        spr.useHandCursor = true;

        if (isPrimary)
            _primaryButtonField = tf;
        else
            _secondaryButtonField = tf;

        return spr;
    }

    function _removeInputListeners():Void
    {
        removeEventListener(MouseEvent.CLICK, _onMouseClick);
        removeEventListener(MouseEvent.MOUSE_OVER, _onOver);
        removeEventListener(MouseEvent.MOUSE_OUT, _onOut);

        if (_primaryButton != null)
        {
            _primaryButton.removeEventListener(MouseEvent.CLICK, _onPrimaryClick);
            _primaryButton.removeEventListener(MouseEvent.MOUSE_OVER, _onPrimaryOver);
            _primaryButton.removeEventListener(MouseEvent.MOUSE_OUT, _onPrimaryOut);
        }

        if (_secondaryButton != null)
        {
            _secondaryButton.removeEventListener(MouseEvent.CLICK, _onSecondaryClick);
            _secondaryButton.removeEventListener(MouseEvent.MOUSE_OVER, _onSecondaryOver);
            _secondaryButton.removeEventListener(MouseEvent.MOUSE_OUT, _onSecondaryOut);
        }
    }

    function _onPrimaryClick(e:MouseEvent):Void
    {
        e.stopImmediatePropagation();
        if (_primaryAction != null) _primaryAction();
        _beginFadeOut();
    }

    function _onSecondaryClick(e:MouseEvent):Void
    {
        e.stopImmediatePropagation();
        if (_secondaryAction != null) _secondaryAction();
        _beginFadeOut();
    }

    function _onPrimaryOver(_:MouseEvent):Void
    {
        if (_state == COUNTING && _primaryButton != null) _primaryButton.alpha = 0.92;
    }

    function _onPrimaryOut(_:MouseEvent):Void
    {
        if (_primaryButton != null) _primaryButton.alpha = 1.0;
    }

    function _onSecondaryOver(_:MouseEvent):Void
    {
        if (_state == COUNTING && _secondaryButton != null) _secondaryButton.alpha = 0.92;
    }

    function _onSecondaryOut(_:MouseEvent):Void
    {
        if (_secondaryButton != null) _secondaryButton.alpha = 1.0;
    }

    function _updatePrimaryButtonLabel():Void
    {
        if (_primaryButtonField == null || !_autoTriggerPrimary) return;

        _primaryButtonField.text = _formatPrimaryLabel(Std.int(Math.ceil(_totalTime - _elapsed)));
        _primaryButtonField.y = Math.max(0, (_primaryBtnH - (_primaryButtonField.textHeight + 4)) / 2 - (1 * getScale()));
    }

    function _formatPrimaryLabel(?remaining:Int):String
    {
        if (!_hasText(_primaryLabelBase)) return '';

        if (_autoTriggerPrimary)
        {
            var sec:Int = remaining == null ? Std.int(Math.ceil(_totalTime - _elapsed)) : remaining;
            if (sec < 0) sec = 0;
            return _primaryLabelBase + ' (' + sec + ' saniye icinde otomatik secilir)';
        }

        return _primaryLabelBase;
    }

    // ── Timer / Counter ──

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

    // ── Helpers ──

    function _makeField(font:String, size:Int, color:Int, bold:Bool):TextField
    {
        var tf = new TextField();
        tf.selectable    = false;
        tf.multiline     = true;
        tf.wordWrap      = true;
        tf.defaultTextFormat = new TextFormat(font, size, color, bold);
        tf.antiAliasType = ADVANCED;
        tf.embedFonts    = true;
        return tf;
    }

    function _makeCenteredField(font:String, size:Int, color:Int, bold:Bool):TextField
    {
        var tf = _makeField(font, size, color, bold);
        var fmt:TextFormat = tf.defaultTextFormat;
        fmt.align = TextFormatAlign.CENTER;
        tf.defaultTextFormat = fmt;
        return tf;
    }

    function _drawRoundRect(s:Shape, w:Float, h:Float, r:Float, color:Int, a:Float = 1.0)
    {
        s.graphics.clear();
        s.graphics.beginFill(color, a);
        if (r > 0)
            s.graphics.drawRoundRect(0, 0, w, h, r * 2, r * 2);
        else
            s.graphics.drawRect(0, 0, w, h);
        s.graphics.endFill();
    }

    function getScale():Float
    {
        var s:Float = Lib.application.window.width / 1280;
        return s < 1 ? 1 : s;
    }

    function _measureTextWidth(tf:TextField):Float
    {
        tf.width = MAX_CONTENT_W * getScale();
        return tf.textWidth + 8;
    }

    function _measureTextWidthLimit(tf:TextField, limit:Float):Float
    {
        tf.width = limit;
        return tf.textWidth + 8;
    }

    function _hasText(v:String):Bool
    {
        return v != null && v.trim().length > 0;
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

    static function _getReadableTextColor(color:Int):Int
    {
        var r:Float = (color >> 16) & 0xFF;
        var g:Float = (color >> 8) & 0xFF;
        var b:Float = color & 0xFF;
        var lum:Float = (0.299 * r) + (0.587 * g) + (0.114 * b);
        return lum >= 155 ? 0xFF111318 : 0xFFFFFFFF;
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
                           color:Int, ?onClick:Void->Void,
                           ?primaryText:String, ?onPrimary:Void->Void,
                           ?secondaryText:String, ?onSecondary:Void->Void,
                           autoTriggerPrimary:Bool = false)
    {
        var msg:AlertMessage = _pool.length > 0 ? _pool.pop() : new AlertMessage();
        msg.setup(title, message, duration, color, onClick, primaryText, onPrimary, secondaryText, onSecondary, autoTriggerPrimary);
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

    public static function showChoice(title:String, ?message:String,
                                      duration:Float = 5,
                                      color:Int = 0xFF4FC3F7,
                                      primaryText:String = "TAMAM",
                                      ?onPrimary:Void->Void,
                                      ?secondaryText:String,
                                      ?onSecondary:Void->Void,
                                      autoTriggerPrimary:Bool = false):Void
    {
        if (AlertMgr.instance == null) return;
        AlertMgr.instance._spawn(title, message, duration, color, null,
            primaryText, onPrimary, secondaryText, onSecondary, autoTriggerPrimary);
    }
}