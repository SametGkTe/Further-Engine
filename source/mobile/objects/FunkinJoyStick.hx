package mobile.objects;

import flixel.FlxSprite;
import flixel.util.FlxColor;

class FunkinJoyStick extends FlxSprite {
	public function new(x:Float = 0, y:Float = 0, ?graphic:String, ?onMove:Float->Float->Float->String->Void) {
		super(x, y);
		makeGraphic(1, 1, FlxColor.TRANSPARENT);
	}

	public inline function pressed(keys:Dynamic):Bool {
		return false;
	}

	public inline function justPressed(keys:Dynamic):Bool {
		return false;
	}

	public inline function released(keys:Dynamic):Bool {
		return false;
	}

	public inline function justReleased(keys:Dynamic):Bool {
		return false;
	}
}
