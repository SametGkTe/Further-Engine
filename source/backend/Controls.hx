package backend;

import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.mappings.FlxGamepadMapping;
import flixel.input.keyboard.FlxKey;

class Controls
{
	//Keeping same use cases on stuff for it to be easier to understand/use
	//I'd have removed it but this makes it a lot less annoying to use in my opinion

	//You do NOT have to create these variables/getters for adding new keys,
	//but you will instead have to use:
	//   controls.justPressed("ui_up")   instead of   controls.UI_UP

	//Dumb but easily usable code, or Smart but complicated? Your choice.
	//Also idk how to use macros they're weird as fuck lol

	// Pressed buttons (directions)
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;
	private function get_UI_UP_P() return justPressed('ui_up');
	private function get_UI_DOWN_P() return justPressed('ui_down');
	private function get_UI_LEFT_P() return justPressed('ui_left');
	private function get_UI_RIGHT_P() return justPressed('ui_right');
	private function get_NOTE_UP_P() return justPressed('note_up');
	private function get_NOTE_DOWN_P() return justPressed('note_down');
	private function get_NOTE_LEFT_P() return justPressed('note_left');
	private function get_NOTE_RIGHT_P() return justPressed('note_right');

	// Held buttons (directions)
	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;
	private function get_UI_UP() return pressed('ui_up');
	private function get_UI_DOWN() return pressed('ui_down');
	private function get_UI_LEFT() return pressed('ui_left');
	private function get_UI_RIGHT() return pressed('ui_right');
	private function get_NOTE_UP() return pressed('note_up');
	private function get_NOTE_DOWN() return pressed('note_down');
	private function get_NOTE_LEFT() return pressed('note_left');
	private function get_NOTE_RIGHT() return pressed('note_right');

	// Released buttons (directions)
	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;
	private function get_UI_UP_R() return justReleased('ui_up');
	private function get_UI_DOWN_R() return justReleased('ui_down');
	private function get_UI_LEFT_R() return justReleased('ui_left');
	private function get_UI_RIGHT_R() return justReleased('ui_right');
	private function get_NOTE_UP_R() return justReleased('note_up');
	private function get_NOTE_DOWN_R() return justReleased('note_down');
	private function get_NOTE_LEFT_R() return justReleased('note_left');
	private function get_NOTE_RIGHT_R() return justReleased('note_right');


	// Pressed buttons (others)
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;
	private function get_ACCEPT() return justPressed('accept');
	private function get_BACK() return justPressed('back');
	private function get_PAUSE() return justPressed('pause');
	private function get_RESET() return justPressed('reset');

	//Gamepad, Keyboard & Mobile stuff
	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;
	public var mobileBinds:Map<String, Array<MobileInputID>>;
	public function justPressed(key:String)
	{
		var result:Bool = (FlxG.keys.anyJustPressed(keyboardBinds[key]) == true);
		if(result) controllerMode = false;

		return result
			|| _myGamepadJustPressed(gamepadBinds[key]) == true
			|| mobileCJustPressed(mobileBinds[key]) == true
			|| touchPadJustPressed(mobileBinds[key]) == true;
	}

	public function pressed(key:String)
	{
		var result:Bool = (FlxG.keys.anyPressed(keyboardBinds[key]) == true);
		if(result) controllerMode = false;

		return result
			|| _myGamepadPressed(gamepadBinds[key]) == true
			|| mobileCPressed(mobileBinds[key]) == true
			|| touchPadPressed(mobileBinds[key]) == true;
	}

	public function justReleased(key:String)
	{
		var result:Bool = (FlxG.keys.anyJustReleased(keyboardBinds[key]) == true);
		if(result) controllerMode = false;

		return result
			|| _myGamepadJustReleased(gamepadBinds[key]) == true
			|| mobileCJustReleased(mobileBinds[key]) == true
			|| touchPadJustReleased(mobileBinds[key]) == true;
	}

	public var controllerMode:Bool = false;
	private function _myGamepadJustPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if(keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyJustPressed(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}
	private function _myGamepadPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if(keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyPressed(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}
	private function _myGamepadJustReleased(keys:Array<FlxGamepadInputID>):Bool
	{
		if(keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyJustReleased(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	public var isInSubstate:Bool = false; // don't worry about this it becomes true and false on it's own in MusicBeatSubstate
	public var requestedInstance(get, default):Dynamic; // is set to MusicBeatState or MusicBeatSubstate when the constructor is called
	public var requestedMobileC(get, default):IMobileControls; // for PlayState and EditorPlayState (hitbox and touchPad)
	public var mobileC(get, never):Bool;
	
	private function touchPadPressed(keys:Array<MobileInputID>):Bool
	{
		return touchPadCheckState(keys, "pressed");
	}

	private function touchPadJustPressed(keys:Array<MobileInputID>):Bool
	{
		return touchPadCheckState(keys, "justPressed");
	}

	private function touchPadJustReleased(keys:Array<MobileInputID>):Bool
	{
		return touchPadCheckState(keys, "justReleased");
	}

	private function touchPadReleased(keys:Array<MobileInputID>):Bool
	{
		return touchPadCheckState(keys, "released");
	}

	private function touchPadCheckState(keys:Array<MobileInputID>, state:String):Bool
	{
		if (keys == null || requestedInstance == null || requestedInstance.touchPad == null)
			return false;

		var tp:Dynamic = requestedInstance.touchPad;
		var members:Dynamic = Reflect.field(tp, "members");
		if (members == null)
			return false;

		var wantedStrings:Array<String> = convertMobileKeys(keys);
		var membersArray:Array<Dynamic> = cast members;

		for (member in membersArray)
		{
			if (member == null)
				continue;

			var ids:Dynamic = Reflect.field(member, "IDs");
			if (ids == null)
				continue;

			if (!matchesAnyKey(ids, keys, wantedStrings))
				continue;

			var val:Dynamic = Reflect.field(member, state);
			if (val == true)
				return true;
		}

		return false;
	}

	private function matchesAnyKey(ids:Dynamic, keys:Array<MobileInputID>, wantedStrings:Array<String>):Bool
	{
		if (ids == null)
			return false;

		var idArray:Array<Dynamic> = cast ids;

		for (id in idArray)
		{
			var idStr:String = Std.string(id).toUpperCase();

			for (key in keys)
			{
				if (id == key)
					return true;
			}

			for (wanted in wantedStrings)
			{
				if (idStr == wanted.toUpperCase())
					return true;
			}
		}

		return false;
	}

	private function convertMobileKeys(keys:Array<MobileInputID>):Array<String>
	{
		var out:Array<String> = [];
		if (keys == null) return out;

		for (key in keys)
		{
			switch (key)
			{
				case LEFT: out.push("LEFT");
				case RIGHT: out.push("RIGHT");
				case UP: out.push("UP");
				case DOWN: out.push("DOWN");

				case NOTE_LEFT: out.push("NOTE_LEFT");
				case NOTE_RIGHT: out.push("NOTE_RIGHT");
				case NOTE_UP: out.push("NOTE_UP");
				case NOTE_DOWN: out.push("NOTE_DOWN");

				case LEFT2: out.push("LEFT2");
				case RIGHT2: out.push("RIGHT2");
				case UP2: out.push("UP2");
				case DOWN2: out.push("DOWN2");

				case A: out.push("A");
				case B: out.push("B");
				case C: out.push("C");
				case D: out.push("D");
				case E: out.push("E");
				case F: out.push("F");
				case G: out.push("G");
				case H: out.push("H");
				case I: out.push("I");
				case J: out.push("J");
				case K: out.push("K");
				case L: out.push("L");
				case M: out.push("M");
				case N: out.push("N");
				case O: out.push("O");
				case P: out.push("P");
				case Q: out.push("Q");
				case R: out.push("R");
				case S: out.push("S");
				case T: out.push("T");
				case U: out.push("U");
				case V: out.push("V");
				case W: out.push("W");
				case X: out.push("X");
				case Y: out.push("Y");
				case Z: out.push("Z");

				case EXTRA_1: out.push("EXTRA_1");
				case EXTRA_2: out.push("EXTRA_2");

				case HITBOX_LEFT: out.push("HITBOX_LEFT");
				case HITBOX_RIGHT: out.push("HITBOX_RIGHT");
				case HITBOX_UP: out.push("HITBOX_UP");
				case HITBOX_DOWN: out.push("HITBOX_DOWN");

				case NONE: out.push("NONE");
				case ANY: out.push("ANY");

				default:
					out.push(Std.string(key));
			}
		}

		return out;
	}
	

	private function mobileCPressed(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedMobileC != null)
			if (requestedMobileC.instance.anyPressed(keys))
				return true;

		return false;
	}

	private function mobileCJustPressed(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedMobileC != null)
			if (requestedMobileC.instance.anyJustPressed(keys))
				return true;

		return false;
	}

	private function mobileCJustReleased(keys:Array<MobileInputID>):Bool
	{
		if (keys != null && requestedMobileC != null)
			if (requestedMobileC.instance.anyJustReleased(keys))
				return true;

		return false;
	}

	@:noCompletion
	private function get_requestedInstance():Dynamic
	{
		if (isInSubstate)
			return MusicBeatSubstate.instance;
		else
			return MusicBeatState.getState();
	}

	@:noCompletion
	private function get_requestedMobileC():IMobileControls
	{
		return requestedInstance.mobileControls;
	}

	@:noCompletion
	private function get_mobileC():Bool
	{
		if (ClientPrefs.data.controlsAlpha >= 0.1)
			return true;
		else
			return false;
	}
	

	// IGNORE THESE/ karim: no.
	public static var instance:Controls;
	public function new()
	{
		keyboardBinds = ClientPrefs.keyBinds;
		gamepadBinds = ClientPrefs.gamepadBinds;
		mobileBinds = ClientPrefs.mobileBinds;
	}
}
