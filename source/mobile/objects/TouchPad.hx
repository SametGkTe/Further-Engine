package mobile.objects;

import mobile.flixel.controls.MobileControls as OnlineMobileControls;
import mobile.input.MobileInputID;

class VirtualButton {
	public var id:MobileInputID;
	public var controls:OnlineMobileControls;
	public var x:Float = 0;
	public var y:Float = 0;
	public var visible:Bool = true;
	public var tag:String;

	public function new(id:MobileInputID, controls:OnlineMobileControls) {
		this.id = id;
		this.controls = controls;
		this.tag = id.toString();
	}

	public var justPressed(get, never):Bool;
	public var pressed(get, never):Bool;
	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;

	inline function get_justPressed()  return controls.checkState(id.toString(), "justpressed");
	inline function get_pressed()      return controls.checkState(id.toString(), "pressed");
	inline function get_justReleased() return controls.checkState(id.toString(), "justreleased");
	inline function get_released()     return controls.checkState(id.toString(), "released");
}

class TouchPad extends OnlineMobileControls implements IMobileControls {
	public var instance:OnlineMobileControls;

	public var buttonLeft:VirtualButton;
	public var buttonUp:VirtualButton;
	public var buttonRight:VirtualButton;
	public var buttonDown:VirtualButton;
	public var buttonLeft2:VirtualButton;
	public var buttonUp2:VirtualButton;
	public var buttonRight2:VirtualButton;
	public var buttonDown2:VirtualButton;
	public var buttonA:VirtualButton;
	public var buttonB:VirtualButton;
	public var buttonC:VirtualButton;
	public var buttonD:VirtualButton;
	public var buttonE:VirtualButton;
	public var buttonF:VirtualButton;
	public var buttonG:VirtualButton;
	public var buttonH:VirtualButton;
	public var buttonI:VirtualButton;
	public var buttonJ:VirtualButton;
	public var buttonK:VirtualButton;
	public var buttonL:VirtualButton;
	public var buttonM:VirtualButton;
	public var buttonN:VirtualButton;
	public var buttonO:VirtualButton;
	public var buttonP:VirtualButton;
	public var buttonQ:VirtualButton;
	public var buttonR:VirtualButton;
	public var buttonS:VirtualButton;
	public var buttonT:VirtualButton;
	public var buttonU:VirtualButton;
	public var buttonV:VirtualButton;
	public var buttonW:VirtualButton;
	public var buttonX:VirtualButton;
	public var buttonY:VirtualButton;
	public var buttonZ:VirtualButton;

	public function new(DPadMode:String, ActionMode:String, ?Extra:Dynamic) {
		super();
		instance = this;
		initVirtualButtons();

		if (DPadMode != "NONE" && DPadMode != null) addDPad(DPadMode);
		if (ActionMode != "NONE" && ActionMode != null) addButton(ActionMode);

		if (Extra == 1)
			addButton("EXTRA_1");
		else if (Extra == 2)
			addButton("EXTRA_1_2");
	}

	private function initVirtualButtons():Void {
		buttonLeft   = new VirtualButton(MobileInputID.LEFT,   this);
		buttonUp     = new VirtualButton(MobileInputID.UP,     this);
		buttonRight  = new VirtualButton(MobileInputID.RIGHT,  this);
		buttonDown   = new VirtualButton(MobileInputID.DOWN,   this);
		buttonLeft2  = new VirtualButton(MobileInputID.LEFT2,  this);
		buttonUp2    = new VirtualButton(MobileInputID.UP2,    this);
		buttonRight2 = new VirtualButton(MobileInputID.RIGHT2, this);
		buttonDown2  = new VirtualButton(MobileInputID.DOWN2,  this);
		buttonA      = new VirtualButton(MobileInputID.A,      this);
		buttonB      = new VirtualButton(MobileInputID.B,      this);
		buttonC      = new VirtualButton(MobileInputID.C,      this);
		buttonD      = new VirtualButton(MobileInputID.D,      this);
		buttonE      = new VirtualButton(MobileInputID.E,      this);
		buttonF      = new VirtualButton(MobileInputID.F,      this);
		buttonG      = new VirtualButton(MobileInputID.G,      this);
		buttonH      = new VirtualButton(MobileInputID.H,      this);
		buttonI      = new VirtualButton(MobileInputID.I,      this);
		buttonJ      = new VirtualButton(MobileInputID.J,      this);
		buttonK      = new VirtualButton(MobileInputID.K,      this);
		buttonL      = new VirtualButton(MobileInputID.L,      this);
		buttonM      = new VirtualButton(MobileInputID.M,      this);
		buttonN      = new VirtualButton(MobileInputID.N,      this);
		buttonO      = new VirtualButton(MobileInputID.O,      this);
		buttonP      = new VirtualButton(MobileInputID.P,      this);
		buttonQ      = new VirtualButton(MobileInputID.Q,      this);
		buttonR      = new VirtualButton(MobileInputID.R,      this);
		buttonS      = new VirtualButton(MobileInputID.S,      this);
		buttonT      = new VirtualButton(MobileInputID.T,      this);
		buttonU      = new VirtualButton(MobileInputID.U,      this);
		buttonV      = new VirtualButton(MobileInputID.V,      this);
		buttonW      = new VirtualButton(MobileInputID.W,      this);
		buttonX      = new VirtualButton(MobileInputID.X,      this);
		buttonY      = new VirtualButton(MobileInputID.Y,      this);
		buttonZ      = new VirtualButton(MobileInputID.Z,      this);
		buttonExtra  = new VirtualButton(MobileInputID.EXTRA_1, this);
		buttonExtra2 = new VirtualButton(MobileInputID.EXTRA_2, this);
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

	public function setExtrasDefaultPos():Void {}
	public function setExtrasPos():Void {}
}