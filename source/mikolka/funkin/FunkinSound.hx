package mikolka.funkin;

import mikolka.funkin.sound.FlxPartialSound;
import openfl.media.Sound;
import mikolka.vslice.freeplay.FreeplayState;
import flixel.system.FlxAssets.FlxSoundAsset;

class FunkinSound extends FlxSound
{
	public static function playOnce(key:String, volume:Float = 1.0, ?onComplete:Void->Void, ?onLoad:Void->Void):Void
	{
		var result = FunkinSound.load(key, volume, false, true, true, onComplete, onLoad);
	}

	public static function load(embeddedSound:FlxSoundAsset, volume:Float = 1.0, looped:Bool = false, autoDestroy:Bool = false, autoPlay:Bool = false,
			?onComplete:Void->Void, ?onLoad:Void->Void):Null<FunkinSound>
	{

		var sound:FunkinSound = new FunkinSound(); 

		if(embeddedSound is String) embeddedSound = Paths.sound(embeddedSound);
		sound.loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);


		if (autoPlay)
			sound.play();
		sound.volume = volume;
		sound.group = FlxG.sound.defaultSoundGroup;
		sound.persist = true;

		FlxG.sound.list.add(sound);

		if (onLoad != null && sound._sound != null)
			onLoad();

		return sound;
	}

	static var prevSound:Sound = null;
	public static function playMusic(key:String, params:FunkinSoundPlayMusicParams):Bool {
		if(params.pathsFunction == INST){
			var instPath = "";
			
			try{

				instPath = 'assets/songs/${Paths.formatToSongPath(key)}/Inst.${Paths.SOUND_EXT}';
				#if MODS_ALLOWED
				var modsInstPath = Paths.modFolders('songs/${Paths.formatToSongPath(key)}/Inst.${Paths.SOUND_EXT}');
				var real_modSngPath = NativeFileSystem.getPathLike(modsInstPath);
				#if (mac || ios)
				if(real_modSngPath != null) instPath = haxe.io.Path.join([StorageUtil.getStorageDirectory(),real_modSngPath]);
				#else
				if(real_modSngPath != null) instPath = real_modSngPath;
				#end

				#end
				
				var future = FlxPartialSound.partialLoadFromFile(instPath,params.partialParams.start,params.partialParams.end);
				if(future == null){
					trace('Internal failure loading instrumentals for ${key} "${instPath}"');
					return false;
				}
				future.future.onComplete(function(sound:Sound)
					{
						@:privateAccess{
							if(!Std.isOfType(FlxG.state.subState,FreeplayState)) return;
							var fp = cast (FlxG.state.subState,FreeplayState);

							var cap = fp.grpCapsules.activeSongItems[fp.curSelected];
							if(cap.songData == null || cap.songData.getNativeSongId() != key || fp.busy) return;
						}
						
						trace("Playing preview!");
						FlxG.sound.playMusic(sound,0);
						params.onLoad();
					});
				return true;
			}
		}
		else{
			var targetPath = key+"/"+key;
			if(key == "freakyMenu") targetPath = "freakyMenu";
			FlxG.sound.playMusic(Paths.music(targetPath),params.startingVolume,params.loop);
			if(params.onLoad!= null)params.onLoad();
			return true;
		}
	}
}

 typedef FunkinSoundPlayMusicParams =
 {
   var ?startingVolume:Float;
 
   var ?suffix:String;
 
   var ?overrideExisting:Bool;
 
   var ?restartTrack:Bool;
 
   var ?loop:Bool;
 
   var ?mapTimeChanges:Bool;
 
   var ?pathsFunction:PathsFunction;
 
   var ?partialParams:PartialSoundParams;
 
   var ?onComplete:Void->Void;
   var ?onLoad:Void->Void;
 }

 typedef PartialSoundParams =
{
  var loadPartial:Bool;
  var start:Float;
  var end:Float;
}

enum abstract PathsFunction(String)
{
  var MUSIC;
  var INST;
  var VOICES;
  var SOUND;
}