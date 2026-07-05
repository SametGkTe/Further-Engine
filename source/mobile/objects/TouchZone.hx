package mobile.objects;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import mobile.objects.TouchButton.TypedTouchButton;

class TouchZone extends TypedTouchButton<FlxSprite>
{
	public function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0, color:FlxColor = FlxColor.GREEN)
	{
		super(x, y);

		makeGraphic(Std.int(Math.max(width, 1)), Std.int(Math.max(height, 1)), color);
		alpha = #if debug 0.3 #else 0.0001 #end;
		statusIndicatorType = NONE;
		scrollFactor.set();
	}
}