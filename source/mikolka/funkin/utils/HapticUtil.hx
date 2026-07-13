package mikolka.funkin.utils;

import mikolka.compatibility.VsliceOptions;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
#if mubile
import extension.haptics.Haptic;
#end
class HapticUtil
{
  public static var amplitudeTween:FlxTween;
  public static final hapticsIntensityMultiplier:Float = 1;

  public static var defaultVibrationPreset(get, never):VibrationPreset;

  public static var hapticsAvailable(get, never):Bool;

  public static function vibrate(period:Float = Constants.DEFAULT_VIBRATION_PERIOD, duration:Float = Constants.DEFAULT_VIBRATION_DURATION,
      amplitude:Float = Constants.DEFAULT_VIBRATION_AMPLITUDE, sharpness:Float = Constants.DEFAULT_VIBRATION_SHARPNESS,
      ?targetHapticsModes:Array<HapticsMode>):Void
  {

    if (!HapticUtil.hapticsAvailable) return;

    final hapticsModes:Array<HapticsMode> = targetHapticsModes ?? [HapticsMode.ALL];

    final amplitudeValue = FlxMath.bound(amplitude * hapticsIntensityMultiplier, 0, Constants.MAX_VIBRATION_AMPLITUDE);

    if (period > 0)
    {
      final durations:Array<Float> = [];
      final amplitudes:Array<Float> = [];
      final sharpnesses:Array<Float> = [];

      final durationPeriod:Float = period / 2;

      for (i in 0...Math.ceil(duration / durationPeriod))
      {
        durations[i] = durationPeriod;
        amplitudes[i] = amplitudeValue;
        sharpnesses[i] = sharpness;
      }
      #if mubile
      Haptic.vibratePattern(durations, amplitudes, sharpnesses);
      #end
    }
    else
    {
      #if mubile
      Haptic.vibrateOneShot(duration, amplitudeValue, sharpness);
      #end
    }

  }

  public static function vibrateByPreset(vibrationPreset:VibrationPreset = null):Void
  {
    if (!HapticUtil.hapticsAvailable) return;

    final preset:VibrationPreset = (vibrationPreset != null) ? vibrationPreset : defaultVibrationPreset;

    vibrate(preset.period, preset.duration, preset.amplitude, preset.sharpness);
  }

  public static function increasingVibrate(startAmplitude:Float, targetAmplitude:Float, tweenDuration:Float = 1):Void
  {
    if (!HapticUtil.hapticsAvailable) return;

    if (amplitudeTween != null) amplitudeTween.cancel();

    amplitudeTween = FlxTween.num(startAmplitude, targetAmplitude, tweenDuration,
      {
        onComplete: function(_) {
          final finalAmplitude:Float = targetAmplitude * 2;

          vibrate(Constants.DEFAULT_VIBRATION_PERIOD, Constants.DEFAULT_VIBRATION_DURATION, finalAmplitude);
        }
      }, function(currentAmplitude:Float) {
        vibrate(0, Constants.DEFAULT_VIBRATION_DURATION / 10, currentAmplitude);
      });
  }

  static function get_defaultVibrationPreset():VibrationPreset
  {
    return {
      period: Constants.DEFAULT_VIBRATION_PERIOD,
      duration: Constants.DEFAULT_VIBRATION_DURATION,
      amplitude: Constants.DEFAULT_VIBRATION_AMPLITUDE,
      sharpness: Constants.DEFAULT_VIBRATION_SHARPNESS
    };
  }

  static function get_hapticsAvailable():Bool
  {



    return VsliceOptions.VIBRATION;
  }
}

typedef VibrationPreset =
{
  var period:Float;

  var duration:Float;

  var amplitude:Float;

  var sharpness:Float;
}

enum abstract HapticsMode(Int) from Int to Int
{
  var NONE:Int = 0;

  var NOTES_ONLY:Int = 1;

  var ALL:Int = 2;
}