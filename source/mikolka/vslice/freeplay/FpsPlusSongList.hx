package mikolka.vslice.freeplay;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.HealthIcon;
import mikolka.vslice.freeplay.capsule.SongMenuItem;

/**
 * FPS Plus-style vertical song-card renderer.
 * Selection and confirmation deliberately stay in FreeplayState/SongCapsuleGroup;
 * this renderer only replaces the old capsule presentation.
 */
class FpsPlusSongList extends FlxTypedGroup<FpsPlusSongRow>
{
	static inline var ROW_HEIGHT:Int = 76;
	static inline var VISIBLE_ROWS:Int = 7;
	var originX:Float;
	var originY:Float;
	var rows:Array<FpsPlusSongRow> = [];

	public function new(x:Float, y:Float)
	{
		super();
		originX = x;
		originY = y;
		for (i in 0...VISIBLE_ROWS)
		{
			var row = new FpsPlusSongRow(x, y + i * ROW_HEIGHT);
			rows.push(row);
			add(row);
		}
	}

	public function refresh(entries:Array<SongMenuItem>, selectedIndex:Int):Void
	{
		for (slot in 0...rows.length)
		{
			var songIndex = selectedIndex + slot - Std.int(rows.length / 2);
			var row = rows[slot];
			if (songIndex < 0 || songIndex >= entries.length || entries[songIndex] == null)
			{
				row.visible = false;
				continue;
			}

			var item = entries[songIndex];
			var isSelected = songIndex == selectedIndex;
			row.setSong(item, isSelected, songIndex == 0);
			row.setPosition(originX, originY + slot * ROW_HEIGHT);
			row.visible = true;
		}
	}
}

class FpsPlusSongRow extends FlxSpriteGroup
{
	var card:FlxSprite;
	var accent:FlxSprite;
	var icon:HealthIcon;
	var nameText:FlxText;
	var metaText:FlxText;
	var selected:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		card = new FlxSprite().makeGraphic(480, 66, 0xE61B1A2A);
		add(card);
		accent = new FlxSprite().makeGraphic(7, 66, 0xFFB566FF);
		add(accent);
		icon = new HealthIcon('bf');
		icon.setGraphicSize(52, 52);
		icon.updateHitbox();
		icon.setPosition(16, 7);
		add(icon);
		nameText = new FlxText(80, 9, 300, '', 25);
		nameText.setFormat('VCR OSD Mono', 25, FlxColor.WHITE);
		nameText.bold = true;
		add(nameText);
		metaText = new FlxText(81, 39, 370, '', 13);
		metaText.setFormat('VCR OSD Mono', 13, 0xFFB7B4C8);
		add(metaText);
	}

	public function setSong(item:SongMenuItem, isSelected:Bool, isRandom:Bool):Void
	{
		selected = isSelected;
		var data = item.songData;
		var color:FlxColor = isRandom || data == null ? 0xFFFFD166 : data.color;
		accent.color = color;
		card.color = isSelected ? FlxColor.WHITE : 0xFF4D4A63;
		card.alpha = isSelected ? 0.95 : 0.62;
		nameText.alpha = isSelected ? 1 : 0.68;
		metaText.alpha = isSelected ? 1 : 0.55;
		nameText.text = isRandom || data == null ? 'RANDOM SONG' : data.songName.toUpperCase();
		var difficulty:String = data?.currentDifficulty;
		if (difficulty == null || difficulty.length == 0)
			difficulty = 'normal';
		metaText.text = isRandom || data == null ? 'PLAY A RANDOM AVAILABLE TRACK' : 'DIFFICULTY: ' + difficulty.toUpperCase();
		if (!isRandom && data != null)
			icon.changeIcon(data.songCharacter);
		else
			icon.changeIcon('bf');
	}
}
