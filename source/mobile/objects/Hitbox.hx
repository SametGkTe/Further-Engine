package mobile.objects;

import mobile.flixel.controls.MobileControls as OnlineMobileControls;
import mobile.input.MobileInputID;

class Hitbox extends OnlineMobileControls implements IMobileControls {
	public var instance:OnlineMobileControls;

	public var buttonLeft:VirtualButton;
	public var buttonUp:VirtualButton;
	public var buttonRight:VirtualButton;
	public var buttonDown:VirtualButton;

	public function new(?Extra:Dynamic) {
		super();
		instance = this;

		buttonLeft   = new VirtualButton(MobileInputID.HITBOX_LEFT,  this);
		buttonUp     = new VirtualButton(MobileInputID.HITBOX_UP,    this);
		buttonRight  = new VirtualButton(MobileInputID.HITBOX_RIGHT, this);
		buttonDown   = new VirtualButton(MobileInputID.HITBOX_DOWN,  this);
		buttonExtra  = new VirtualButton(MobileInputID.EXTRA_1,      this);
		buttonExtra2 = new VirtualButton(MobileInputID.EXTRA_2,      this);

		addHitbox("DEFAULT");

		if (Extra == 1)
			addButton("EXTRA_1");
		else if (Extra == 2)
			addButton("EXTRA_1_2");
	}

	override public function anyPressed(keys:Array<MobileInputID>):Bool {
		for (key in keys) if (checkState(key.toString(), "pressed")) return true;
		return false;
	}

	override public function anyJustPressed(keys:Array<MobileInputID>):Bool {
		for (key in keys) if (checkState(key.toString(), "justpressed")) return true;
		return false;
	}

	override public function anyJustReleased(keys:Array<MobileInputID>):Bool {
		for (key in keys) if (checkState(key.toString(), "justreleased")) return true;
		return false;
	}

	override public function anyReleased(keys:Array<MobileInputID>):Bool {
		for (key in keys) if (checkState(key.toString(), "released")) return true;
		return false;
	}

	override public inline function buttonPressed(id:MobileInputID):Bool {
		return checkState(id.toString(), "pressed");
	}

	override public inline function buttonJustPressed(id:MobileInputID):Bool {
		return checkState(id.toString(), "justpressed");
	}

	override public inline function buttonJustReleased(id:MobileInputID):Bool {
		return checkState(id.toString(), "justreleased");
	}
}