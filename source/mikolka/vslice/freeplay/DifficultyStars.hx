package mikolka.vslice.freeplay;

import mikolka.compatibility.VsliceOptions;
import shaders.HSVShader;
import mikolka.vslice.freeplay.obj.FreeplayFlames;
import flixel.group.FlxSpriteGroup;

class DifficultyStars extends FlxSpriteGroup
{

  var curDifficulty(default, set):Int = 0;

  public var difficulty(default, set):Int = 1;

  public var stars:FlxAnimate;

  public var flames:FreeplayFlames;

  var hsvShader:HSVShader;

  public function new(x:Float, y:Float)
  {
    super(x, y);

    
    
    flames = new FreeplayFlames(0, 0);
    add(flames);
    
    stars = new FlxAtlasSprite(0, 0, "freeplay/freeplayStars");

    stars.anim.play("diff stars");
    add(stars);
    if(VsliceOptions.SHADERS){

      hsvShader = new HSVShader();
      stars.shader = hsvShader;
      
      for (memb in flames.members)
        memb.shader = hsvShader;
    }
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (curDifficulty < 15 && stars.anim.curFrame >= (curDifficulty + 1) * 100)
    {
      stars.anim.play("diff stars", true, false, curDifficulty * 100);
    }
  }

  function set_difficulty(value:Int):Int
  {
    difficulty = value;

    if (difficulty <= 0)
    {
      difficulty = 0;
      curDifficulty = 15;
    }
    else if (difficulty <= 15)
    {
      difficulty = value;
      curDifficulty = difficulty - 1;
    }
    else
    {
      difficulty = 15;
      curDifficulty = difficulty - 1;
    }

    flameCheck();

    return difficulty;
  }

  public function flameCheck():Void
  {
    if (difficulty > 10) flames.flameCount = difficulty - 10;
    else
      flames.flameCount = 0;
  }

  function set_curDifficulty(value:Int):Int
  {
    curDifficulty = value;
    if (curDifficulty == 15)
    {
      stars.anim.play("diff stars", true, false, 1500);
      stars.anim.pause();
    }
    else
    {
      stars.anim.curFrame = Std.int(curDifficulty * 100);
      stars.anim.play("diff stars", true, false, curDifficulty * 100);
    }

    return curDifficulty;
  }
}
