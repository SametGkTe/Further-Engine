package backend;

import flixel.FlxG;
import openfl.Lib;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

#if lime
import lime.app.Application;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
#end

class IOSKeyboardFix
{
	public static var enabled(default, null):Bool = false;

	static var frameID:Int = 0;
	static var held:Map<String, Bool> = new Map();
	static var pressFrame:Map<String, Int> = new Map();
	static var releaseFrame:Map<String, Int> = new Map();

	public static function init():Void
	{
		#if ios
		if (enabled) return;
		enabled = true;

		if (Lib.current != null && Lib.current.stage != null)
		{
			Lib.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			Lib.current.stage.addEventListener(Event.ACTIVATE, onActivate);
			Lib.current.stage.addEventListener(Event.DEACTIVATE, onDeactivate);
			Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onStageKeyDown);
			Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onStageKeyUp);
		}

		#if lime
		if (Application.current != null && Application.current.window != null)
		{
			Application.current.window.onKeyDown.add(onWindowKeyDown);
			Application.current.window.onKeyUp.add(onWindowKeyUp);
		}
		#end
		#end
	}

	static function onEnterFrame(_):Void
	{
		frameID++;
	}

	static inline function isHeld(name:String):Bool
	{
		return held.exists(name) && held.get(name);
	}

	static function setDown(name:String):Void
	{
		if (!isHeld(name))
			pressFrame.set(name, frameID + 1);

		held.set(name, true);
	}

	static function setUp(name:String):Void
	{
		held.set(name, false);
		releaseFrame.set(name, frameID + 1);
	}

	public static inline function pressed(name:String):Bool
	{
		return isHeld(name);
	}

	public static inline function justPressed(name:String):Bool
	{
		return pressFrame.exists(name) && pressFrame.get(name) == frameID;
	}

	public static inline function justReleased(name:String):Bool
	{
		return releaseFrame.exists(name) && releaseFrame.get(name) == frameID;
	}

	static function clearHeld():Void
	{
		held = new Map();
	}

	static function onActivate(_):Void
	{
		try {
			if (Lib.current != null && Lib.current.stage != null && FlxG.game != null)
				Lib.current.stage.focus = cast FlxG.game;
		} catch (e:Dynamic) {}
	}

	static function onDeactivate(_):Void
	{
		clearHeld();
	}

	static function onStageKeyDown(e:KeyboardEvent):Void
	{
		normalizeOpenFLDown(e.keyCode, e.charCode);
	}

	static function onStageKeyUp(e:KeyboardEvent):Void
	{
		normalizeOpenFLUp(e.keyCode, e.charCode);
	}

	static function normalizeOpenFLDown(keyCode:Int, charCode:Int):Void
	{
		switch (keyCode)
		{
			case Keyboard.ENTER, 10:
				setDown("accept");

			case Keyboard.BACKSPACE, Keyboard.DELETE, Keyboard.ESCAPE, 27, 127:
				setDown("back");

			case Keyboard.LEFT, 63234:
				setDown("left");

			case Keyboard.UP, 63232:
				setDown("up");

			case Keyboard.RIGHT, 63235:
				setDown("right");

			case Keyboard.DOWN, 63233:
				setDown("down");

			case Keyboard.SPACE:
				setDown("space");
		}

		if (charCode > 0)
		{
			var c = String.fromCharCode(charCode).toLowerCase();
			switch (c)
			{
				case "a": setDown("a");
				case "s": setDown("s");
				case "w": setDown("w");
				case "d": setDown("d");
			}
		}
	}

	static function normalizeOpenFLUp(keyCode:Int, charCode:Int):Void
	{
		switch (keyCode)
		{
			case Keyboard.ENTER, 10:
				setUp("accept");

			case Keyboard.BACKSPACE, Keyboard.DELETE, Keyboard.ESCAPE, 27, 127:
				setUp("back");

			case Keyboard.LEFT, 63234:
				setUp("left");

			case Keyboard.UP, 63232:
				setUp("up");

			case Keyboard.RIGHT, 63235:
				setUp("right");

			case Keyboard.DOWN, 63233:
				setUp("down");

			case Keyboard.SPACE:
				setUp("space");
		}

		if (charCode > 0)
		{
			var c = String.fromCharCode(charCode).toLowerCase();
			switch (c)
			{
				case "a": setUp("a");
				case "s": setUp("s");
				case "w": setUp("w");
				case "d": setUp("d");
			}
		}
	}

	#if lime
	static function onWindowKeyDown(key:KeyCode, mod:KeyModifier):Void
	{
		switch (key)
		{
			case RETURN, NUMPAD_ENTER:
				setDown("accept");

			case BACKSPACE, ESCAPE, DELETE:
				setDown("back");

			case LEFT:
				setDown("left");

			case UP:
				setDown("up");

			case RIGHT:
				setDown("right");

			case DOWN:
				setDown("down");

			case SPACE:
				setDown("space");

			case A:
				setDown("a");

			case S:
				setDown("s");

			case W:
				setDown("w");

			case D:
				setDown("d");

			default:
		}
	}

	static function onWindowKeyUp(key:KeyCode, mod:KeyModifier):Void
	{
		switch (key)
		{
			case RETURN, NUMPAD_ENTER:
				setUp("accept");

			case BACKSPACE, ESCAPE, DELETE:
				setUp("back");

			case LEFT:
				setUp("left");

			case UP:
				setUp("up");

			case RIGHT:
				setUp("right");

			case DOWN:
				setUp("down");

			case SPACE:
				setUp("space");

			case A:
				setUp("a");

			case S:
				setUp("s");

			case W:
				setUp("w");

			case D:
				setUp("d");

			default:
		}
	}
	#end
}