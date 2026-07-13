package mikolka.funkin;

import flixel.FlxObject;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxPool;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.util.FlxAxes;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.math.FlxMath;

class IntervalShake implements IFlxDestroyable
{
  #if LEGACY_PSYCH
  static var _pool:FlxPool<IntervalShake> = new FlxPool<IntervalShake>(IntervalShake);
  #else
  static var _pool:FlxPool<IntervalShake> = new FlxPool<IntervalShake>(IntervalShake.new);
  #end

  static var _boundObjects:Map<FlxObject, IntervalShake> = new Map<FlxObject, IntervalShake>();

  public static function shake(Object:FlxObject, Duration:Float = 1, Interval:Float = 0.04, StartIntensity:Float = 0, EndIntensity:Float = 0,
      Ease:EaseFunction, ?CompletionCallback:IntervalShake->Void, ?ProgressCallback:IntervalShake->Void):IntervalShake
  {
    if (isShaking(Object))
    {
      return _boundObjects[Object];
    }

    if (Interval <= 0)
    {
      Interval = FlxG.elapsed;
    }

    var shake:IntervalShake = _pool.get();
    shake.start(Object, Duration, Interval, StartIntensity, EndIntensity, Ease, CompletionCallback, ProgressCallback);
    return _boundObjects[Object] = shake;
  }

  public static function isShaking(Object:FlxObject):Bool
  {
    return _boundObjects.exists(Object);
  }

  public static function stopShaking(Object:FlxObject):Void
  {
    var boundShake:IntervalShake = _boundObjects[Object];
    if (boundShake != null)
    {
      boundShake.stop();
    }
  }

  public var object(default, null):FlxObject;

  public var timer(default, null):FlxTimer;

  public var startIntensity(default, null):Float;

  public var endIntensity(default, null):Float;

  public var duration(default, null):Float;

  public var interval(default, null):Float;

  public var axes(default, null):FlxAxes;

  public var initialOffset(default, null):FlxPoint;

  public var completionCallback(default, null):IntervalShake->Void;

  public var progressCallback(default, null):IntervalShake->Void;

  public var ease(default, null):EaseFunction;

  public function destroy():Void
  {
    object = null;
    timer = null;
    ease = null;
    completionCallback = null;
    progressCallback = null;
  }

  function start(Object:FlxObject, Duration:Float = 1, Interval:Float = 0.04, StartIntensity:Float = 0, EndIntensity:Float = 0, Ease:EaseFunction,
      ?CompletionCallback:IntervalShake->Void, ?ProgressCallback:IntervalShake->Void):Void
  {
    object = Object;
    duration = Duration;
    interval = Interval;
    completionCallback = CompletionCallback;
    startIntensity = StartIntensity;
    endIntensity = EndIntensity;
    initialOffset = new FlxPoint(Object.x, Object.y);
    ease = Ease;
    axes = FlxAxes.XY;
    _secondsSinceStart = 0;
    timer = new FlxTimer().start(interval, shakeProgress, Std.int(duration / interval));
  }

  public function stop():Void
  {
    timer.cancel();
    object.x = initialOffset.x;
    object.y = initialOffset.y;
    release();
  }

  function release():Void
  {
    _boundObjects.remove(object);
    _pool.put(this);
  }

  public var _secondsSinceStart(default, null):Float = 0;

  public var scale(default, null):Float = 0;

  function shakeProgress(timer:FlxTimer):Void
  {
    _secondsSinceStart += interval;
    scale = _secondsSinceStart / duration;
    if (ease != null)
    {
      scale = 1 - ease(scale);
    }

    var curIntensity:Float = 0;
    curIntensity = FlxMath.lerp(endIntensity, startIntensity, scale);

    if (axes.x) object.x = initialOffset.x + FlxG.random.float((-curIntensity) * object.width, (curIntensity) * object.width);
    if (axes.y) object.y = initialOffset.y + FlxG.random.float((-curIntensity) * object.width, (curIntensity) * object.width);


    if (progressCallback != null) progressCallback(this);

    if (timer.loops > 0 && timer.loopsLeft == 0)
    {
      object.x = initialOffset.x;
      object.y = initialOffset.y;
      if (completionCallback != null)
      {
        completionCallback(this);
      }

      if (this.timer == timer) release();
    }
  }

  @:keep
  function new() {}
}
