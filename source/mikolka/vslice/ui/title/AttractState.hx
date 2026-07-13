package mikolka.vslice.ui.title;
#if VIDEOS_ALLOWED
import mikolka.compatibility.ModsHelper;
#if hxCodec
import hxcodec.flixel.FlxVideoSprite;
#elseif hxvlc
import hxvlc.flixel.FlxVideoSprite;
#else
import objects.WebVideoSprite as FlxVideo;
#end
using mikolka.funkin.utils.ArrayTools;
import mikolka.vslice.ui.title.TitleState;


class AttractState extends MusicBeatSubstate
{
  #if html5
  var ATTRACT_VIDEO_PATH:String = Paths.video("commercials/"+FlxG.random.getObject([
    'toyCommercial',
    'kickstarterTrailer',
    'boyfriend everywhere'
  ]));
  #else
   var ATTRACT_VIDEO_PATH:String = '';
  #end

  public function new(video:String = null) {
    if(video != null) ATTRACT_VIDEO_PATH = video;
    super();
  }
  public override function create():Void
  {
    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.destroy();
      FlxG.sound.music = null;
    }

    #if html5
    trace('Playing web video ${ATTRACT_VIDEO_PATH}');
    playVideoHTML5(ATTRACT_VIDEO_PATH);
    #end

    #if (hxvlc || hxCodec)
    if (ATTRACT_VIDEO_PATH == '') ATTRACT_VIDEO_PATH = ModsHelper.collectVideos();
    trace('Playing native video ${ATTRACT_VIDEO_PATH}');
    playVideoNative(ATTRACT_VIDEO_PATH);
    #end
  }

  #if html5
  var vid:FlxVideo;

  function playVideoHTML5(filePath:String):Void
  {
    vid = new FlxVideo();
    vid.netStream.play(filePath);
    if (vid != null)
    {
      vid.zIndex = 0;

      vid.finishCallback = onAttractEnd;

      add(vid);
    }
    else
    {
      trace('ALERT: Video is null! Could not play cutscene!');
    }
  }
  #end

  #if (VIDEOS_ALLOWED && sys)
  var vid:FlxVideoSprite;

  function playVideoNative(filePath:String):Void
  {
    vid = new FlxVideoSprite(0, 0);

    if (vid != null)
    {
      vid.bitmap.onEndReached.add(onAttractEnd);

      #if hxvlc
      vid.bitmap.onFormatSetup.add(function()
      #else
      vid.bitmap.onTextureSetup.add(function()
      #end
        {
          vid.setGraphicSize(FlxG.width);
          vid.updateHitbox();
          vid.screenCenter();
        });

      add(vid);
      #if hxvlc
      vid.load(filePath, null);
      vid.play();
      #else
      vid.play(filePath, false);
      #end
    }
    else
    {
      trace('ALERT: Video is null! Could not play cutscene!');
    }
  }
  #end

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    #if LEGACY_PSYCH
    if (TouchUtil.justPressed || FlxG.keys.justPressed.ANY && 
      !FlxG.keys.anyJustPressed(InitState.muteKeys) && 
      !FlxG.keys.anyJustPressed(InitState.volumeDownKeys) && 
      !FlxG.keys.anyJustPressed(InitState.volumeUpKeys))
    #else
    if (TouchUtil.justPressed || FlxG.keys.justPressed.ANY && !controls.justPressed("volume_up") && !controls.justPressed("volume_down") && !controls.justPressed("volume_mute"))
    #end
    {
      onAttractEnd();
    }
  }

  function onAttractEnd():Void
  {
    #if html5
    if (vid != null)
    {
      remove(vid);
    }
    #end

    #if (hxvlc || hxCodec)
    if (vid != null)
      {
        vid.stop();
        remove(vid);
      }
    #end

    #if (html5 || hxCodec)
    vid.destroy();
    vid = null;
    #end
    if(FlxG.state.subState == this){
      close();
    }
    else{
      FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
      #if LEGACY_PSYCH
      FlxG.switchState(new TitleState());
      #else
      FlxG.switchState(() -> new TitleState());
      #end
    }
  }
}
#end