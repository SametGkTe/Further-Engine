package mikolka.funkin.utils;

class MathUtil
{
  public static final E:Float = 2.71828182845904523536;

  @:deprecated('Use smoothLerp instead.')
  public static function coolLerp(base:Float, target:Float, ratio:Float,wobble:Bool = true):Float
  {
    var lerp = cameraLerp(ratio);
    if(!wobble) lerp = FlxMath.bound(lerp,0,1);
    return base + lerp * (target - base);
  }

  @:deprecated('Use smoothLerp instead')
  public static function cameraLerp(lerp:Float):Float
  {
    return lerp * (FlxG.elapsed / (1 / 60));
  }

  public static function logBase(base:Float, value:Float):Float
  {
    return Math.log(value) / Math.log(base);
  }

  public static function easeInOutCirc(x:Float):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    var result:Float = (x < 0.5) ? (1 - Math.sqrt(1 - 4 * x * x)) / 2 : (Math.sqrt(1 - 4 * (1 - x) * (1 - x)) + 1) / 2;
    return (result == Math.NaN) ? 1.0 : result;
  }

  public static function easeInOutBack(x:Float, ?c:Float = 1.70158):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    var result:Float = (x < 0.5) ? (2 * x * x * ((c + 1) * 2 * x - c)) / 2 : (1 - 2 * (1 - x) * (1 - x) * ((c + 1) * 2 * (1 - x) - c)) / 2;
    return (result == Math.NaN) ? 1.0 : result;
  }

  public static function easeInBack(x:Float, ?c:Float = 1.70158):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    return (1 + c) * x * x * x - c * x * x;
  }

  public static function easeOutBack(x:Float, ?c:Float = 1.70158):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2);
  }

  public static function lerp(base:Float, target:Float, progress:Float):Float
  {
    return base + progress * (target - base);
  }

  public static function smoothLerp(current:Float, target:Float, elapsed:Float, duration:Float, precision:Float = 1 / 100):Float
  {

    if (current == target) return target;

    var result:Float = lerp(current, target, 1 - Math.pow(precision, elapsed / duration));

    if (Math.abs(result - target) < (precision * target)) result = target;

    return result;
  }
  public static function gcd(m:Int, n:Int):Int
  {
    m = Math.floor(Math.abs(m));
    n = Math.floor(Math.abs(n));
    var t;
    do
    {
      if (n == 0) return m;
      t = m;
      m = n;
      n = t % m;
    }
    while (true);
  }
}
