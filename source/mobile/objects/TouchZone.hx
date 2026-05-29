package mobile.objects;

import mobile.objects.TouchButton.TypedTouchButton;
import flixel.util.FlxColor;

class TouchZone extends TypedTouchButton<FlxSprite>
{
	public function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0, color:FlxColor = FlxColor.GREEN)
	{
		super(x, y);
		makeGraphic(Std.int(width), Std.int(height), color);
		alpha = #if debug 0.3 #else 0 #end;
		statusIndicatorType = NONE;
	}
}