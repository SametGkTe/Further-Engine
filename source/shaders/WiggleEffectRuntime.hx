package shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.Assets;

enum WiggleEffectType
{
  DREAMY; 
  WAVY; 
  HEAT_WAVE_HORIZONTAL; 
  HEAT_WAVE_VERTICAL; 
  FLAG; 
}

class WiggleEffectRuntime extends FlxRuntimeShader
{
  public static function getEffectTypeId(v:WiggleEffectType):Int
  {
    return WiggleEffectType.getConstructors().indexOf(Std.string(v));
  }

  public var effectType(default, set):WiggleEffectType = DREAMY;

  function set_effectType(v:WiggleEffectType):WiggleEffectType
  {
    this.setInt('effectType', getEffectTypeId(v));
    return effectType = v;
  }

  public var waveSpeed(default, set):Float = 0;

  function set_waveSpeed(v:Float):Float
  {
    this.setFloat('uSpeed', v);
    return waveSpeed = v;
  }

  public var waveFrequency(default, set):Float = 0;

  function set_waveFrequency(v:Float):Float
  {
    this.setFloat('uFrequency', v);
    return waveFrequency = v;
  }

  public var waveAmplitude(default, set):Float = 0;

  function set_waveAmplitude(v:Float):Float
  {
    this.setFloat('uWaveAmplitude', v);
    return waveAmplitude = v;
  }

  var time(default, set):Float = 0;

  function set_time(v:Float):Float
  {
    this.setFloat('uTime', v);
    return time = v;
  }

  public function new(speed:Float, freq:Float, amplitude:Float, ?effect:WiggleEffectType = DREAMY):Void
  {
    super(Assets.getText(Paths.shaderFragment('wiggle')));

    this.waveSpeed = speed;
    this.waveFrequency = freq;
    this.waveAmplitude = amplitude;
    this.effectType = effect;
  }

  public function update(elapsed:Float)
  {
    this.time += elapsed;
  }
}
