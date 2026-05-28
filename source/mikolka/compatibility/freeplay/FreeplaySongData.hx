package mikolka.compatibility.freeplay;

import mikolka.vslice.freeplay.obj.SngCapsuleData;
import mikolka.vslice.freeplay.pslice.BPMCache;
import mikolka.funkin.Scoring.ScoringRank;
import backend.Highscore;
import backend.WeekData;




/**
 * Data about a specific song in the freeplay menu. Very heaviely dependent on exact engine
 */
class FreeplaySongData extends SngCapsuleData
{

	public function new(levelId:Int, songId:String, songCharacter:String, color:FlxColor)
	{
		super(levelId,songId,songCharacter,color);
		this.isFav = ClientPrefs.data.favSongIds.contains(songId + this.levelName); // Save.instance.isSongFavorited(songId);
	}

	/**
	 * Toggle whether or not the song is favorited, then flush to save data.
	 * @return Whether or not the song is now favorited.
	 */
	public function toggleFavorite():Bool
	{
		isFav = !isFav;
		if (isFav)
		{
			ClientPrefs.data.favSongIds.pushUnique(this.songId + this.levelName);
		}
		else
		{
			ClientPrefs.data.favSongIds.remove(this.songId + this.levelName);
		}
		ClientPrefs.saveSettings();
		return isFav;
	}

	private function resolveSongDataPath(fileSngName:String):String
	{
		var candidates:Array<String> = [];

		#if MODS_ALLOWED
		candidates.push(Paths.modFolders('data/' + fileSngName));
		candidates.push(Paths.modFolders('data/songs/' + fileSngName));
		#end

		// Export/runtime tarafı
		candidates.push(Paths.getSharedPath('data/' + fileSngName));
		candidates.push(Paths.getSharedPath('data/songs/' + fileSngName));

		// Senin proje kaynak yapın
		candidates.push('assets/base_game/shared/data/' + fileSngName);
		candidates.push('assets/base_game/shared/data/songs/' + fileSngName);

		for (path in candidates)
		{
			if (path != null && NativeFileSystem.exists(path))
			{
				trace('[FreeplaySongData] Resolved "' + fileSngName + '" to: ' + path);
				return path;
			}
		}

		trace('[FreeplaySongData] Failed to resolve "' + fileSngName + '". Tried: ' + candidates.join(' | '));
		return candidates[candidates.length - 1];
	}
	
	function updateValues():Void
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[levelId]);

		levelName = leWeek.weekName;
		this.songDifficulties = leWeek.difficulties.extractWeeks();
		this.folder = leWeek.folder;

		Mods.currentModDirectory = this.folder;

		var fileSngName = Paths.formatToSongPath(getNativeSongId());
		var sngDataPath = resolveSongDataPath(fileSngName);

		var discoveredDiffs:Array<String> = [];

		if (NativeFileSystem.exists(sngDataPath))
		{
			var chartFiles = NativeFileSystem.readDirectory(sngDataPath).filter(s ->
				s.toLowerCase().startsWith(fileSngName) && s.endsWith(".json")
			);

			var diffNames = chartFiles.map(s -> s.substring(fileSngName.length + 1, s.length - 5));

			if (diffNames.remove("."))
				diffNames.insert(1, "normal");
			if (diffNames.remove("easy"))
				diffNames.insert(0, "easy");
			if (diffNames.remove("hard"))
				diffNames.insert(2, "hard");

			discoveredDiffs = diffNames;
		}

		if (discoveredDiffs.length > 0)
		{
			this.songDifficulties = discoveredDiffs;
		}
		else if (this.songDifficulties.length == 0)
		{
			this.songDifficulties = ['normal'];
			trace('Directory $sngDataPath does not exist! $songName has no charts (difficulties)!');
			trace('Forcing "normal" difficulty. Expect issues!!');
		}

		if (allowErect && !hasErectSong())
		{
			this.songDifficulties.remove("erect");
			this.songDifficulties.remove("nightmare");
		}

		if (!this.songDifficulties.contains(currentDifficulty))
		{
			@:bypassAccessor
			currentDifficulty = songDifficulties[0];
		}

		songStartingBpm = BPMCache.instance.getBPM(sngDataPath, fileSngName);

		this.scoringRank = Scoring.calculateRankForSong(
			Highscore.formatSong(getNativeSongId(), loadAndGetDiffId())
		);

		updateIsNewTag();
	}

	public function updateIsNewTag()
	{
		if(!metaAllowNew && !ClientPrefs.data.vsliceForceNewTag){
			isNew = false;
			return;
		}
		var wasCompleted = false;
		var saveSongName = Paths.formatToSongPath(getNativeSongId());
		for (x in Highscore.songScores.keys())
		{
			if (x.startsWith(saveSongName) && Highscore.songScores[x] > 0)
			{
				wasCompleted = true;
				break;
			}
		}
		isNew = !wasCompleted;
	}

	public function loadAndGetDiffId()
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[levelId]);
		Difficulty.loadFromWeek(leWeek);
		return Difficulty.list.findIndex(s -> s.trim().toLowerCase() == currentDifficulty);
	}


	public function hasErectSong():Bool
	{
		var fileSngName = Paths.formatToSongPath(songId + "-erect");
		var sngDataPath = resolveSongDataPath(fileSngName);
		return NativeFileSystem.exists(sngDataPath);
	}
}
