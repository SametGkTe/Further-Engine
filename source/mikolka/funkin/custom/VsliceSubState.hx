package mikolka.funkin.custom;

import mikolka.compatibility.freeplay.FreeplayHelpers;
import flixel.FlxBasic;
import flixel.util.FlxSort;

class VsliceSubState extends MusicBeatSubstate
{
	public function refresh()
	{
		sort(SortUtil.byZIndex, FlxSort.ASCENDING);
	}
	override function update(elapsed:Float) {
		if(FlxG.sound.music != null)  FreeplayHelpers.updateConductorSongTime(FlxG.sound.music.time); 
		super.update(elapsed);
	}
}
