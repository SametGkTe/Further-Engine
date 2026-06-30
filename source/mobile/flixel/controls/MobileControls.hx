package mobile.flixel.controls;

#if flixel
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.Json;
import mobile.io.File;
import mobile.input.MobileInputID;

class MobileControls extends FlxSpriteGroup {
	public static var DPAD_PATH:String = "assets/shared/mobile/DPad/images/";
	public static var BUTTON_PATH:String = "assets/shared/mobile/Button/images/";
	public static var JOYSTICK_PATH:String = "assets/shared/mobile/JoyStick/images/";

	public static var DPAD_JSON:String = "assets/shared/mobile/DPad/";
	public static var BUTTON_JSON:String = "assets/shared/mobile/Button/";
	public static var JOYSTICK_JSON:String = "assets/shared/mobile/JoyStick/";
	public static var HITBOX_JSON:String = "assets/shared/mobile/Hitbox/";
	
	public var buttonExtra:mobile.objects.VirtualButton;
	public var buttonExtra2:mobile.objects.VirtualButton;
	
	private function get_buttonExtra():mobile.objects.VirtualButton
    return new mobile.objects.VirtualButton(mobile.input.MobileInputID.EXTRA_1, this);

	private function get_buttonExtra2():mobile.objects.VirtualButton
		return new mobile.objects.VirtualButton(mobile.input.MobileInputID.EXTRA_2, this);

	private var controls:Array<InputHandler> = [];

	public var buttons:Array<mobile.flixel.controls.Button> = [];
	public var dpads:Array<mobile.flixel.controls.DPad> = [];
	public var joysticks:Array<mobile.flixel.controls.Joystick> = [];
	public var hitboxes:Array<mobile.flixel.controls.Hitbox> = [];

	public var onButtonDown:FlxTypedSignal<(InputHandler, String) -> Void> = new FlxTypedSignal<(InputHandler, String) -> Void>();
	public var onButtonUp:FlxTypedSignal<(InputHandler, String) -> Void> = new FlxTypedSignal<(InputHandler, String) -> Void>();

	public function new() {
		super();
	}

	public function getButtonByName(buttonName:String):mobile.flixel.controls.Button {
		for (btn in buttons) {
			if (btn != null && btn.name == buttonName) {
				return btn;
			}
		}
		return null;
	}

	public function addButton(name:String):Void {
		if (buttons.length > 0) removeButton();

		var path = BUTTON_JSON + name + ".json";
		var rawContent = File.getContent(path);
		if (rawContent == null) return;

		var parsed:Dynamic = Json.parse(rawContent);
		for (data in (parsed.buttons : Array<Dynamic>)) {
			var btn:mobile.flixel.controls.Button = new mobile.flixel.controls.Button(data);
			addControl(btn);
			buttons.push(btn);
		}
	}

	public function addDPad(name:String):Void {
		if (dpads.length > 0) removeDPad();

		var path = DPAD_JSON + name + ".json";
		var rawContent = File.getContent(path);
		if (rawContent == null) return;

		var parsed:Dynamic = Json.parse(rawContent);
		for (data in (parsed.dpads : Array<Dynamic>)) {
			var dpad:mobile.flixel.controls.DPad = new mobile.flixel.controls.DPad(data);
			addControl(dpad);
			dpads.push(dpad);
		}
	}

	public function addJoyStick(name:String):Void {
		if (joysticks.length > 0) removeJoyStick();

		var path = JOYSTICK_JSON + name + ".json";
		var rawContent = File.getContent(path);
		if (rawContent == null) return;

		var parsed:Dynamic = Json.parse(rawContent);
		for (data in (parsed.joysticks : Array<Dynamic>)) {
			var joy:mobile.flixel.controls.Joystick = new mobile.flixel.controls.Joystick(data);
			addControl(joy);
			joysticks.push(joy);
		}
	}

	public function addHitbox(name:String):Void {
		if (hitboxes.length > 0) removeHitbox();

		var path = HITBOX_JSON + name + ".json";
		var rawContent = File.getContent(path);
		if (rawContent == null) return;

		var parsed:Dynamic = Json.parse(rawContent);
		for (data in (parsed.hitboxes : Array<Dynamic>)) {
			var box:mobile.flixel.controls.Hitbox = new mobile.flixel.controls.Hitbox(data);
			addControl(box);
			hitboxes.push(box);
		}
	}

	private function addControl(c:InputHandler):Void {
		controls.push(c);
		c.onButtonDown.add(_dispatchButtonDown);
		c.onButtonUp.add(_dispatchButtonUp);
		add(c);
	}

	private function _dispatchButtonDown(handler:InputHandler, id:String):Void {
		onButtonDown.dispatch(handler, id);
	}

	private function _dispatchButtonUp(handler:InputHandler, id:String):Void {
		onButtonUp.dispatch(handler, id);
	}

	public function removeButton():Void {
		for (btn in buttons) {
			controls.remove(btn);
			remove(btn, true);
		}
		buttons = [];
	}

	public function removeDPad():Void {
		for (dpad in dpads) {
			controls.remove(dpad);
			remove(dpad, true);
		}
		dpads = [];
	}

	public function removeJoyStick():Void {
		for (joy in joysticks) {
			controls.remove(joy);
			remove(joy, true);
		}
		joysticks = [];
	}

	public function removeHitbox():Void {
		for (box in hitboxes) {
			controls.remove(box);
			remove(box, true);
		}
		hitboxes = [];
	}

	public function clearControls():Void {
		removeButton();
		removeDPad();
		removeJoyStick();
		removeHitbox();
		resetAllInputs();
	}

	public function checkState(id:String, state:String = "pressed"):Bool {
		for (c in controls) {
			if (c == null || c.disabled) continue;

			switch (state.toLowerCase()) {
				case "pressed":
					if (c.pressed(id)) return true;
				case "justpressed":
					if (c.justPressed(id)) return true;
				case "justreleased":
					if (c.justReleased(id)) return true;
				case "released":
					if (c.released(id)) return true;
			}
		}
		return false;
	}

	public function anyPressed(keys:Array<MobileInputID>):Bool {
		if (keys == null) return false;
		for (key in keys) if (checkState(key.toString(), "pressed")) return true;
		return false;
	}

	public function anyJustPressed(keys:Array<MobileInputID>):Bool {
		if (keys == null) return false;
		for (key in keys) if (checkState(key.toString(), "justpressed")) return true;
		return false;
	}

	public function anyJustReleased(keys:Array<MobileInputID>):Bool {
		if (keys == null) return false;
		for (key in keys) if (checkState(key.toString(), "justreleased")) return true;
		return false;
	}

	public function anyReleased(keys:Array<MobileInputID>):Bool {
		if (keys == null) return false;
		for (key in keys) if (checkState(key.toString(), "released")) return true;
		return false;
	}

	public function buttonPressed(id:MobileInputID):Bool {
		return checkState(id.toString(), "pressed");
	}

	public function buttonJustPressed(id:MobileInputID):Bool {
		return checkState(id.toString(), "justpressed");
	}

	public function buttonJustReleased(id:MobileInputID):Bool {
		return checkState(id.toString(), "justreleased");
	}

	public function resetAllInputs():Void {
		for (c in controls) {
			if (c != null) c.resetInputs();
		}
	}
}
#end