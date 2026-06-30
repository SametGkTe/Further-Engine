package mobile.objects;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxDestroyUtil;
import backend.ClientPrefs;
import mobile.backend.MobileData;

class MobileControls extends FlxSpriteGroup
{
	public var touchPad:TouchPad;
	public var hitbox:Hitbox;

	public function new(?forceType:Int, ?extra:Bool = true)
	{
		super();
		MobileData.forcedMode = forceType;
		initController(MobileData.mode, extra);
		alpha = ClientPrefs.data.controlsAlpha;
	}

	private function initController(controlMode:Int = 0, ?extra:Bool = true):Void
	{
		var extraAction:Dynamic = MobileData.extraActions.get(ClientPrefs.data.extraButtons);
		if (!extra) extraAction = 0;

		switch (controlMode)
		{
			case 0:
				touchPad = new TouchPad("RIGHT_FULL", "NONE", extraAction);
				touchPad = MobileData.setButtonsColors(touchPad);
				add(touchPad);

			case 1:
				touchPad = new TouchPad("LEFT_FULL", "NONE", extraAction);
				touchPad = MobileData.setButtonsColors(touchPad);
				add(touchPad);

			case 2:
				touchPad = MobileData.getTouchPadCustom(new TouchPad("RIGHT_FULL", "NONE", extraAction));
				touchPad = MobileData.setButtonsColors(touchPad);
				add(touchPad);

			case 3:
				hitbox = new Hitbox(extraAction);
				hitbox = MobileData.setButtonsColors(hitbox);
				add(hitbox);
		}
	}

	override public function destroy():Void
	{
		super.destroy();

		if (touchPad != null)
		{
			touchPad = FlxDestroyUtil.destroy(touchPad);
			touchPad = null;
		}

		if (hitbox != null)
		{
			hitbox = FlxDestroyUtil.destroy(hitbox);
			hitbox = null;
		}

		MobileData.forcedMode = null;
	}
}