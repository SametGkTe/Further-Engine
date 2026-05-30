package mobile.objects;

import mobile.MobilePad;
import mobile.MobileConfig;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.FlxG;
import mobile.input.MobileInputID;

class FunkinMobilePad extends MobilePad
{
	private var _activeTouches:Map<Int, MobileButton> = new Map();
	public var globalAlpha:Float = 0.7;


	public var buttonLeft:Dynamic;
	public var buttonUp:Dynamic;
	public var buttonRight:Dynamic;
	public var buttonDown:Dynamic;

	public var buttonLeft2:Dynamic;
	public var buttonUp2:Dynamic;
	public var buttonRight2:Dynamic;
	public var buttonDown2:Dynamic;

	public var buttonA:Dynamic;
	public var buttonB:Dynamic;
	public var buttonC:Dynamic;
	public var buttonD:Dynamic;
	public var buttonE:Dynamic;
	public var buttonF:Dynamic;
	public var buttonG:Dynamic;
	public var buttonH:Dynamic;
	public var buttonI:Dynamic;
	public var buttonJ:Dynamic;
	public var buttonK:Dynamic;
	public var buttonL:Dynamic;
	public var buttonM:Dynamic;
	public var buttonN:Dynamic;
	public var buttonO:Dynamic;
	public var buttonP:Dynamic;
	public var buttonQ:Dynamic;
	public var buttonR:Dynamic;
	public var buttonS:Dynamic;
	public var buttonT:Dynamic;
	public var buttonU:Dynamic;
	public var buttonV:Dynamic;
	public var buttonW:Dynamic;
	public var buttonX:Dynamic;
	public var buttonY:Dynamic;
	public var buttonZ:Dynamic;

	public var buttonExtra:Dynamic;
	public var buttonExtra2:Dynamic;

	override public function createVirtualButton(x:Float, y:Float, framePath:String, ?scale:Float = 1.0, ?ColorS:Int = 0xFFFFFF, ?returned:String):MobileButton
	{
		var frames:FlxGraphic;
		final path:String = MobileConfig.mobileFolderPath + 'MobilePad/Textures/$framePath.png';

		if (Assets.exists(path))
			frames = FlxGraphic.fromBitmapData(Assets.getBitmapData(path));
		else
			frames = FlxGraphic.fromBitmapData(Assets.getBitmapData(MobileConfig.mobileFolderPath + 'MobilePad/Textures/default.png'));

		var button = new MobileButton(x, y, returned);
		button.scale.set(scale, scale);
		button.frames = FlxTileFrames.fromGraphic(frames, FlxPoint.get(Std.int(frames.width / 2), frames.height));

		button.updateHitbox();
		button.updateLabelPosition();

		button.bounds.makeGraphic(Std.int(button.width - 50), Std.int(button.height - 50), FlxColor.TRANSPARENT);
		button.centerBounds();

		button.immovable = true;
		button.solid = button.moves = false;
		button.antialiasing = ClientPrefs.data.antialiasing;
		button.tag = framePath.toUpperCase();

		if (ColorS != -1)
			button.color = ColorS;

		return button;
	}

	public function new(DPad:String, Action:String, globalAlpha:Float = 0.7)
	{
		super(DPad, Action, true);
		this.globalAlpha = globalAlpha;
		alpha = globalAlpha;
		instance = this;

		refreshCompatButtons();
		wireCompatCallbacks();
	}

	private static var _dummyButton:TouchButton = null;

	private function getDummyButton():TouchButton
	{
		if (_dummyButton == null)
		{
			_dummyButton = new TouchButton(-9999, -9999);
			_dummyButton.visible = false;
			_dummyButton.active = false;
			_dummyButton.alpha = 0;
		}
		return _dummyButton;
	}

	private function safeGetButton(name:String):Dynamic
	{
		try
		{
			var btn = getButton(name);
			if (btn != null)
				return btn;
		}
		catch (e:Dynamic) {}

		return getDummyButton();
	}

	private function refreshCompatButtons():Void
	{
		buttonLeft = safeGetButton("buttonLeft");
		buttonUp = safeGetButton("buttonUp");
		buttonRight = safeGetButton("buttonRight");
		buttonDown = safeGetButton("buttonDown");

		buttonLeft2 = safeGetButton("buttonLeft2");
		buttonUp2 = safeGetButton("buttonUp2");
		buttonRight2 = safeGetButton("buttonRight2");
		buttonDown2 = safeGetButton("buttonDown2");

		buttonA = safeGetButton("buttonA");
		buttonB = safeGetButton("buttonB");
		buttonC = safeGetButton("buttonC");
		buttonD = safeGetButton("buttonD");
		buttonE = safeGetButton("buttonE");
		buttonF = safeGetButton("buttonF");
		buttonG = safeGetButton("buttonG");
		buttonH = safeGetButton("buttonH");
		buttonI = safeGetButton("buttonI");
		buttonJ = safeGetButton("buttonJ");
		buttonK = safeGetButton("buttonK");
		buttonL = safeGetButton("buttonL");
		buttonM = safeGetButton("buttonM");
		buttonN = safeGetButton("buttonN");
		buttonO = safeGetButton("buttonO");
		buttonP = safeGetButton("buttonP");
		buttonQ = safeGetButton("buttonQ");
		buttonR = safeGetButton("buttonR");
		buttonS = safeGetButton("buttonS");
		buttonT = safeGetButton("buttonT");
		buttonU = safeGetButton("buttonU");
		buttonV = safeGetButton("buttonV");
		buttonW = safeGetButton("buttonW");
		buttonX = safeGetButton("buttonX");
		buttonY = safeGetButton("buttonY");
		buttonZ = safeGetButton("buttonZ");

		buttonExtra = safeGetButton("buttonExtra");
		buttonExtra2 = safeGetButton("buttonExtra2");
	}

	private function wireCompatCallbacks():Void
	{
		for (member in members)
		{
			if (member == null) continue;

			var btn:Dynamic = member;

			try
			{
				var downEvent:Dynamic = Reflect.field(btn, "onDown");
				if (downEvent != null)
				{
					var prevDown:Void->Void = Reflect.field(downEvent, "callback");
					Reflect.setField(downEvent, "callback", function()
					{
						if (prevDown != null) prevDown();

						var ids:Array<String> = [];
						var uniqueID:Int = -1;

						try
						{
							var foundIDs:Dynamic = Reflect.field(btn, "IDs");
							if (foundIDs != null) ids = cast foundIDs;
						}
						catch (e:Dynamic) {}

						try
						{
							var foundUnique:Dynamic = Reflect.field(btn, "uniqueID");
							if (foundUnique != null) uniqueID = Std.int(foundUnique);
						}
						catch (e:Dynamic) {}

						onButtonDown.dispatch(btn, ids, uniqueID);
					});
				}
			}
			catch (e:Dynamic) {}

			try
			{
				var upEvent:Dynamic = Reflect.field(btn, "onUp");
				if (upEvent != null)
				{
					var prevUp:Void->Void = Reflect.field(upEvent, "callback");
					Reflect.setField(upEvent, "callback", function()
					{
						if (prevUp != null) prevUp();

						var ids:Array<String> = [];
						var uniqueID:Int = -1;

						try
						{
							var foundIDs:Dynamic = Reflect.field(btn, "IDs");
							if (foundIDs != null) ids = cast foundIDs;
						}
						catch (e:Dynamic) {}

						try
						{
							var foundUnique:Dynamic = Reflect.field(btn, "uniqueID");
							if (foundUnique != null) uniqueID = Std.int(foundUnique);
						}
						catch (e:Dynamic) {}

						onButtonUp.dispatch(btn, ids, uniqueID);
					});
				}
			}
			catch (e:Dynamic) {}
		}
	}

	public function buttonPressed(button:MobileInputID):Bool
	{
		return anyPressed([button]);
	}

	public function buttonJustPressed(button:MobileInputID):Bool
	{
		return anyJustPressed([button]);
	}

	public function buttonJustReleased(button:MobileInputID):Bool
	{
		return anyJustReleased([button]);
	}

	public function buttonReleased(button:MobileInputID):Bool
	{
		return anyReleased([button]);
	}

	public function anyPressed(buttons:Array<MobileInputID>):Bool
	{
		return checkButtonState(buttons, "pressed");
	}

	public function anyJustPressed(buttons:Array<MobileInputID>):Bool
	{
		return checkButtonState(buttons, "justPressed");
	}

	public function anyJustReleased(buttons:Array<MobileInputID>):Bool
	{
		return checkButtonState(buttons, "justReleased");
	}

	public function anyReleased(buttons:Array<MobileInputID>):Bool
	{
		return checkButtonState(buttons, "released");
	}

	private function checkButtonState(buttons:Array<MobileInputID>, state:String):Bool
	{
		if (buttons == null)
			return false;

		var wantedStrings:Array<String> = convertMobileKeys(buttons);

		for (member in members)
		{
			if (member == null)
				continue;

			var btn:Dynamic = member;
			var ids:Dynamic = Reflect.field(btn, "IDs");
			if (ids == null)
				continue;

			if (!matchesAnyKey(ids, buttons, wantedStrings))
				continue;

			var value:Dynamic = Reflect.field(btn, state);
			if (value == true)
				return true;
		}

		return false;
	}

	private function matchesAnyKey(ids:Dynamic, buttons:Array<MobileInputID>, wantedStrings:Array<String>):Bool
	{
		var idArray:Array<Dynamic> = cast ids;

		for (id in idArray)
		{
			for (button in buttons)
			{
				if (id == button)
					return true;
			}

			var idStr:String = Std.string(id).toUpperCase();
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

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (touch in FlxG.touches.list)
		{
			var currentOverlappedButton:MobileButton = null;

			for (member in members)
			{
				if (member != null && member is MobileButton)
				{
					var btn:MobileButton = cast member;
					if (touch.overlaps(btn))
					{
						currentOverlappedButton = btn;
						break;
					}
				}
			}

			var lastButtonForTouch = _activeTouches.get(touch.touchPointID);

			if (touch.justPressed)
			{
				if (currentOverlappedButton != null)
				{
					currentOverlappedButton.onDown.callback();
					_activeTouches.set(touch.touchPointID, currentOverlappedButton);
				}
			}
			else if (touch.pressed)
			{
				if (currentOverlappedButton != lastButtonForTouch)
				{
					if (lastButtonForTouch != null)
						lastButtonForTouch.onUp.callback();

					if (currentOverlappedButton != null)
						currentOverlappedButton.onDown.callback();

					_activeTouches.set(touch.touchPointID, currentOverlappedButton);
				}
			}
			else if (touch.justReleased)
			{
				if (lastButtonForTouch != null)
					lastButtonForTouch.onUp.callback();

				_activeTouches.remove(touch.touchPointID);
			}
		}
	}

	override function destroy():Void
	{
		if (onButtonDown != null) onButtonDown.destroy();
		if (onButtonUp != null) onButtonUp.destroy();
		super.destroy();
	}
}