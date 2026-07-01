package mobile.objects;

import mobile.input.MobileInputID;

class FunkinHitbox extends Hitbox {
	public function new(?extraMode:Dynamic, ?hints:Dynamic = null) {
		var mode:ExtraActions = NONE;
		if (extraMode != null) {
			switch (Std.string(extraMode).toUpperCase()) {
				case 'SINGLE':
					mode = SINGLE;
				case 'DOUBLE':
					mode = DOUBLE;
				default:
					mode = NONE;
			}
		}
		super(mode);
	}

	public inline function pressed(keys:Dynamic):Bool {
		return checkButtons(keys, PRESSED);
	}

	public inline function justPressed(keys:Dynamic):Bool {
		return checkButtons(keys, JUST_PRESSED);
	}

	public inline function released(keys:Dynamic):Bool {
		return checkButtons(keys, RELEASED);
	}

	public inline function justReleased(keys:Dynamic):Bool {
		return checkButtons(keys, JUST_RELEASED);
	}

	private function checkButtons(keys:Dynamic, state:ButtonsStates):Bool {
		if (keys == null) return false;

		var ids:Array<MobileInputID> = [];
		if (Std.isOfType(keys, String)) {
			ids.push(MobileInputID.fromString(cast keys));
		} else if (Std.isOfType(keys, Array)) {
			for (item in cast(keys, Array<Dynamic>)) {
				if (Std.isOfType(item, String)) {
					ids.push(MobileInputID.fromString(cast item));
				} else if (Std.isOfType(item, MobileInputID)) {
					ids.push(cast item);
				}
			}
		}

		for (id in ids) {
			if (checkStatus(id, state)) return true;
		}
		return false;
	}
}
