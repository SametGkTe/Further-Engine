package mikolka.vslice.charSelect;


import mikolka.funkin.FlxAtlasSprite;
class CharSelectPlayer extends FlxAtlasSprite 
{
  public function new(x:Float, y:Float)
  {
    super(x, y, null);

    onAnimationComplete.add(function(animLabel:String) { 
      switch (animLabel)
      {
        case "slidein":
          if (hasAnimation("slidein idle point"))
          {
            playAnimation("slidein idle point", true, false, false);
          }
          else
          {
            playAnimation("idle", true, false, false);
          }
        case "deselect":
          playAnimation("deselect loop start", true, false, true);

        case "slidein idle point", "cannot select Label", "unlock":
          playAnimation("idle", true, false, false);
        case "idle":
          trace('Waiting for onBeatHit');
      }
    });
  }

  public function onBeatHit():Void
  {
    if (getCurrentAnimation() == "idle")
    {
      playAnimation("idle", true, false, false);
    }
  };

  public function updatePosition(str:String)
  {
    switch (str)
    {
      case "bf":
        x = 0;
        y = 0;
      case "pico":
        x = 0;
        y = 0;
      case "random":
    }
  }

  public function switchChar(str:String)
  {
    switch str
    {
      default:
        loadAtlas("charSelect/" + str + "Chill");
    }

    playAnimation("slidein", true, false, false);

    updateHitbox();

    updatePosition(str);
  }

}
