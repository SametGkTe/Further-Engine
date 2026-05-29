package mikolka.compatibility.freeplay;

import mikolka.vslice.freeplay.obj.SngCapsuleData;
import mikolka.vslice.freeplay.pslice.BPMCache;
import mikolka.funkin.Scoring.ScoringRank;
import backend.Highscore;
import backend.WeekData;
import haxe.ds.StringMap;




/**
 * Data about a specific song in the freeplay menu. Very heaviely dependent on exact engine
 */
class FreeplaySongData extends SngCapsuleData
{
	static var _resolvedSongPathCache:StringMap<String> = new StringMap<String>();
	static var _failedSongPathLogged:StringMap<Bool> = new StringMap<Bool>();

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

		if (ClientPrefs.data.favSongIds == null)
			ClientPrefs.data.favSongIds = [];

		var key = this.songId + this.levelName;

		if (isFav)
		{
			if (!ClientPrefs.data.favSongIds.contains(key))
				ClientPrefs.data.favSongIds.push(key);
		}
		else
		{
			ClientPrefs.data.favSongIds.remove(key);
		}

		ClientPrefs.saveSettings();
		return isFav;
	}

	private function resolveSongDataPath(fileSngName:String):String
	{
		if (_resolvedSongPathCache.exists(fileSngName))
			return _resolvedSongPathCache.get(fileSngName);

		var candidates:Array<String> = [];

		#if MODS_ALLOWED
		candidates.push(Paths.modFolders('data/' + fileSngName));
		candidates.push(Paths.modFolders('data/songs/' + fileSngName));
		#end

		// Export/shared tarafı
		candidates.push(Paths.getSharedPath('data/' + fileSngName));
		candidates.push(Paths.getSharedPath('data/songs/' + fileSngName));

		// Doğrudan asset fallback
		candidates.push('assets/data/' + fileSngName);
		candidates.push('assets/data/songs/' + fileSngName);
		candidates.push('assets/shared/data/' + fileSngName);
		candidates.push('assets/shared/data/songs/' + fileSngName);

		// Base game fallback
		candidates.push('assets/base_game/data/' + fileSngName);
		candidates.push('assets/base_game/data/songs/' + fileSngName);
		candidates.push('assets/base_game/shared/data/' + fileSngName);
		candidates.push('assets/base_game/shared/data/songs/' + fileSngName);

		for (path in candidates)
		{
			if (path != null && path.length > 0 && NativeFileSystem.exists(path))
			{
				_resolvedSongPathCache.set(fileSngName, path);
				trace('[FreeplaySongData] Resolved "' + fileSngName + '" to: ' + path);
				return path;
			}
		}

		var fallback = Paths.getSharedPath('data/' + fileSngName);
		_resolvedSongPathCache.set(fileSngName, fallback);

		if (!_failedSongPathLogged.exists(fileSngName))
		{
			_failedSongPathLogged.set(fileSngName, true);
			trace('[FreeplaySongData] Failed to resolve "' + fileSngName + '". Tried: ' + candidates.join(' | '));
		}

		return fallback;
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
				s != null && s.toLowerCase().endsWith(".json")
			);

			var diffNames:Array<String> = [];

			for (file in chartFiles)
			{
				var lower = file.toLowerCase();
				var lowerSong = fileSngName.toLowerCase();

				// normal: tutorial.json
				if (lower == lowerSong + ".json")
				{
					if (!diffNames.contains("normal"))
						diffNames.push("normal");
				}
				// hard/easy/other: tutorial-hard.json
				else if (lower.startsWith(lowerSong + "-"))
				{
					var diff = lower.substring(lowerSong.length + 1, lower.length - 5).trim();
					if (diff.length > 0 && !diffNames.contains(diff))
						diffNames.push(diff);
				}
			}

			// Sıralamayı düzelt
			var ordered:Array<String> = [];

			if (diffNames.contains("easy")) ordered.push("easy");
			if (diffNames.contains("normal")) ordered.push("normal");
			if (diffNames.contains("hard")) ordered.push("hard");

			for (diff in diffNames)
			{
				if (!ordered.contains(diff))
					ordered.push(diff);
			}

			discoveredDiffs = ordered;
		}

		if (discoveredDiffs.length > 0)
		{
			this.songDifficulties = discoveredDiffs;
		}
		else if (this.songDifficulties.length == 0)
		{
			this.songDifficulties = ['normal'];

			if (!_failedSongPathLogged.exists(fileSngName + "_diffs"))
			{
				_failedSongPathLogged.set(fileSngName + "_diffs", true);
				trace('Directory $sngDataPath does not exist! $songName has no charts (difficulties)!');
				trace('Forcing "normal" difficulty. Expect issues!!');
			}
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
