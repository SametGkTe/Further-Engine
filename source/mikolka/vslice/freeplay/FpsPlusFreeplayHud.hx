package mikolka.vslice.freeplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * FPS Plus-inspired Freeplay information panel.
 *
 * This is deliberately presentation-only: song discovery, player selection,
 * mod paths, touch input and playback remain owned by P-Slice FreeplayState.
 * Keeping that boundary makes the FPS Plus presentation safe for mobile and
 * P-Slice's character/result flows.
 *
 * Visual source assets are adapted from Psych-Plus-Team/FNF-PlusEngine
 * (Apache-2.0), commit 708213105b4aa16b17f71db0e164cbe4654ffa54.
 */
class FpsPlusFreeplayHud extends FlxTypedGroup<FlxSprite>
{
	public static inline var PANEL_WIDTH:Int = 330;
	public static inline var PANEL_HEIGHT:Int = 174;

	var panel:FlxSprite;
	var title:FlxText;
	var song:FlxText;
	var difficulty:FlxText;
	var score:FlxText;
	var accuracy:FlxText;
	var hint:FlxText;
	var spectrum:Array<FlxSprite> = [];
	var spectrumPhase:Float = 0;
	var lastDisplayKey:String = null;

	public function new(x:Float, y:Float)
	{
		super();

		panel = new FlxSprite(x, y).loadGraphic(Paths.image('freeplay/fpsplus/card'));
		panel.setGraphicSize(PANEL_WIDTH, PANEL_HEIGHT);
		panel.updateHitbox();
		panel.alpha = 0.94;
		add(panel);

		title = makeText(x + 18, y + 12, PANEL_WIDTH - 36, 'FREEPLAY // FPS PLUS', 15, 0xFFE4C9FF);
		title.bold = true;
		add(title);

		song = makeText(x + 18, y + 40, PANEL_WIDTH - 36, '-', 27, FlxColor.WHITE);
		song.bold = true;
		add(song);

		difficulty = makeText(x + 18, y + 76, PANEL_WIDTH - 36, 'DIFFICULTY: NORMAL', 14, 0xFFFFD166);
		add(difficulty);

		score = makeText(x + 18, y + 102, 180, 'SCORE 0', 16, FlxColor.WHITE);
		add(score);
		accuracy = makeText(x + 190, y + 102, 122, '0.00%', 16, 0xFF9FE8FF);
		accuracy.alignment = RIGHT;
		add(accuracy);

		hint = makeText(x + 18, y + PANEL_HEIGHT - 25, PANEL_WIDTH - 36, '← → DIFFICULTY   •   C SEARCH', 11, 0xFFB8B4C5);
		hint.alignment = CENTER;
		add(hint);

		for (i in 0...32)
		{
			var bar = new FlxSprite(x + 18 + i * 9, y + 145).makeGraphic(5, 1, 0xFFB566FF);
			bar.origin.set(0, 1);
			bar.alpha = 0.72;
			spectrum.push(bar);
			add(bar);
		}
	}

	function makeText(x:Float, y:Float, width:Float, value:String, size:Int, color:FlxColor):FlxText
	{
		var text = new FlxText(x, y, width, value, size);
		text.setFormat('VCR OSD Mono', size, color);
		text.antialiasing = ClientPrefs.data.antialiasing;
		return text;
	}

	public function refresh(songName:Null<String>, difficultyId:Null<String>, intendedScore:Int, intendedAccuracy:Float):Void
	{
		var safeSong = songName == null || songName.length == 0 ? 'RANDOM' : songName.toUpperCase();
		var safeDifficulty = difficultyId == null ? 'NORMAL' : difficultyId.toUpperCase();
		var safeAccuracy = Std.string(Math.round(intendedAccuracy * 10000) / 100) + '%';
		var displayKey = safeSong + '|' + safeDifficulty + '|' + intendedScore + '|' + safeAccuracy;
		if (displayKey == lastDisplayKey)
			return;
		lastDisplayKey = displayKey;
		song.text = safeSong;
		difficulty.text = 'DIFFICULTY: ' + safeDifficulty;
		score.text = 'SCORE ' + Std.string(intendedScore);
		accuracy.text = safeAccuracy;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		spectrumPhase += elapsed * 5;

		// Use music amplitude when the target exposes it; the sine fallback keeps
		// the panel alive on targets/backends where amplitude is unavailable.
		var amplitude:Float = 0;
		if (FlxG.sound.music != null)
		{
			var raw:Dynamic = Reflect.field(FlxG.sound.music, 'amplitudeLeft');
			if (raw == null) raw = Reflect.field(FlxG.sound.music, 'amplitude');
			if (raw != null) amplitude = Math.min(1, Math.abs(cast raw));
		}

		for (i in 0...spectrum.length)
		{
			var wave = (Math.sin(spectrumPhase + i * 0.62) + 1) * 0.5;
			var height = 2 + Std.int((wave * 0.38 + amplitude * 0.62) * 22);
			var bar = spectrum[i];
			bar.scale.y = height;
			bar.color = i % 2 == 0 ? 0xFFB566FF : 0xFF71D7FF;
		}
	}
}
