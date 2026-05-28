package mobile.objects;

import flixel.util.FlxDestroyUtil;
import mobile.backend.MobileData;
import mobile.backend.MobileData.ExtraActions;
import backend.ClientPrefs;

class PSliceTouchControls extends BaseMobileControls
{
	public var hitbox:PSliceHitbox = null;

	public function new(?forceType:Int, ?extra:Bool = true)
	{
		super();

		var extraAction:ExtraActions = MobileData.extraActions.get(ClientPrefs.data.extraButtons);
		if (!extra || extraAction == null)
			extraAction = ExtraActions.NONE;

		hitbox = new PSliceHitbox(extraAction, MobileData.getButtonsColors());
		add(hitbox);
		bindControl(hitbox);
	}

	override public function destroy():Void
	{
		super.destroy();

		if (hitbox != null)
		{
			hitbox = FlxDestroyUtil.destroy(hitbox);
			hitbox = null;
		}

		clearBindings();
	}
}