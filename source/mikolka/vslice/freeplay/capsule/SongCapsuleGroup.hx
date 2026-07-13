package mikolka.vslice.freeplay.capsule;

import mikolka.vslice.freeplay.capsule.SongMenuItem.SongCapsuleAnim;
import mikolka.vslice.freeplay.capsule.CustomAnimControl;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxSignal.FlxTypedSignal;
import mikolka.compatibility.freeplay.FreeplaySongData;
import mikolka.funkin.freeplay.FreeplayStyle;

class SongCapsuleGroup extends FlxTypedGroup<SongMenuItem> {

    @:allow(mikolka.vslice.freeplay.capsule.CapsuleNumber)
    static var BIG_NUMBER_FRAMES:FlxAtlasFrames;
    @:allow(mikolka.vslice.freeplay.capsule.CapsuleNumber)
    static var SMALL_NUMBER_FRAMES:FlxAtlasFrames;
    
    public final onRandomSelected:FlxTypedSignal<SongMenuItem -> Void> = new FlxTypedSignal<SongMenuItem -> Void>();
    public final onSongSelected:FlxTypedSignal<SongMenuItem -> Void> = new FlxTypedSignal<SongMenuItem -> Void>();
	final randomCapsule:SongMenuItem;

	public final activeSongItems:Array<SongMenuItem> = new Array<SongMenuItem>();

    var styleData:FreeplayStyle;
    public function new(styleData:FreeplayStyle) {
        super();
        this.styleData = styleData;
		if (this.styleData == null)
			trace('[SongCapsuleGroup] WARNING: styleData is null!');
		randomCapsule = new SongMenuItem(FlxG.width,0,styleData);
		randomCapsule.onConfirm = function()
		{
			onRandomSelected.dispatch(randomCapsule);
		};
		randomCapsule.applySongData(null);
		randomCapsule.alpha = 0;
		randomCapsule.songText.visible = false;
		randomCapsule.hsvShader = SongMenuItem.static_hsvShader;

		add(randomCapsule);

        BIG_NUMBER_FRAMES = Paths.getSparrowAtlas('freeplay/freeplayCapsule/bignumbers');
        SMALL_NUMBER_FRAMES = Paths.getSparrowAtlas('freeplay/freeplayCapsule/smallnumbers');
    }


    override function destroy() {
        BIG_NUMBER_FRAMES = null;
        SMALL_NUMBER_FRAMES = null;
        super.destroy();
    }

    public function updateSongDifficulties(currentDifficulty:String) {
			for (songCapsule in activeSongItems)
			{
				if (songCapsule == null)
					continue;
				if (songCapsule.songData != null)
				{
					songCapsule.songData.currentDifficulty = currentDifficulty;
					songCapsule.refreshDisplayDifficulty();
				}
				else
				{
					songCapsule.applySongData(null);
				}
			}
    }
	public function generateFullSongList(songList:Array<Null<FreeplaySongData>>,currentDifficulty:String,animation:SongCapsuleAnim,randomAnimation:SongCapsuleAnim):Void
	{
		
		for (cap in members)
		{
			if(cap.songData == null) continue; 
			cap.songText.resetText();
			cap.kill();
		}
		activeSongItems.clear();
		var recycledSongCards = findSongItems(songList);

		randomCapsule.initPosition(FlxG.width, 0);
		randomCapsule.y = randomCapsule.intendedY(1) + 10;
		randomCapsule.ID = 0;
		randomCapsule.targetPos.x = randomCapsule.x;
		randomCapsule.setCapsuleAnimation(randomAnimation);
		
		activeSongItems.push(randomCapsule);
		add(randomCapsule);

		for (i in 0...songList.length)
		{
			var tempSong = songList[i];
			if (tempSong == null)
				continue;

			tempSong.currentDifficulty = currentDifficulty;

			var funnyMenu:SongMenuItem = recycledSongCards.get(tempSong);
			if(funnyMenu == null){
				funnyMenu = recycle(SongMenuItem,() ->{
					return new SongMenuItem(FlxG.width,0,styleData);
				});
				funnyMenu.initPosition(FlxG.width,0);
				funnyMenu.applySongData(tempSong);
				add(funnyMenu); 
			}
			else{
				funnyMenu.refreshDisplayDifficulty();
			}
			funnyMenu.onConfirm = function()
			{
				onSongSelected.dispatch(funnyMenu);
			};
			funnyMenu.targetPos.x = funnyMenu.x; 
			funnyMenu.y = funnyMenu.intendedY(i + 1) + 10; 
			funnyMenu.ID = i;
			funnyMenu.capsule.alpha = 0.5;
			funnyMenu.songText.visible = false;
			funnyMenu.hsvShader = SongMenuItem.static_hsvShader;
			funnyMenu.checkClip();
			
			funnyMenu.setCapsuleAnimation(animation);

			activeSongItems.push(funnyMenu);
			
		}
	}

	inline public function setInitialAnimPosition() {
		for (card in activeSongItems)
			card.setCapsuleAnimInitPosition();
	}

	function findSongItems(songData:Array<FreeplaySongData>):Map<FreeplaySongData,Null<SongMenuItem>> {
		var foundSongItem = new Map<FreeplaySongData,Null<SongMenuItem>>();
		forEachDead(tomb ->{
			if(songData.contains(tomb.songData) && !foundSongItem.exists(tomb.songData)){
				tomb.revive();
				foundSongItem.set(tomb.songData,tomb);
			}
		});
		return foundSongItem;
	}
}
