package mikolka.vslice.components;

import mikolka.compatibility.funkin.FunkinControls;
import mikolka.vslice.components.crash.UserErrorSubstate;
import mikolka.compatibility.VsliceOptions;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import flixel.addons.util.FlxAsyncLoop;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.events.MouseEvent;
import flixel.addons.plugin.screengrab.FlxScreenGrab;

typedef ScreenshotPluginParams =
{
  ?region:Rectangle,
  flashColor:Null<FlxColor>,
};

class ScreenshotPlugin extends FlxBasic
{
  public static var instance:ScreenshotPlugin = null;

  public static final SCREENSHOT_FOLDER = 'screenshots';

  var region:Null<Rectangle>;

  public static var flashColor(default, set):Int = 0xFFFFFFFF;

  public static function set_flashColor(v:Int):Int
  {
    flashColor = v;
    if (instance != null && instance.flashBitmap != null) instance.flashBitmap.bitmapData = new BitmapData(lastWidth, lastHeight, true, v);
    return flashColor;
  }

  public var onPreScreenshot(default, null):FlxSignal;

  public var onPostScreenshot(default, null):FlxTypedSignal<Bitmap->Void>;

  private static var lastWidth:Int;
  private static var lastHeight:Int;
  private static var HIDE_MOUSE:Bool = false;
  private static var PREVIEW:Bool = true;
  private static var PREVIEW_ONSAVE:Bool = true;
  private static var SAVE_FORMAT:String = "png";

  var flashSprite:Sprite;
  var flashBitmap:Bitmap;
  var previewSprite:Sprite;
  var shotPreviewBitmap:Bitmap;
  var outlineBitmap:Bitmap;

  var wasMouseHidden:Bool = false; 
  var wasMouseShown:Bool = false; 
  var screenshotTakenFrame:Int = 0;

  var screenshotBeingSpammed:Bool = false;

  var screenshotSpammedTimer:FlxTimer;

  var screenshotBuffer:Array<Bitmap> = [];
  var screenshotNameBuffer:Array<String> = [];

  var unsavedScreenshotBuffer:Array<Bitmap> = [];
  var unsavedScreenshotNameBuffer:Array<String> = [];

  var stateChanging:Bool = false;
  var noSavingScreenshots:Bool = false;

  var flashTween:FlxTween;

  var previewFadeInTween:FlxTween;
  var previewFadeOutTween:FlxTween;

  var asyncLoop:FlxAsyncLoop;

  public function new(params:ScreenshotPluginParams)
  {
    super();

    if (instance != null)
    {
      destroy();
      return;
    }

    instance = this;

    lastWidth = FlxG.width;
    lastHeight = FlxG.height;

    flashSprite = new Sprite();
    flashSprite.alpha = 0;
    flashBitmap = new Bitmap(new BitmapData(lastWidth, lastHeight, true, params.flashColor));
    flashSprite.addChild(flashBitmap);

    previewSprite = new Sprite();
    previewSprite.alpha = 0;

    outlineBitmap = new Bitmap(new BitmapData(Std.int(lastWidth / 5) + 10, Std.int(lastHeight / 5) + 10, true, 0xFFFFFFFF));
    outlineBitmap.x = 5;
    outlineBitmap.y = 5;
    previewSprite.addChild(outlineBitmap);

    shotPreviewBitmap = new Bitmap();
    shotPreviewBitmap.scaleX /= 5;
    shotPreviewBitmap.scaleY /= 5;

    previewSprite.addChild(shotPreviewBitmap);
    #if FLX_NO_DEBUG 
    FlxG.stage.addChild(flashSprite);
    #end

    region = params.region ?? null;
    flashColor = params.flashColor;

    onPreScreenshot = new FlxTypedSignal<Void->Void>();
    onPostScreenshot = new FlxTypedSignal<Bitmap->Void>();
    FlxG.signals.gameResized.add(this.resizeBitmap);
    FlxG.signals.preStateSwitch.add(this.saveUnsavedBufferedScreenshots);
    FlxG.signals.postStateSwitch.add(this.postStateSwitch);

  }

  public override function update(elapsed:Float):Void
  {
    if (asyncLoop != null)
    {
      if (!asyncLoop.started)
      {
        asyncLoop.start();
      }
      else
      {
        if (asyncLoop.finished)
        {
          if (screenshotBuffer != [])
          {
            trace("finished processing screenshot buffer");
            screenshotBuffer = [];
            screenshotNameBuffer = [];
          }
          asyncLoop.kill();
          asyncLoop.destroy();
          asyncLoop = null;
        }
      }
    }
    super.update(elapsed);

    if (hasPressedScreenshot() && screenshotTakenFrame == 0)
    {
      if (FlxG.keys.pressed.SHIFT)
      {
        openScreenshotsFolder();
        return; 
      }
      if (HIDE_MOUSE && !wasMouseHidden && FlxG.mouse.visible)
      {
        wasMouseHidden = true;
        FlxG.mouse.visible = false;
      }
      for (sprite in [flashSprite, previewSprite])
      {
        FlxTween.cancelTweensOf(sprite);
        sprite.alpha = 0;
      }
      if (screenshotSpammedTimer == null || screenshotSpammedTimer.finished == true)
      {
        screenshotSpammedTimer = new FlxTimer().start(1, function(_) {
          screenshotBeingSpammed = false;
          if (screenshotBuffer[0] != null) saveBufferedScreenshots(screenshotBuffer, screenshotNameBuffer);
          if (!PREVIEW && wasMouseHidden && !FlxG.mouse.visible)
          {
            wasMouseHidden = false;
            FlxG.mouse.visible = true;
          }
        });
      }
      else 
      {
        screenshotBeingSpammed = true;
        screenshotSpammedTimer.reset(1);
      }
      FlxG.stage.removeChild(previewSprite);
      screenshotTakenFrame++;
    }
    else if (screenshotTakenFrame > 1)
    {
      screenshotTakenFrame = 0;
      capture(); 
    }
    else if (screenshotTakenFrame > 0)
    {
      screenshotTakenFrame++;
    }
  }

  public static function initialize():Void
  {
    #if LEGACY_PSYCH FlxG.plugins.add
    #else FlxG.plugins.addPlugin
    #end 
    (new ScreenshotPlugin(
      {
        flashColor: VsliceOptions.FLASHBANG ? FlxColor.WHITE : null, 
      }));
    
  }

  public function hasPressedScreenshot():Bool
  {
    return FunkinControls.SCREENSHOT && !noSavingScreenshots;
  }

  public function updateFlashColor():Void
  {
    VsliceOptions.FLASHBANG ? set_flashColor(FlxColor.WHITE) : null;
  }

  private function resizeBitmap(width:Int, height:Int)
  {
    lastWidth = width;
    lastHeight = height;
    flashBitmap.bitmapData = new BitmapData(lastWidth, lastHeight, true, flashColor);
    outlineBitmap.bitmapData = new BitmapData(Std.int(lastWidth / 5) + 10, Std.int(lastHeight / 5) + 10, true, 0xFFFFFFFF);
  }

  public function capture():Void
  {
    onPreScreenshot.dispatch();

    var shot = new Bitmap(BitmapData.fromImage(FlxG.stage.window.readPixels()));
    if (screenshotBeingSpammed == true)
    {
      if (screenshotBuffer.length < 15)
      {
        screenshotBuffer.push(shot);
        screenshotNameBuffer.push('screenshot-${DateUtil.generateTimestamp()}');

        unsavedScreenshotBuffer.push(shot);
        unsavedScreenshotNameBuffer.push('screenshot-${DateUtil.generateTimestamp()}');
      }
      else
      {
        noSavingScreenshots = true;
        screenshotBuffer = [];
        screenshotNameBuffer = [];
        UserErrorSubstate.makeMessage("Too many screenshots!",
          "You've tried taking more than 15 screenshots at a time. Give the game a funkin break! Jeez.\n\n\nIf you wanted those screenshots, well too bad!");
        FlxG.state.subStateClosed.addOnce(state -> {
            noSavingScreenshots = false;
        });

      }
      showCaptureFeedback();
      if (wasMouseHidden && !FlxG.mouse.visible && VsliceOptions.FLASHBANG) 
      {
        wasMouseHidden = false;
        FlxG.mouse.visible = true;
      }
      if (!PREVIEW_ONSAVE) showFancyPreview(shot);
    }
    else
    {
      saveScreenshot(shot, 'screenshot-${DateUtil.generateTimestamp()}', 1, false);
      showCaptureFeedback();
      if (wasMouseHidden && !FlxG.mouse.visible)
      {
        wasMouseHidden = false;
        FlxG.mouse.visible = true;
      }
      if (!PREVIEW_ONSAVE) showFancyPreview(shot);
    }
    onPostScreenshot.dispatch(shot);
  }

  final CAMERA_FLASH_DURATION = 0.25;

  function showCaptureFeedback():Void
  {
    if (stateChanging) return; 
    flashSprite.alpha = 1;
    FlxTween.tween(flashSprite, {alpha: 0}, 0.15);

    FlxG.sound.play(Paths.sound('screenshot'), 1.0);
  }

  static final PREVIEW_INITIAL_DELAY = 0.25; 
  static final PREVIEW_FADE_IN_DURATION = 0.3; 
  static final PREVIEW_FADE_OUT_DELAY = 1.25; 
  static final PREVIEW_FADE_OUT_DURATION = 0.3; 

  function showFancyPreview(shot:Bitmap):Void
  {
    if (!PREVIEW || screenshotBeingSpammed && !VsliceOptions.FLASHBANG || stateChanging) return; 
    shotPreviewBitmap.bitmapData = shot.bitmapData;
    shotPreviewBitmap.x = outlineBitmap.x + 5;
    shotPreviewBitmap.y = outlineBitmap.y + 5;

    shotPreviewBitmap.width = outlineBitmap.width - 10;
    shotPreviewBitmap.height = outlineBitmap.height - 10;

    FlxG.stage.removeChild(previewSprite);


    if (!wasMouseShown && !wasMouseHidden && !FlxG.mouse.visible)
    {
      wasMouseShown = true;
      FlxG.mouse.visible = true;
    }

    var changingAlpha:Bool = false;
    var targetAlpha:Float = 1;

    var onHover = function(e:MouseEvent) {
      if (!changingAlpha) e.target.alpha = 0.6;
      targetAlpha = 0.6;
    };

    var onHoverOut = function(e:MouseEvent) {
      if (!changingAlpha) e.target.alpha = 1;
      targetAlpha = 1;
    }

    previewSprite.buttonMode = true;
    previewSprite.addEventListener(MouseEvent.MOUSE_DOWN, previewSpriteOpenScreenshotsFolder);
    previewSprite.addEventListener(MouseEvent.MOUSE_MOVE, onHover);
    previewSprite.addEventListener(MouseEvent.MOUSE_OUT, onHoverOut);

    FlxTween.cancelTweensOf(previewSprite); 
    FlxG.stage.addChild(previewSprite);
    previewSprite.alpha = 0.0;
    previewSprite.y -= 10;
    if (previewSprite.hitTestPoint(previewSprite.mouseX, previewSprite.mouseY)) targetAlpha = 0.6;
    new FlxTimer().start(PREVIEW_INITIAL_DELAY, function(_) {
      changingAlpha = true;
      FlxTween.tween(previewSprite, {alpha: targetAlpha, y: 0}, PREVIEW_FADE_IN_DURATION,
        {
          ease: FlxEase.quartOut,
          onComplete: function(_) {
            changingAlpha = false;
            new FlxTimer().start(PREVIEW_FADE_OUT_DELAY, function(_) {
              changingAlpha = true;
              FlxTween.tween(previewSprite, {alpha: 0.0, y: 10}, PREVIEW_FADE_OUT_DURATION,
                {
                  ease: FlxEase.quartInOut,
                  onComplete: function(_) {
                    if (wasMouseShown && FlxG.mouse.visible)
                    {
                      wasMouseShown = false;
                      FlxG.mouse.visible = false;
                    }
                    else if (wasMouseHidden && !FlxG.mouse.visible)
                    {
                      wasMouseHidden = false;
                      FlxG.mouse.visible = true;
                    }

                    previewSprite.removeEventListener(MouseEvent.MOUSE_DOWN, previewSpriteOpenScreenshotsFolder);
                    previewSprite.removeEventListener(MouseEvent.MOUSE_OVER, onHover);
                    previewSprite.removeEventListener(MouseEvent.MOUSE_OUT, onHoverOut);

                    FlxG.stage.removeChild(previewSprite);
                  }
                });
            });
          }
        });
    });
  }

  function previewSpriteOpenScreenshotsFolder(e:MouseEvent):Void
  {
    if (previewSprite.alpha <= 0) return;
    openScreenshotsFolder();
  }

  function openScreenshotsFolder():Void
  {
    FileUtil.openFolder(SCREENSHOT_FOLDER);
  }

  function onWindowClose(exitCode:Int):Void
  {
    if (noSavingScreenshots) return; 
    saveUnsavedBufferedScreenshots();
  }

  function onWindowCrash(message:String):Void
  {
    if (noSavingScreenshots) return;
    saveUnsavedBufferedScreenshots();
  }

  static function getCurrentState():FlxState
  {
    var state = FlxG.state;
    while (state.subState != null)
    {
      state = state.subState;
    }
    return state;
  }

  static function getScreenshotPath():String
  {
    return '$SCREENSHOT_FOLDER/';
  }

  static function makeScreenshotPath():Void
  {
    FileUtil.createDirIfNotExists(SCREENSHOT_FOLDER);
  }

  function encode(bitmap:Bitmap):ByteArray
  {
    var compressor = returnEncoder(SAVE_FORMAT);
    return bitmap.bitmapData.encode(bitmap.bitmapData.rect, compressor);
  }

  var previousScreenshotName:String;
  var previousScreenshotCopyNum:Int;

  function saveScreenshot(bitmap:Bitmap, targetPath = "image", screenShotNum:Int = 0, delaySave:Bool = true)
  {
    makeScreenshotPath();
    if (previousScreenshotName != targetPath && previousScreenshotName != (targetPath + ' (${previousScreenshotCopyNum})'))
    {
      previousScreenshotName = targetPath;
      targetPath = getScreenshotPath() + targetPath + '.' + Std.string(SAVE_FORMAT).toLowerCase();
      previousScreenshotCopyNum = 2;
    }
    else
    {
      var newTargetPath:String = targetPath + ' (${previousScreenshotCopyNum})';
      while (previousScreenshotName == newTargetPath)
      {
        previousScreenshotCopyNum++;
        newTargetPath = targetPath + ' (${previousScreenshotCopyNum})';
      }
      previousScreenshotName = newTargetPath;
      targetPath = getScreenshotPath() + newTargetPath + '.' + Std.string(SAVE_FORMAT).toLowerCase();
    }


    if (delaySave) 
      new FlxTimer().start(screenShotNum, function(_) {
        var pngData = encode(bitmap);

        if (pngData == null)
        {
          trace('[WARN] Failed to encode ${SAVE_FORMAT} data');
          previousScreenshotName = null;
          unsavedScreenshotBuffer.shift();
          unsavedScreenshotNameBuffer.shift();
          return;
        }
        else
        {
          trace('Saving screenshot to: ' + targetPath);
          FileUtil.writeBytesToPath(targetPath, pngData);
          unsavedScreenshotBuffer.shift();
          unsavedScreenshotNameBuffer.shift();
          if (PREVIEW_ONSAVE) showFancyPreview(bitmap); 
        }
      });
    else 
    {
      var pngData = encode(bitmap);

      if (pngData == null)
      {
        trace('[WARN] Failed to encode ${SAVE_FORMAT} data');
        previousScreenshotName = null;
        return;
      }
      else
      {
        trace('Saving screenshot to: ' + targetPath);
        FileUtil.writeBytesToPath(targetPath, pngData);
        if (PREVIEW_ONSAVE) showFancyPreview(bitmap); 
      }
    }
  }

  function saveBufferedScreenshots(screenshots:Array<Bitmap>, screenshotNames)
  {
    trace('Saving screenshot buffer');
    var i:Int = 0;

    asyncLoop = new FlxAsyncLoop(screenshots.length, () -> {
      if (screenshots[i] != null)
      {
        saveScreenshot(screenshots[i], screenshotNames[i], i);
      }
      i++;
    }, 1);
    getCurrentState().add(asyncLoop);
    if (!VsliceOptions.FLASHBANG && !PREVIEW_ONSAVE)
      showFancyPreview(screenshots[screenshots.length - 1]); 
  }

  function saveUnsavedBufferedScreenshots()
  {
    stateChanging = true;
    if (flashSprite.alpha != 0 || previewSprite.alpha != 0)
    {
      for (sprite in [flashSprite, previewSprite])
      {
        FlxTween.cancelTweensOf(sprite);
        sprite.alpha = 0;
      }
    }

    if (wasMouseShown && FlxG.mouse.visible)
    {
      wasMouseShown = false;
      FlxG.mouse.visible = false;
    }
    else if (wasMouseHidden && !FlxG.mouse.visible)
    {
      wasMouseHidden = false;
      FlxG.mouse.visible = true;
    }

    if (unsavedScreenshotBuffer[0] == null) return;

    trace('Saving unsaved screenshots in buffer!');

    for (i in 0...unsavedScreenshotBuffer.length)
    {
      if (unsavedScreenshotBuffer[i] != null) saveScreenshot(unsavedScreenshotBuffer[i], unsavedScreenshotNameBuffer[i], i, false);
    }

    unsavedScreenshotBuffer = [];
    unsavedScreenshotNameBuffer = [];
  }

  public function returnEncoder(saveFormat:String):Any
  {
    return switch (saveFormat)
    {
      default: new openfl.display.PNGEncoderOptions();
    }
  }

  function postStateSwitch()
  {
    stateChanging = false;
    screenshotBeingSpammed = false;
    FlxG.stage.removeChild(previewSprite);
  }

  override public function destroy():Void
  {
    if (instance == this) instance = null;

    if (FlxG.plugins.list.contains(this)) FlxG.plugins.remove(this);

    FlxG.signals.gameResized.remove(this.resizeBitmap);
    FlxG.signals.preStateSwitch.remove(this.saveUnsavedBufferedScreenshots);
    FlxG.signals.postStateSwitch.remove(this.postStateSwitch);
    FlxG.stage.removeChild(previewSprite);
    FlxG.stage.removeChild(flashSprite);

    super.destroy();

    try{

      @:privateAccess
      for (parent in [flashSprite, previewSprite])
        for (child in parent.__children)
          parent.removeChild(child);
    }
    catch(x:Dynamic){
      trace("We caught an exception while trying to remove the screenshot plugin!");
    }

    flashSprite = null;
    flashBitmap = null;
    previewSprite = null;
    shotPreviewBitmap = null;
    outlineBitmap = null;
  }
}
