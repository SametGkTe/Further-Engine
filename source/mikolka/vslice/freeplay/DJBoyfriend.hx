package mikolka.vslice.freeplay;

import mikolka.funkin.players.PlayerData.PlayerFreeplayDJData;
import mikolka.compatibility.funkin.FunkinPath as Paths;

import flixel.FlxSprite;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;

class FreeplayDJ extends FlxAtlasSprite
{
  private var currentState:FreeplayDJState = Intro;

  public var onIntroDone:FlxSignal = new FlxSignal();

  public var onIdleEasterEgg:FlxSignal = new FlxSignal();

  var seenIdleEasterEgg:Bool = false;

  static final IDLE_EGG_PERIOD:Float = 60.0;
  static final IDLE_CARTOON_PERIOD:Float = 120.0;

  var timeIdling:Float = 0;

  final playableCharData:PlayerFreeplayDJData;

  public function new(x:Float, y:Float, character:PlayableCharacter)
  {

    var playableChar = character;
    playableCharData = playableChar.getFreeplayDJData();

    super(x, y, playableCharData.getAtlasPath());

    onAnimationFrame.add(function(name, number) {
      if (name == playableCharData.getAnimationPrefix('cartoon'))
      {
        if (number == playableCharData.getCartoonSoundClickFrame())
        {
          FunkinSound.playOnce(Paths.sound('remote_click'));
        }
        if (number == playableCharData.getCartoonSoundCartoonFrame())
        {
          runTvLogic();
        }
      }
    });

    FlxG.debugger.track(this);
    FlxG.console.registerObject("dj", this);

    onAnimationComplete.add(onFinishAnim);

    FlxG.console.registerFunction("freeplayCartoon", function() {
      currentState = Cartoon;
    });
  }

  override public function listAnimations():Array<String>
  {
    var anims:Array<String> = [];
    @:privateAccess
    for (animKey in anim.symbolDictionary)
    {
      anims.push(animKey.name);
    }
    return anims;
  }

  var lowPumpLoopPoint:Int = 4;

  public override function update(elapsed:Float):Void
  {


    switch (currentState)
    {
      case Intro:
        var animPrefix = playableCharData.getAnimationPrefix('intro');
        if (getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, true);
        timeIdling = 0;
      case Idle:
        var animPrefix = playableCharData.getAnimationPrefix('idle');
        if (getCurrentAnimation() != animPrefix)
        {
          playFlashAnimation(animPrefix, true, false, true);
        }
        timeIdling += elapsed;
      case NewUnlock:
        var animPrefix = playableCharData.getAnimationPrefix('newUnlock');
        if (!hasAnimation(animPrefix))
        {
          currentState = Idle;
        }
        if (getCurrentAnimation() != animPrefix)
        {
          playFlashAnimation(animPrefix, true, false, true);
        }
      case Confirm:
        var animPrefix = playableCharData.getAnimationPrefix('confirm');
        if (getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, false);
        timeIdling = 0;
      case FistPumpIntro:
        var animPrefixA = playableCharData.getAnimationPrefix('fistPump');
        var animPrefixB = playableCharData.getAnimationPrefix('loss');

        if (getCurrentAnimation() == animPrefixA)
        {
          var endFrame = playableCharData.getFistPumpIntroEndFrame();
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixA, true, false, false, playableCharData.getFistPumpIntroStartFrame());
          }
        }
        else if (getCurrentAnimation() == animPrefixB)
        {
          trace("Loss Intro");
          var endFrame = playableCharData.getFistPumpIntroBadEndFrame();
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixB, true, false, false, playableCharData.getFistPumpIntroBadStartFrame());
          }
        }
        else
        {
          FlxG.log.warn("Unrecognized animation in FistPumpIntro: " + getCurrentAnimation());
        }

      case FistPump:
        var animPrefixA = playableCharData.getAnimationPrefix('fistPump');
        var animPrefixB = playableCharData.getAnimationPrefix('loss');

        if (getCurrentAnimation() == animPrefixA)
        {
          var endFrame = playableCharData.getFistPumpLoopEndFrame();
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixA, true, false, false, playableCharData.getFistPumpLoopStartFrame());
          }
        }
        else if (getCurrentAnimation() == animPrefixB)
        {
          trace("Loss GYATT");
          var endFrame = playableCharData.getFistPumpLoopBadEndFrame();
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixB, true, false, false, playableCharData.getFistPumpLoopBadStartFrame());
          }
        }
        else
        {
          FlxG.log.warn("Unrecognized animation in FistPump: " + getCurrentAnimation());
        }

      case IdleEasterEgg:
        var animPrefix = playableCharData.getAnimationPrefix('idleEasterEgg');
        if (getCurrentAnimation() != animPrefix)
        {
          onIdleEasterEgg.dispatch();
          playFlashAnimation(animPrefix, false);
          seenIdleEasterEgg = true;
        }
        timeIdling = 0;
      case Cartoon:
        var animPrefix = playableCharData.getAnimationPrefix('cartoon');
        if (animPrefix == null)
        {
          currentState = IdleEasterEgg;
        }
        else
        {
          if (getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, true);
          timeIdling = 0;
        }
      default:
    }

    #if FEATURE_DEBUG_FUNCTIONS
    if (FlxG.keys.pressed.CONTROL)
    {
      if (FlxG.keys.justPressed.LEFT)
      {
        this.offsetX -= FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.RIGHT)
      {
        this.offsetX += FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.UP)
      {
        this.offsetY -= FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.DOWN)
      {
        this.offsetY += FlxG.keys.pressed.ALT ? 0.1 : (FlxG.keys.pressed.SHIFT ? 10.0 : 1.0);
      }

      if (FlxG.keys.justPressed.C)
      {
        currentState = (currentState == Idle ? Cartoon : Idle);
      }
    }
    #end


    super.update(elapsed);
  }

  function onFinishAnim(name:String):Void
  {

    if (name == playableCharData.getAnimationPrefix('intro'))
    {
      if (PlayerRegistry.instance.hasNewCharacter())
      {
        currentState = NewUnlock;
      }
      else
      {
        currentState = Idle;
      }
      onIntroDone.dispatch();
    }
    else if (name == playableCharData.getAnimationPrefix('idle'))
    {    
        if (timeIdling >= IDLE_EGG_PERIOD && !seenIdleEasterEgg) 
        {
          currentState = IdleEasterEgg;
        }
        else if (timeIdling >= IDLE_CARTOON_PERIOD)
        {
          currentState = Cartoon;
        }
    }
    else if (name == playableCharData.getAnimationPrefix('confirm'))
    {
    }
    else if (name == playableCharData.getAnimationPrefix('fistPump'))
    {
      currentState = Idle;
    }
    else if (name == playableCharData.getAnimationPrefix('idleEasterEgg'))
    {
      currentState = Idle;
    }
    else if (name == playableCharData.getAnimationPrefix('loss'))
    {
      currentState = Idle;
    }
    else if (name == playableCharData.getAnimationPrefix('cartoon'))
    {

      var frame:Int = FlxG.random.bool(33) ? playableCharData.getCartoonLoopBlinkFrame() : playableCharData.getCartoonLoopFrame();

      if (FlxG.random.bool(5))
      {
        frame = playableCharData.getCartoonChannelChangeFrame();
      }
      trace('Replay idle: ${frame}');
      playFlashAnimation(playableCharData.getAnimationPrefix('cartoon'), true, false, false, frame);
    }
    else if (name == playableCharData.getAnimationPrefix('newUnlock'))
    {
    }
    else if (name == playableCharData.getAnimationPrefix('charSelect'))
    {
      onCharSelectComplete();
    }
    else
    {
      trace('Finished ${name}');
    }
  }

  public function resetAFKTimer():Void
  {
    timeIdling = 0;
    seenIdleEasterEgg = false;
  }

  public dynamic function onCharSelectComplete():Void
  {
    trace('onCharSelectComplete()');
  }

  var offsetX:Float = 0.0;
  var offsetY:Float = 0.0;

  var cartoonSnd:Null<FunkinSound> = null;

  public var playingCartoon:Bool = false;

  public function runTvLogic()
  {
    if (cartoonSnd == null)
    {
      FunkinSound.playOnce(Paths.sound('tv_on'), 1.0, function() {
        loadCartoon();
      });
    }
    else
    {
      FunkinSound.playOnce(Paths.sound('channel_switch'), 1.0, function() {
        cartoonSnd.destroy();
        loadCartoon();
      });
    }

  }

  function loadCartoon()
  {
    cartoonSnd = FunkinSound.load(Paths.sound(getRandomFlashToon()), 1.0, false, true, true, function() {
      playFlashAnimation(playableCharData.getAnimationPrefix('cartoon'), true, false, false, 60);
    });

    FlxG.sound.music.fadeOut(1.0, 0.1);

    cartoonSnd.time = FlxG.random.float(0, Math.max(cartoonSnd.length - (5 * Constants.MS_PER_SEC), 0.0));
  }
  final cartoonList:Array<String> = openfl.utils.Assets.list().filter(function(path) return path.startsWith("assets/shared/sounds/cartoons/"));

  function getRandomFlashToon():String
  {
    var randomFile = FlxG.random.getObject(cartoonList);

    randomFile = randomFile.replace("assets/shared/sounds/", "");
    randomFile = randomFile.substring(0, randomFile.length - 4);

    return randomFile;
  }

  public function confirm():Void
  {
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = Confirm;
  }

  public function toCharSelect():Void
  {
    if (hasAnimation(playableCharData.getAnimationPrefix('charSelect')))
    {
      currentState = CharSelect;
      var animPrefix = playableCharData.getAnimationPrefix('charSelect');
      playFlashAnimation(animPrefix, true, false, false, 0);
    }
    else
    {
      FlxG.log.warn("Freeplay character does not have 'charSelect' animation!");
      currentState = Confirm;
      onCharSelectComplete();
    }
  }

  public function fistPumpIntro():Void
  {
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPumpIntro;
    var animPrefix = playableCharData.getAnimationPrefix('fistPump');
    playFlashAnimation(animPrefix, true, false, false, playableCharData.getFistPumpIntroStartFrame());
  }

  public function fistPump():Void
  {
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPump;
    var animPrefix = playableCharData.getAnimationPrefix('fistPump');
    playFlashAnimation(animPrefix, true, false, false, playableCharData.getFistPumpLoopStartFrame());
  }

  public function fistPumpLossIntro():Void
  {
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPumpIntro;
    var animPrefix = playableCharData.getAnimationPrefix('loss');
    playFlashAnimation(animPrefix, true, false, false, playableCharData.getFistPumpIntroBadStartFrame());
  }

  public function fistPumpLoss():Void
  {
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPump;
    var animPrefix = playableCharData.getAnimationPrefix('loss');
    playFlashAnimation(animPrefix, true, false, false, playableCharData.getFistPumpLoopBadStartFrame());
  }

  override public function getCurrentAnimation():String
  {
    if (this.anim == null || this.anim.curSymbol == null) return "";
    return this.anim.curSymbol.name;
  }

  public function playFlashAnimation(id:String, Force:Bool = false, Reverse:Bool = false, Loop:Bool = false, Frame:Int = 0):Void
  {
    playAnimation(id, Force, Reverse, Loop, Frame);
    applyAnimOffset();
  }

	function applyAnimOffset()
	{
		var AnimName = getCurrentAnimation();
		var daOffset = playableCharData.getAnimationOffsetsByPrefix(AnimName);

		if (daOffset != null)
			trace('[FreeplayDJ] raw offset = ' + daOffset[0] + ', ' + daOffset[1]);
		else
			trace('[FreeplayDJ] no offset found');

		offset.set(0, 0);
	}

  public override function destroy():Void
  {
    super.destroy();

    if (cartoonSnd != null)
    {
      cartoonSnd.destroy();
      cartoonSnd = null;
    }
  }
}

enum FreeplayDJState
{
  Intro;

  Idle;

  IdleEasterEgg;

  Cartoon;

  Confirm;

  FistPumpIntro;

  FistPump;

  NewUnlock;

  CharSelect;
}
