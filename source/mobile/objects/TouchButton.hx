/*
 * Copyright (C) 2025 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package mobile.objects;

import flixel.input.FlxInput;
import flixel.input.FlxPointer;
import flixel.input.IFlxInput;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
#if mac
import flixel.input.mouse.FlxMouseButton;
#end

class TouchButton extends TypedTouchButton<FlxSprite>
{
	public static inline var NORMAL:Int = 0;

	public static inline var HIGHLIGHT:Int = 1;

	public static inline var PRESSED:Int = 2;

	public var tag:String;

	public var IDs:Array<MobileInputID> = [];

	public var bounds:FlxSprite = new FlxSprite();

	public function new(X:Float = 0, Y:Float = 0, ?IDs:Array<MobileInputID> = null):Void
	{
		super(X, Y);

		this.IDs = IDs == null ? [] : IDs;
	}

	public inline function centerInBounds()
	{
		setPosition(bounds.x + ((bounds.width - frameWidth) / 2), bounds.y + ((bounds.height - frameHeight) / 2));
	}

	public inline function centerBounds()
	{
		bounds.setPosition(x + ((frameWidth - bounds.width) / 2), y + ((frameHeight - bounds.height) / 2));
	}
}

#if !display
@:generic
#end
class TypedTouchButton<T:FlxSprite> extends FlxSprite implements IFlxInput
{
	public var label(default, set):T;

	public var allowSwiping:Bool = true;

	public var multiTouch:Bool = false;

	public var maxInputMovement:Float = Math.POSITIVE_INFINITY;

	public var onUp(default, null):TouchButtonEvent;

	public var onDown(default, null):TouchButtonEvent;

	public var onOver(default, null):TouchButtonEvent;

	public var onOut(default, null):TouchButtonEvent;

	public var status(default, set):Int;

	public var statusAlphas:Array<Float> = [1.0, 1.0, 0.6];

	public var statusBrightness:Array<Float> = [1.0, 0.95, 0.7];

	public var labelStatusDiff:Float = 0.05;

	public var parentAlpha(default, set):Float = 1;

	public var statusIndicatorType(default, set):StatusIndicators = ALPHA;

	public var brightShader:ButtonBrightnessShader = new ButtonBrightnessShader();

	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;
	public var pressed(get, never):Bool;
	public var justPressed(get, never):Bool;

	var _spriteLabel:FlxSprite;

	var input:FlxInput<Int>;

	var currentInput:IFlxInput;

	public var canChangeLabelAlpha:Bool = true;

	public function new(X:Float = 0, Y:Float = 0):Void
	{
		super(X, Y);

		if (statusIndicatorType == BRIGHTNESS)
			shader = brightShader;

		onUp = new TouchButtonEvent();
		onDown = new TouchButtonEvent();
		onOver = new TouchButtonEvent();
		onOut = new TouchButtonEvent();

		status = multiTouch ? TouchButton.NORMAL : TouchButton.HIGHLIGHT;

		scrollFactor.set();

		input = new FlxInput(0);
	}

	override public function destroy():Void
	{
		label = FlxDestroyUtil.destroy(label);
		_spriteLabel = null;

		onUp = FlxDestroyUtil.destroy(onUp);
		onDown = FlxDestroyUtil.destroy(onDown);
		onOver = FlxDestroyUtil.destroy(onOver);
		onOut = FlxDestroyUtil.destroy(onOut);

		currentInput = null;
		input = null;

		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (visible)
		{
			#if FLX_POINTER_INPUT
			updateButton();
			#end
		}

		input.update();
	}

	override public function draw():Void
	{
		super.draw();

		if (_spriteLabel != null && _spriteLabel.graphic != null && _spriteLabel.pixels != null && _spriteLabel.visible)
		{
			if (_spriteLabel.cameras != cameras)
				_spriteLabel.cameras = cameras;
			_spriteLabel.draw();
		}
	}

	#if FLX_DEBUG
	override public function drawDebug():Void
	{
		super.drawDebug();

		if (_spriteLabel != null)
			_spriteLabel.drawDebug();
	}
	#end

	function updateButton():Void
	{
		var overlapFound = checkTouchOverlap();

		if (currentInput != null && currentInput.justReleased && overlapFound)
			onUpHandler();

		if (status != TouchButton.NORMAL && (!overlapFound || (currentInput != null && currentInput.justReleased)))
			onOutHandler();
	}

	function checkTouchOverlap():Bool
	{
		var overlap = false;

		for (camera in cameras)
		{
			#if mac
			var button = FlxMouseButton.getByID(FlxMouseButtonID.LEFT);
			if (checkInput(FlxG.mouse, button, button.justPressedPosition, camera))
			#else
			for (touch in FlxG.touches.list)
				if (checkInput(touch, touch, touch.justPressedPosition, camera))
			#end
			overlap = true;
		}

		return overlap;
	}

	function checkInput(pointer:FlxPointer, input:IFlxInput, justPressedPosition:FlxPoint, camera:FlxCamera):Bool
	{
		if (maxInputMovement != Math.POSITIVE_INFINITY
			&& justPressedPosition.distanceTo(pointer.getScreenPosition(FlxPoint.weak())) > maxInputMovement
			&& input == currentInput)
		{
			currentInput = null;
		}
		else if (overlapsPoint(pointer.getWorldPosition(camera, _point), true, camera))
		{
			updateStatus(input);
			return true;
		}

		return false;
	}

	function updateStatus(input:IFlxInput):Void
	{
		if (input.justPressed)
		{
			currentInput = input;
			onDownHandler();
		}
		else if (status == TouchButton.NORMAL)
		{
			if (allowSwiping && input.pressed)
				onDownHandler();
			else
				onOverHandler();
		}
	}

	function updateLabelPosition()
	{
		if (_spriteLabel != null)
		{
			_spriteLabel.x = ((width - _spriteLabel.width) / 2) + (pixelPerfectPosition ? Math.floor(x) : x);
			_spriteLabel.y = ((height - _spriteLabel.height) / 2) + (pixelPerfectPosition ? Math.floor(y) : y);
		}
	}

	function updateLabelScale()
	{
		if (_spriteLabel != null)
			_spriteLabel.scale.set(scale.x, scale.y);
	}

	function indicateStatus()
	{
		switch (statusIndicatorType)
		{
			case ALPHA:
				alpha = statusAlphas[status];
			case BRIGHTNESS:
				brightShader.brightness.value = [statusBrightness[status]];
			case NONE: 
		}
	}

	function onUpHandler():Void
	{
		status = TouchButton.NORMAL;
		input.release();
		currentInput = null;
		onUp.fire(); 
	}

	function onDownHandler():Void
	{
		status = TouchButton.PRESSED;
		input.press();
		onDown.fire(); 
	}

	function onOverHandler():Void
	{
		status = TouchButton.HIGHLIGHT;
		onOver.fire(); 
	}

	function onOutHandler():Void
	{
		status = TouchButton.NORMAL;
		input.release();
		onOut.fire(); 
	}

	function set_label(Value:T):T
	{
		if (Value != null)
		{
			Value.scrollFactor.put();
			Value.scrollFactor = scrollFactor;
		}

		label = Value;
		_spriteLabel = label;

		updateLabelPosition();

		if (statusIndicatorType == BRIGHTNESS && label != null && brightShader != null)
			_spriteLabel.shader = brightShader;

		return Value;
	}

	function set_status(Value:Int):Int
	{
		status = Value;
		indicateStatus();
		return status;
	}

	override function set_alpha(Value:Float):Float
	{
		super.set_alpha(Value);
		if (_spriteLabel != null && canChangeLabelAlpha)
			_spriteLabel.alpha = alpha == 0 ? 0 : alpha + labelStatusDiff;
		return Value;
	}

	override function set_visible(Value:Bool):Bool
	{
		super.set_visible(Value);
		if (_spriteLabel != null)
			_spriteLabel.visible = Value;
		return Value;
	}

	override function set_x(Value:Float):Float
	{
		super.set_x(Value);
		updateLabelPosition();
		return x;
	}

	override function set_y(Value:Float):Float
	{
		super.set_y(Value);
		updateLabelPosition();
		return y;
	}

	override function set_color(Value:FlxColor):Int
	{
		if (_spriteLabel != null)
			_spriteLabel.color = Value;
		brightShader.color = Value;
		super.set_color(Value);
		return Value;
	}

	override private function set_width(Value:Float)
	{
		super.set_width(Value);
		updateLabelScale();
		return Value;
	}

	override private function set_height(Value:Float)
	{
		super.set_height(Value);
		updateLabelScale();
		return Value;
	}

	override public function updateHitbox()
	{
		super.updateHitbox();
		if (_spriteLabel != null)
			_spriteLabel.updateHitbox();
	}

	function set_parentAlpha(Value:Float):Float
	{
		statusAlphas = [
			Value,
			Value - 0.05,
			(parentAlpha - 0.45 == 0 && parentAlpha > 0)
			? 0.25 : parentAlpha - 0.45
		];
		indicateStatus();
		return parentAlpha = Value;
	}

	function set_statusIndicatorType(Value:StatusIndicators)
	{
		if (Value == BRIGHTNESS)
		{
			shader = brightShader;
			if (_spriteLabel != null)
				_spriteLabel.shader = brightShader;
		}
		else
		{
			shader = null;
			if (_spriteLabel != null)
				_spriteLabel.shader = null;
		}
		statusIndicatorType = Value;
		return Value;
	}

	inline function get_justReleased():Bool
		return input.justReleased;

	inline function get_released():Bool
		return input.released;

	inline function get_pressed():Bool
		return input.pressed;

	inline function get_justPressed():Bool
		return input.justPressed;
}

private class TouchButtonEvent implements IFlxDestroyable
{
	public var callback:Void->Void;

	#if FLX_SOUND_SYSTEM
	public var sound:FlxSound;
	#end

	public function new(?Callback:Void->Void, ?sound:FlxSound):Void
	{
		callback = Callback;

		#if FLX_SOUND_SYSTEM
		this.sound = sound;
		#end
	}

	public inline function destroy():Void
	{
		callback = null;

		#if FLX_SOUND_SYSTEM
		sound = FlxDestroyUtil.destroy(sound);
		#end
	}

	public inline function fire():Void
	{
		if (callback != null)
			callback();

		#if FLX_SOUND_SYSTEM
		if (sound != null)
			sound.play(true);
		#end
	}
}

class ButtonBrightnessShader extends FlxShader
{
	public var color(default, set):Null<FlxColor> = FlxColor.WHITE;

	@:glFragmentSource('
		#pragma header

		uniform float brightness;

		void main()
		{
			vec4 col = flixel_texture2D(bitmap, openfl_TextureCoordv);
			col.rgb *= brightness;

			gl_FragColor = col;
		}
	')
	public function new()
	{
		super();
	}

	private function set_color(?laColor:FlxColor)
	{
		if (laColor == null)
		{
			colorMultiplier.value = [1, 1, 1, 1];
			hasColorTransform.value = hasTransform.value = [false];
			return color = laColor;
		}
		hasColorTransform.value = hasTransform.value = [true];
		colorMultiplier.value = [laColor.redFloat, laColor.blueFloat, laColor.greenFloat, laColor.alphaFloat];
		return color = laColor;
	}
}

enum StatusIndicators
{
	ALPHA;
	BRIGHTNESS;
	NONE;
}
