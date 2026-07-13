package mikolka.funkin;

import mikolka.compatibility.VsliceOptions;
import flixel.util.FlxSignal.FlxTypedSignal;
import flxanimate.FlxAnimate.Settings;
import mikolka.compatibility.ModsHelper;
import flixel.graphics.frames.FlxFrame;
import flixel.system.FlxAssets.FlxGraphicAsset;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.math.FlxPoint;
import flxanimate.animate.FlxKeyFrame;

class FlxAtlasSprite extends PsychFlxAnimate
{
  public static final ANIMATION_OBJECTS = new Map<String,Dynamic>();

  static final SETTINGS:Settings =
    {
      FrameRate: 24.0,
      Reversed: false,
      ShowPivot: false,
      Antialiasing: true,
      ScrollFactor: null,
    };

  public var onAnimationFrame:FlxTypedSignal<String->Int->Void> = new FlxTypedSignal();

  public var onAnimationComplete:FlxTypedSignal<String->Void> = new FlxTypedSignal();

  var currentAnimation:String;

  var canPlayOtherAnims:Bool = true;

  public function new(x:Float, y:Float, ?path:String, ?settings:Settings)
  {
    if (settings == null) settings = SETTINGS;
    SETTINGS.Antialiasing = VsliceOptions.ANTIALIASING; 
    if (path == null)
    {
    }
    else if (path.startsWith("assets") || path.startsWith("mods")){
      throw '$path is an absolute path. This is discouraged!';
    }


    super(x, y, path, settings);

    if (this.anim.stageInstance == null && path != null)
    {
      throw 'FlxAtlasSprite not initialized properly. Are you sure the path (${path}) exists?';
    }

    onAnimationComplete.add(cleanupAnimation);

    if (path != null)
    {
      this.anim.play('');
      this.anim.pause();
    }

    this.anim.onComplete.add(_onAnimationComplete);
    this.anim.onFrame.add(_onAnimationFrame);
  }
  override function loadAtlas(path:String) {
      Paths.loadAnimateAtlas(this,path,null,ANIMATION_OBJECTS.get(path));
  }
  public function listAnimations():Array<String>
  {
    var mainSymbol = this.anim.symbolDictionary[this.anim.stageInstance.symbol.name];
    if (mainSymbol == null)
    {
      FlxG.log.error('FlxAtlasSprite does not have its main symbol!');
      return [];
    }
    return mainSymbol.getFrameLabels().map(keyFrame -> keyFrame.name).filter(s -> s != null);
  }

  public function hasAnimation(id:String):Bool
  {
    return getLabelIndex(id) != -1 || anim.symbolDictionary.exists(id);
  }

  public function getCurrentAnimation():String
  {
    return this.currentAnimation;
  }

  var _completeAnim:Bool = false;

  var fr:FlxKeyFrame = null;

  var looping:Bool = false;

  public var ignoreExclusionPref:Array<String> = [];

  public function playAnimation(id:String, restart:Bool = false, ignoreOther:Bool = false, loop:Bool = false, startFrame:Int = 0):Void
  {
    if ((!canPlayOtherAnims))
    {
      if (this.currentAnimation == id && restart) {}
      else if (ignoreExclusionPref != null && ignoreExclusionPref.length > 0)
      {
        var detected:Bool = false;
        for (entry in ignoreExclusionPref)
        {
          if (id.startsWith(entry))
          {
            detected = true;
            break;
          }
        }
        if (!detected) return;
      }
      else
        return;
    }

    if (anim == null) return;

    if (id == null || id == '') id = this.currentAnimation;

    if (this.currentAnimation == id && !restart)
    {
      if (!anim.isPlaying)
      {
        if (fr != null) anim.curFrame = fr.index + startFrame;
        else
          anim.curFrame = startFrame;

        anim.resume();
      }

      return;
    }
    else if (!hasAnimation(id))
    {
      trace('Animation ' + id + ' not found');
      return;
    }

    this.currentAnimation = id;
    anim.onComplete.removeAll();
    anim.onComplete.add(function() {
      _onAnimationComplete();
    });

    looping = loop;

    if (ignoreOther) canPlayOtherAnims = false;

    if ((id == null || id == "") || this.anim.symbolDictionary.exists(id) || (this.anim.getByName(id) != null))
    {
      this.anim.play(id, restart, false, startFrame);

      this.currentAnimation = anim.curSymbol.name;

      fr = null;
    }
    if (getFrameLabelNames().indexOf(id) != -1)
    {
      goToFrameLabel(id);
      fr = anim.getFrameLabel(id);
      anim.curFrame += startFrame;
    }
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);
  }

  public function isAnimationFinished():Bool
  {
    return this.anim.finished;
  }

  public function isLoopComplete():Bool
  {
    if (this.anim == null) return false;
    if (!this.anim.isPlaying) return false;

    if (fr != null) return (anim.reversed && anim.curFrame < fr.index || !anim.reversed && anim.curFrame >= (fr.index + fr.duration));

    return (anim.reversed && anim.curFrame == 0 || !(anim.reversed) && (anim.curFrame) >= (anim.length - 1));
  }

  public function stopAnimation():Void
  {
    if (this.currentAnimation == null) return;

    this.anim.removeAllCallbacksFrom(getNextFrameLabel(this.currentAnimation));

    goToFrameIndex(0);
  }

  function addFrameCallback(label:String, callback:Void->Void):Void
  {
    var frameLabel = this.anim.getFrameLabel(label);
    frameLabel.add(callback);
  }

  function goToFrameLabel(label:String):Void
  {
    this.anim.goToFrameLabel(label);
  }

  function getFrameLabelNames(?layer:haxe.extern.EitherType<Int, String> = null)
  {
    var labels = this.anim.getFrameLabels(layer);
    var array = [];
    for (label in labels)
    {
      array.push(label.name);
    }

    return array;
  }

  function getNextFrameLabel(label:String):String
  {
    return listAnimations()[(getLabelIndex(label) + 1) % listAnimations().length];
  }

  function getLabelIndex(label:String):Int
  {
    return listAnimations().indexOf(label);
  }

  function goToFrameIndex(index:Int):Void
  {
    this.anim.curFrame = index;
  }

  public function cleanupAnimation(_:String):Void
  {
    canPlayOtherAnims = true;
    this.anim.pause();
  }

  function _onAnimationFrame(frame:Int):Void
  {
    if (currentAnimation != null)
    {
      onAnimationFrame.dispatch(currentAnimation, frame);

      if (isLoopComplete())
      {
        anim.pause();
        _onAnimationComplete();

        if (looping)
        {
          anim.curFrame = (fr != null) ? fr.index : 0;
          anim.resume();
        }
        else if (fr != null && anim.curFrame != anim.length - 1)
        {
          anim.curFrame--;
        }
      }
    }
  }

  function _onAnimationComplete():Void
  {
    if (currentAnimation != null)
    {
      onAnimationComplete.dispatch(currentAnimation);
    }
    else
    {
      onAnimationComplete.dispatch('');
    }
  }

  var prevFrames:Map<Int, FlxFrame> = [];

  public function replaceFrameGraphic(index:Int, ?graphic:FlxGraphicAsset):Void
  {
    if (graphic == null) 
    {
      var prevFrame:Null<FlxFrame> = prevFrames.get(index);
      if (prevFrame == null) return;

      prevFrame.copyTo(frames.getByIndex(index));
      return;
    }

    var prevFrame:FlxFrame = prevFrames.get(index) ?? frames.getByIndex(index).copyTo();
    prevFrames.set(index, prevFrame);

    var frame = FlxG.bitmap.add(graphic).imageFrame.frame;
    frame.copyTo(frames.getByIndex(index));

    @:privateAccess
    if (true)
    {
      var frame = frames.getByIndex(index);
      frame.tileMatrix[0] = prevFrame.frame.width / frame.frame.width;
      frame.tileMatrix[3] = prevFrame.frame.height / frame.frame.height;
    }
  }

  public function getBasePosition():Null<FlxPoint>
  {
    var instancePos = new FlxPoint(anim.curInstance.matrix.tx, anim.curInstance.matrix.ty);
    var firstElement = anim.curSymbol.timeline?.get(0)?.get(0)?.get(0);
    if (firstElement == null) return instancePos;
    var firstElementPos = new FlxPoint(firstElement.matrix.tx, firstElement.matrix.ty);

    return instancePos + firstElementPos;
  }

  public function getPivotPosition():Null<FlxPoint>
  {
    return anim.curInstance.symbol.transformationPoint;
  }

  public override function destroy():Void
  {
    for (prevFrameId in prevFrames.keys())
    {
      replaceFrameGraphic(prevFrameId, null);
    }

    super.destroy();
  }
}
