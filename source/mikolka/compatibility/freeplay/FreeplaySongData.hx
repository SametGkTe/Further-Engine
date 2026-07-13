package mikolka.compatibility.freeplay;

import mikolka.vslice.freeplay.obj.SngCapsuleData;
import mikolka.vslice.freeplay.pslice.BPMCache;
import mikolka.funkin.Scoring.ScoringRank;
import backend.Highscore;
import backend.WeekData;
import haxe.ds.StringMap;
import haxe.io.Path;


class FreeplaySongData extends SngCapsuleData
{
	static var _resolvedSongPathCache:StringMap<String> = new StringMap<String>();
	static var _failedSongPathLogged:StringMap<Bool> = new StringMap<Bool>();

	public function new(levelId:Int, songId:String, songCharacter:String, color:FlxColor)
	{
		super(levelId,songId,songCharacter,color);
		this.isFav = ClientPrefs.data.favSongIds.contains(songId + this.levelName); 
	}

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
	
	private function isAbsolutePath(path:String):Bool
	{
		if (path == null || path.length == 0) return false;
		if (path.charAt(0) == "/" || path.charAt(0) == "\\") return true;
		return path.length > 1 && path.charAt(1) == ":";
	}

	private function toRuntimePath(path:String):String
	{
		if (path == null || path.length == 0) return path;
		if (isAbsolutePath(path)) return Path.normalize(path);

		var exeDir = Path.directory(Sys.programPath());
		return Path.normalize(Path.join([exeDir, path]));
	}

	private function addCandidate(list:Array<String>, path:String):Void
	{
		if (path == null || path.length == 0) return;

		if (!list.contains(path))
			list.push(path);

		var runtimePath = toRuntimePath(path);
		if (runtimePath != path && !list.contains(runtimePath))
			list.push(runtimePath);
	}

	private function normalizePath(path:String):String
	{
		if (path == null) return "";
		path = path.split("\\").join("/");
		while (path.indexOf("//") >= 0)
			path = path.split("//").join("/");
		return path;
	}

	private function resolveSongDataPath(fileSngName:String):String
	{
		if (_resolvedSongPathCache.exists(fileSngName))
			return _resolvedSongPathCache.get(fileSngName);

		var cwd:String = normalizePath(Sys.getCwd());
		if (cwd.endsWith("/"))
			cwd = cwd.substr(0, cwd.length - 1);

		var candidates:Array<String> = [
			cwd + "/assets/shared/data/" + fileSngName,
			cwd + "/assets/shared/data/songs/" + fileSngName,
			cwd + "/assets/data/" + fileSngName,
			cwd + "/assets/data/songs/" + fileSngName,
		];

		#if MODS_ALLOWED
		candidates.unshift(cwd + "/mods/data/songs/" + fileSngName);
		candidates.unshift(cwd + "/mods/data/" + fileSngName);
		#end

		for (path in candidates)
		{
			try {
				if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path))
				{
					_resolvedSongPathCache.set(fileSngName, path);
					return path;
				}
			} catch(e:Dynamic) {}
		}

		var fallback = cwd + "/assets/shared/data/" + fileSngName;
		_resolvedSongPathCache.set(fileSngName, fallback);

		if (!_failedSongPathLogged.exists(fileSngName))
		{
			_failedSongPathLogged.set(fileSngName, true);
			trace('[FreeplaySongData] Failed to resolve "$fileSngName". Tried: ' + candidates.join(" | "));
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
		
		if (sngDataPath != null && sys.FileSystem.exists(sngDataPath) && sys.FileSystem.isDirectory(sngDataPath))
		{
			var chartFiles = sys.FileSystem.readDirectory(sngDataPath).filter(s ->
				s != null && s.toLowerCase().endsWith(".json")
			);
			var diffNames:Array<String> = [];

			for (file in chartFiles)
			{
				var lower = file.toLowerCase();
				var lowerSong = fileSngName.toLowerCase();

				if (lower == lowerSong + ".json")
				{
					if (!diffNames.contains("normal"))
						diffNames.push("normal");
				}
				else if (lower.startsWith(lowerSong + "-"))
				{
					var diff = lower.substring(lowerSong.length + 1, lower.length - 5).trim();
					if (diff.length > 0 && !diffNames.contains(diff))
						diffNames.push(diff);
				}
			}

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
		return sngDataPath != null && sys.FileSystem.exists(sngDataPath) && sys.FileSystem.isDirectory(sngDataPath);
	}
}
