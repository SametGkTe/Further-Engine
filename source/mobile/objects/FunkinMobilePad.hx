package mobile.objects;

import mobile.MobilePad;
import mobile.MobileConfig;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.FlxG;

class FunkinMobilePad extends MobilePad
{
	private var _activeTouches:Map<Int, MobileButton> = new Map();
	public var globalAlpha:Float = 0.7;

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
}