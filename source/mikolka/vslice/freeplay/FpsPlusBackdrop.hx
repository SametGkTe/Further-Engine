package mikolka.vslice.freeplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Animated FPS Plus-inspired Freeplay stage.
 * The character DJ remains P-Slice's FreeplayDJ; this class supplies the
 * deck/visualizer layer around it without replacing its animations or events.
 */
class FpsPlusBackdrop extends FlxTypedGroup<FlxSprite>
{
	var wash:FlxSprite;
	var decorations:FlxSprite;
	var dynamicLayer:FlxSprite;
	var deck:FlxSprite;
	var title:FlxText;
	var djStatus:FlxText;
	var bars:Array<FlxSprite> = [];
	var phase:Float = 0;
	var lastDjState:String = null;

	public function new()
	{
		super();
		wash = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF080713);
		wash.alpha = 0.36;
		add(wash);

		decorations = new FlxSprite().loadGraphic(Paths.image('freeplay/fpsplus/layerfree'));
		decorations.setGraphicSize(FlxG.width, FlxG.height);
		decorations.updateHitbox();
		decorations.alpha = 0.22;
		add(decorations);

		dynamicLayer = new FlxSprite(FlxG.width - 410, FlxG.height - 240).loadGraphic(Paths.image('freeplay/fpsplus/dinamic'));
		dynamicLayer.setGraphicSize(390, 0);
		dynamicLayer.updateHitbox();
		dynamicLayer.alpha = 0.22;
		add(dynamicLayer);

		deck = new FlxSprite(18, FlxG.height - 126).makeGraphic(286, 94, 0xD91B1A2A);
		add(deck);
		title = makeText(31, FlxG.height - 116, 255, 'DJ DECK // READY', 16, 0xFFE4C9FF);
		title.bold = true;
		add(title);
		djStatus = makeText(31, FlxG.height - 49, 255, 'DJ: LOADING', 13, 0xFF9FE8FF);
		add(djStatus);

		for (i in 0...48)
		{
			var bar = new FlxSprite(i * (FlxG.width / 48), FlxG.height - 7).makeGraphic(Std.int(FlxG.width / 48) - 2, 1, 0xFFB566FF);
			bar.origin.set(0, 1);
			bar.alpha = 0.7;
			bars.push(bar);
			add(bar);
		}
	}

	function makeText(x:Float, y:Float, width:Float, text:String, size:Int, color:FlxColor):FlxText
	{
		var result = new FlxText(x, y, width, text, size);
		result.setFormat('VCR OSD Mono', size, color);
		result.antialiasing = ClientPrefs.data.antialiasing;
		return result;
	}

	public function setDjState(animation:Null<String>):Void
	{
		var state = animation == null || animation.length == 0 ? 'DJ: STANDBY' : 'DJ: ' + animation.toUpperCase();
		if (state == lastDjState)
			return;
		lastDjState = state;
		djStatus.text = state;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		phase += elapsed * 5;
		dynamicLayer.alpha = 0.16 + (Math.sin(phase * 0.35) + 1) * 0.05;
		var amplitude:Float = 0;
		if (FlxG.sound.music != null)
		{
			var raw:Dynamic = Reflect.field(FlxG.sound.music, 'amplitudeLeft');
			if (raw == null) raw = Reflect.field(FlxG.sound.music, 'amplitude');
			if (raw != null) amplitude = Math.min(1, Math.abs(cast raw));
		}
		for (i in 0...bars.length)
		{
			var wave = (Math.sin(phase + i * 0.42) + 1) * 0.5;
			bars[i].scale.y = 2 + Std.int((wave * 0.35 + amplitude * 0.65) * 82);
			bars[i].color = i % 3 == 0 ? 0xFF71D7FF : 0xFFB566FF;
		}
	}
}
