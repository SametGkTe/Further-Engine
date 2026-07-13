package mikolka.vslice;

import mikolka.funkin.custom.NativeFileSystem;
import mikolka.vslice.freeplay.DifficultyStars;
#if sys import mikolka.vslice.components.crash.Logger; #end
import mikolka.funkin.utils.MathUtil;
import openfl.Assets;
import openfl.utils.Promise;
import lime.app.Future;
import openfl.events.MouseEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.Lib;
import flixel.system.FlxBasePreloader;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import shaders.VFDOverlay;
#if !LEGACY_PSYCH
import backend.Paths;
#end

using StringTools;


@:bitmap("art/banner.png")
class LogoImage extends BitmapData
{
}

#if TOUCH_HERE_TO_PLAY
@:bitmap('art/touchHereToPlay.png')
class TouchHereToPlayImage extends BitmapData
{
}
#end

class FunkinPreloader extends FlxBasePreloader
{
	static final BASE_WIDTH:Float = 1280;

	static final BAR_PADDING:Float = 20;

	static final BAR_HEIGHT:Int = 12;

	static final LOGO_FADE_TIME:Float = 2.5;

	var ratio:Float = 0;

	var currentState:FunkinPreloaderState = FunkinPreloaderState.NotStarted;

	private var downloadingAssetsPercent:Float = -1;
	private var downloadingAssetsComplete:Bool = false;

	private var preloadingPlayAssetsPercent:Float = -1;
	private var preloadingPlayAssetsStartTime:Float = -1;
	private var preloadingPlayAssetsComplete:Bool = false;

	private var cachingGraphicsPercent:Float = -1;
	private var cachingGraphicsStartTime:Float = -1;
	private var cachingGraphicsComplete:Bool = false;

	private var cachingAudioPercent:Float = -1;
	private var cachingAudioStartTime:Float = -1;
	private var cachingAudioComplete:Bool = false;

	private var cachingDataPercent:Float = -1;
	private var cachingDataStartTime:Float = -1;
	private var cachingDataComplete:Bool = false;

	private var parsingSpritesheetsPercent:Float = -1;
	private var parsingSpritesheetsStartTime:Float = -1;
	private var parsingSpritesheetsComplete:Bool = false;

	private var parsingStagesPercent:Float = -1;
	private var parsingStagesStartTime:Float = -1;
	private var parsingStagesComplete:Bool = false;

	private var parsingCharactersPercent:Float = -1;
	private var parsingCharactersStartTime:Float = -1;
	private var parsingCharactersComplete:Bool = false;

	private var parsingSongsPercent:Float = -1;
	private var parsingSongsStartTime:Float = -1;
	private var parsingSongsComplete:Bool = false;

	private var initializingScriptsPercent:Float = -1;

	private var cachingCoreAssetsPercent:Float = -1;

	private var completeTime:Float = -1;

	var logo:Bitmap;
	#if TOUCH_HERE_TO_PLAY
	var touchHereToPlay:Bitmap;
	var touchHereSprite:Sprite;
	#end
	var progressBarPieces:Array<Sprite>;
	var progressBar:Bitmap;
	var progressLeftText:TextField;
	var progressRightText:TextField;

	var dspText:TextField;
	var fnfText:TextField;
	var enhancedText:TextField;
	var stereoText:TextField;

	var vfdShader:VFDOverlay;
	var vfdBitmap:Bitmap;
	var box:Sprite;
	var progressLines:Sprite;

	public function new()
	{
		super(0.0, ["psych-slice.github.io", FlxBasePreloader.LOCAL]);

		trace('Initializing custom preloader...');

		this.siteLockTitleText = "You Loser!";
	}

	override function create():Void
	{
		super.create();

		Lib.current.stage.color = 0xFF000000;
		Lib.current.stage.frameRate = 30;

		this._width = Lib.current.stage.stageWidth;
		this._height = Lib.current.stage.stageHeight;

		Main.loadGameEarly();

		ratio = this._width / BASE_WIDTH / 2.0;

		logo = createBitmap(LogoImage, function(bmp:Bitmap)
		{
			bmp.scaleX = bmp.scaleY = ratio;
			bmp.x = (this._width - bmp.width) / 2;
			bmp.y = (this._height - bmp.height) / 2;
		});

		var amountOfPieces:Int = 16;
		progressBarPieces = [];
		var maxBarWidth = this._width - BAR_PADDING * 2;
		var pieceWidth = maxBarWidth / amountOfPieces;
		var pieceGap:Int = 8;

		progressLines = new openfl.display.Sprite();
		progressLines.graphics.lineStyle(2, 0xFFA4FF11);
		progressLines.graphics.drawRect(-2, this._height - BAR_PADDING - BAR_HEIGHT - 208, this._width + 4, 30);
		addChild(progressLines);

		var progressBarPiece = new Sprite();
		progressBarPiece.graphics.beginFill(0xFFA4FF11);
		progressBarPiece.graphics.drawRoundRect(0, 0, pieceWidth - pieceGap, BAR_HEIGHT, 4, 4);
		progressBarPiece.graphics.endFill();

		for (i in 0...amountOfPieces)
		{
			var piece = new Sprite();
			piece.graphics.beginFill(0xFFA4FF11);
			piece.graphics.drawRoundRect(0, 0, pieceWidth - pieceGap, BAR_HEIGHT, 4, 4);
			piece.graphics.endFill();

			piece.x = i * (piece.width + pieceGap);
			piece.y = this._height - BAR_PADDING - BAR_HEIGHT - 200;
			addChild(piece);
			progressBarPieces.push(piece);
		}
		progressLeftText = new TextField();
		dspText = new TextField();
		fnfText = new TextField();
		enhancedText = new TextField();
		stereoText = new TextField();

		var progressLeftTextFormat = new TextFormat("DS-Digital", 32, 0xFFA4FF11, true);
		progressLeftTextFormat.align = TextFormatAlign.LEFT;
		progressLeftText.defaultTextFormat = progressLeftTextFormat;

		progressLeftText.selectable = false;
		progressLeftText.width = this._width - BAR_PADDING * 2;
		progressLeftText.text = 'Downloading assets...';
		progressLeftText.x = BAR_PADDING;
		progressLeftText.y = this._height - BAR_PADDING - BAR_HEIGHT - 290;
		addChild(progressLeftText);

		progressRightText = new TextField();

		var progressRightTextFormat = new TextFormat("DS-Digital", 16, 0xFFA4FF11, true);
		progressRightTextFormat.align = TextFormatAlign.RIGHT;
		progressRightText.defaultTextFormat = progressRightTextFormat;

		progressRightText.selectable = false;
		progressRightText.width = this._width - BAR_PADDING * 2;
		progressRightText.text = '0%';
		progressRightText.x = BAR_PADDING;
		progressRightText.y = this._height - BAR_PADDING - BAR_HEIGHT - 16 - 4;
		addChild(progressRightText);

		box = new Sprite();
		box.graphics.beginFill(0xFFA4FF11, 1);
		box.graphics.drawRoundRect(0, 0, 64, 20, 5, 5);
		box.graphics.drawRoundRect(70, 0, 58, 20, 5, 5);
		box.graphics.endFill();
		box.graphics.beginFill(0xFFA4FF11, 0.1);
		box.graphics.drawRoundRect(0, 0, 128, 20, 5, 5);
		box.graphics.endFill();
		box.x = this._width - BAR_PADDING - BAR_HEIGHT - 432;
		box.y = this._height - BAR_PADDING - BAR_HEIGHT - 244;
		addChild(box);

		dspText.selectable = false;
		dspText.textColor = 0x000000;
		dspText.width = this._width;
		dspText.height = 30;
		dspText.text = 'DSP';
		dspText.x = 10;
		dspText.y = -7;
		box.addChild(dspText);

		fnfText.selectable = false;
		fnfText.textColor = 0x000000;
		fnfText.width = this._width;
		fnfText.height = 30;
		fnfText.x = 78;
		fnfText.y = -7;
		fnfText.text = 'FNF';
		box.addChild(fnfText);

		enhancedText.selectable = false;
		enhancedText.textColor = 0xFFA4FF11;
		enhancedText.width = this._width;
		enhancedText.height = 100;
		enhancedText.text = 'ENHANCED';
		enhancedText.x = -100;
		enhancedText.y = 0;
		box.addChild(enhancedText);

		stereoText.selectable = false;
		stereoText.textColor = 0xFFA4FF11;
		stereoText.width = this._width;
		stereoText.height = 100;
		stereoText.text = 'STEREO';
		stereoText.x = 0;
		stereoText.y = -40;
		box.addChild(stereoText);



		vfdBitmap = new Bitmap(new BitmapData(this._width, this._height, true, 0xFFFFFFFF));
		addChild(vfdBitmap);

		vfdShader = new VFDOverlay();
		vfdBitmap.shader = vfdShader;

		#if TOUCH_HERE_TO_PLAY
		touchHereToPlay = createBitmap(TouchHereToPlayImage, function(bmp:Bitmap)
		{
			bmp.scaleX = bmp.scaleY = ratio;
			bmp.x = (this._width - bmp.width) / 2;
			bmp.y = (this._height - bmp.height) / 2;
		});
		touchHereToPlay.alpha = 0.0;

		touchHereSprite = new Sprite();
		touchHereSprite.buttonMode = false;
		touchHereSprite.addChild(touchHereToPlay);
		addChild(touchHereSprite);
		#end
	}

	var lastElapsed:Float = 0.0;

	override function update(percent:Float):Void
	{
		var elapsed:Float = (Date.now().getTime() - this._startTime) / 1000.0;

		vfdShader.update(elapsed * 100);

		downloadingAssetsPercent = percent;
		var loadPercent:Float = updateState(percent, elapsed);
		updateGraphics(loadPercent, elapsed);

		lastElapsed = elapsed;
	}

	function updateState(percent:Float, elapsed:Float):Float
	{
		switch (currentState)
		{
			case FunkinPreloaderState.NotStarted:
				if (downloadingAssetsPercent > 0.0)
					currentState = FunkinPreloaderState.DownloadingAssets;

				return percent;

			case FunkinPreloaderState.DownloadingAssets:
				if (downloadingAssetsPercent >= 1.0 || (elapsed > 0.0 && downloadingAssetsComplete))
					currentState = FunkinPreloaderState.PreloadingPlayAssets;

				return percent;

			case FunkinPreloaderState.PreloadingPlayAssets:
				if (preloadingPlayAssetsPercent < 0.0)
				{
					preloadingPlayAssetsStartTime = elapsed;
					preloadingPlayAssetsPercent = 0.0;

					NativeFileSystem.openFlAssets = Assets.list();
					openfl.utils.Assets.cache.enabled = false;
					
					#if (linux || ios)
					FlxG.signals.preStateCreate.add(state ->{
						mikolka.funkin.custom.NativeFileSystem.excludePaths.resize(0);
					});
					#end


					preloadingPlayAssetsPercent = 1.0;
					preloadingPlayAssetsComplete = true;
					return 0.0;
				}
				else if (0.0 > 0)
				{
					var elapsedPreloadingPlayAssets:Float = elapsed - preloadingPlayAssetsStartTime;
					if (preloadingPlayAssetsComplete && elapsedPreloadingPlayAssets >= 0.0)
					{
						currentState = FunkinPreloaderState.InitializingScripts;
						return 0.0;
					}
					else
					{
						if (preloadingPlayAssetsPercent < (elapsedPreloadingPlayAssets / 0.0))
							return preloadingPlayAssetsPercent;
						else
							return elapsedPreloadingPlayAssets / 0.0;
					}
				}
				else
				{
					if (preloadingPlayAssetsComplete)
						currentState = FunkinPreloaderState.InitializingScripts;
				}

				return preloadingPlayAssetsPercent;

			case FunkinPreloaderState.InitializingScripts:
				if (initializingScriptsPercent < 0.0)
				{
					initializingScriptsPercent = 0.0;


					initializingScriptsPercent = 1.0;
					currentState = FunkinPreloaderState.CachingGraphics;
					return 0.0;
				}

				return initializingScriptsPercent;

			case CachingGraphics:
				if (cachingGraphicsPercent < 0)
				{
					cachingGraphicsPercent = 0.0;
					cachingGraphicsStartTime = elapsed;
					#if !LEGACY_PSYCH
					var assetsToCache:Array<String> = [
					]; 

					var promise = new Promise<Any>();
					new Future(() ->
					{
						for (index => item in assetsToCache)
						{
							try
							{
								
								CacheSystem.excludeAsset(item);
							}
							catch (x:Exception)
								trace("Exception when caching: " + x.message);
							promise.progress(index + 1, assetsToCache.length);
						}
						promise.complete(null);
					}, #if mac false #else true #end); 

					promise.future.onProgress((loaded:Int, total:Int) ->
					{
						cachingGraphicsPercent = loaded / total;
					});
					promise.future.onComplete((_result) ->
					{
						cachingGraphicsComplete = true;
						trace('Completed caching graphics.');
					});
					#else

					cachingGraphicsComplete = true;
					cachingGraphicsPercent = 1.0;
					#end

					return 0.0;
				}
				else if (0.0 > 0)
				{
					var elapsedCachingGraphics:Float = elapsed - cachingGraphicsStartTime;
					if (cachingGraphicsComplete && elapsedCachingGraphics >= 0.0)
					{
						currentState = FunkinPreloaderState.CachingAudio;
						return 0.0;
					}
					else
					{
						if (cachingGraphicsPercent < (elapsedCachingGraphics / 0.0))
						{
							return cachingGraphicsPercent;
						}
						else
						{
							return elapsedCachingGraphics / 0.0;
						}
					}
				}
				else
				{
					if (cachingGraphicsComplete)
					{
						currentState = FunkinPreloaderState.CachingAudio;
						return 0.0;
					}
					else
					{
						return cachingGraphicsPercent;
					}
				}

			case CachingAudio:
				if (cachingAudioPercent < 0)
				{
					cachingAudioPercent = 0.0;
					cachingAudioStartTime = elapsed;

					var assetsToCache:Array<String> = []; 


					cachingAudioPercent = 1.0;
					cachingAudioComplete = true;
					return 0.0;
				}
				else if (0.0 > 0)
				{
					var elapsedCachingAudio:Float = elapsed - cachingAudioStartTime;
					if (cachingAudioComplete && elapsedCachingAudio >= 0.0)
					{
						currentState = FunkinPreloaderState.CachingData;
						return 0.0;
					}
					else
					{
						if (cachingAudioPercent < (elapsedCachingAudio / 0.0))
						{
							return cachingAudioPercent;
						}
						else
						{
							return elapsedCachingAudio / 0.0;
						}
					}
				}
				else
				{
					if (cachingAudioComplete)
					{
						currentState = FunkinPreloaderState.CachingData;
						return 0.0;
					}
					else
					{
						return cachingAudioPercent;
					}
				}

			case CachingData:
				if (cachingDataPercent < 0)
				{
					cachingDataPercent = 0.0;
					cachingDataStartTime = elapsed;
					#if !LEGACY_PSYCH

					var assetsToCache:Array<String> = [
					"freeplay/freeplayStars",
					"freeplay/albumRoll/freeplayAlbum",
					"freeplay/sortedLetters",
					"charSelect/charSelectStage"
					];

					trace("Load misc");

						var promise = new Promise<Any>();
					new Future(() ->
					{
						for (index => item in assetsToCache)
						{
							try
							{
								var text = NativeFileSystem.getContent('assets/shared/images/${item}/Animation.json');
								var jsonBlob = haxe.Json.parse(text);
								if (jsonBlob != null)
								{
									#if debug trace("Cached JSON: " + item); #end
									mikolka.funkin.FlxAtlasSprite.ANIMATION_OBJECTS.set(item,jsonBlob);
								}
								else trace("JSON is null: " + item);
								
							}
							catch (x:Exception)
								trace("Exception when caching Anim JSON: " + x.message);
							promise.progress(index + 1, assetsToCache.length);
						}
						promise.complete(null);
					}, true); 

					promise.future.onProgress((loaded:Int, total:Int) ->
					{
						cachingDataPercent = loaded / total;
					});
					promise.future.onComplete((_result) ->
					{
						cachingDataComplete = true;
						trace('Completed caching JSONs.');
					});
					#else

					cachingDataComplete = true;
					cachingDataPercent = 1.0;
					#end
					return 0.0;
				}
				else if (0.0 > 0)
				{
					var elapsedCachingData:Float = elapsed - cachingDataStartTime;
					if (cachingDataComplete && elapsedCachingData >= 0.0)
					{
						currentState = FunkinPreloaderState.ParsingSpritesheets;
						return 0.0;
					}
					else
					{
						if (cachingDataPercent < (elapsedCachingData / 0.0))
							return cachingDataPercent;
						else
							return elapsedCachingData / 0.0;
					}
				}
				else
				{
					if (cachingDataComplete)
					{
						currentState = FunkinPreloaderState.ParsingSpritesheets;
						return 0.0;
					}
				}

				return cachingDataPercent;

			case ParsingSpritesheets:
				if (parsingSpritesheetsPercent < 0)
				{
					parsingSpritesheetsPercent = 0.0;
					parsingSpritesheetsStartTime = elapsed;

					var sparrowFramesToCache = []; 

					parsingSpritesheetsPercent = 1.0;
					parsingSpritesheetsComplete = true;
					return 0.0;
				}
				else if (0.0 > 0)
				{
					var elapsedParsingSpritesheets:Float = elapsed - parsingSpritesheetsStartTime;
					if (parsingSpritesheetsComplete && elapsedParsingSpritesheets >= 0.0)
					{
						currentState = FunkinPreloaderState.ParsingStages;
						return 0.0;
					}
					else
					{
						if (parsingSpritesheetsPercent < (elapsedParsingSpritesheets / 0.0))
							return parsingSpritesheetsPercent;
						else
							return elapsedParsingSpritesheets / 0.0;
					}
				}
				else
				{
					if (parsingSpritesheetsComplete)
					{
						currentState = FunkinPreloaderState.ParsingStages;
						return 0.0;
					}
				}

				return parsingSpritesheetsPercent;

			case ParsingStages:
				if (parsingStagesPercent < 0)
				{
					parsingStagesPercent = 0.0;
					parsingStagesStartTime = elapsed;


					parsingStagesPercent = 1.0;
					parsingStagesComplete = true;
					return 0.0;
				}
				else if (0.0 > 0)
				{
					var elapsedParsingStages:Float = elapsed - parsingStagesStartTime;
					if (parsingStagesComplete && elapsedParsingStages >= 0.0)
					{
						currentState = FunkinPreloaderState.ParsingCharacters;
						return 0.0;
					}
					else
					{
						if (parsingStagesPercent < (elapsedParsingStages / 0.0))
							return parsingStagesPercent;
						else
							return elapsedParsingStages / 0.0;
					}
				}
				else
				{
					if (parsingStagesComplete)
					{
						currentState = FunkinPreloaderState.ParsingCharacters;
						return 0.0;
					}
				}

				return parsingStagesPercent;

			case ParsingCharacters:
				if (parsingCharactersPercent < 0)
				{
					parsingCharactersPercent = 0.0;
					parsingCharactersStartTime = elapsed;


					parsingCharactersPercent = 1.0;
					parsingCharactersComplete = true;
					return 0.0;
				}
				else if (0.0 > 0)
				{
					var elapsedParsingCharacters:Float = elapsed - parsingCharactersStartTime;
					if (parsingCharactersComplete && elapsedParsingCharacters >= 0.0)
					{
						currentState = FunkinPreloaderState.ParsingSongs;
						return 0.0;
					}
					else
					{
						if (parsingCharactersPercent < (elapsedParsingCharacters / 0.0))
							return parsingCharactersPercent;
						else
							return elapsedParsingCharacters / 0.0;
					}
				}
				else
				{
					if (parsingStagesComplete)
					{
						currentState = FunkinPreloaderState.ParsingSongs;
						return 0.0;
					}
				}

				return parsingCharactersPercent;

			case ParsingSongs:
				if (parsingSongsPercent < 0)
				{
					parsingSongsPercent = 0.0;
					parsingSongsStartTime = elapsed;


					parsingSongsPercent = 1.0;
					parsingSongsComplete = true;

					return 0.0;
				}
				else if (0.0 > 0)
				{
					var elapsedParsingSongs:Float = elapsed - parsingSongsStartTime;
					if (parsingSongsComplete && elapsedParsingSongs >= 0.0)
					{
						currentState = FunkinPreloaderState.Complete;
						return 0.0;
					}
					else
					{
						if (parsingSongsPercent < (elapsedParsingSongs / 0.0))
						{
							return parsingSongsPercent;
						}
						else
						{
							return elapsedParsingSongs / 0.0;
						}
					}
				}
				else
				{
					if (parsingSongsComplete)
					{
						currentState = FunkinPreloaderState.Complete;
						return 0.0;
					}
					else
					{
						return parsingSongsPercent;
					}
				}
			case FunkinPreloaderState.Complete:
				if (completeTime < 0)
				{
					completeTime = elapsed;
				}

				return 1.0;
			#if TOUCH_HERE_TO_PLAY
			case FunkinPreloaderState.TouchHereToPlay:
				if (completeTime < 0)
				{
					completeTime = elapsed;
				}

				if (touchHereToPlay.alpha < 1.0)
				{
					touchHereSprite.buttonMode = true;
					touchHereToPlay.alpha = 1.0;
					removeChild(vfdBitmap);

					addEventListener(MouseEvent.CLICK, onTouchHereToPlay);
					touchHereSprite.addEventListener(MouseEvent.MOUSE_OVER, overTouchHereToPlay);
					touchHereSprite.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownTouchHereToPlay);
					touchHereSprite.addEventListener(MouseEvent.MOUSE_OUT, outTouchHereToPlay);
				}

				return 1.0;
			#end

			default:
		}

		return 0.0;
	}

	#if TOUCH_HERE_TO_PLAY
	function overTouchHereToPlay(e:MouseEvent):Void
	{
		touchHereToPlay.scaleX = touchHereToPlay.scaleY = ratio * 1.1;
		touchHereToPlay.x = (this._width - touchHereToPlay.width) / 2;
		touchHereToPlay.y = (this._height - touchHereToPlay.height) / 2;
	}

	function outTouchHereToPlay(e:MouseEvent):Void
	{
		touchHereToPlay.scaleX = touchHereToPlay.scaleY = ratio * 1;
		touchHereToPlay.x = (this._width - touchHereToPlay.width) / 2;
		touchHereToPlay.y = (this._height - touchHereToPlay.height) / 2;
	}

	function mouseDownTouchHereToPlay(e:MouseEvent):Void
	{
		touchHereToPlay.y += 10;
	}

	function onTouchHereToPlay(e:MouseEvent):Void
	{
		touchHereToPlay.x = (this._width - touchHereToPlay.width) / 2;
		touchHereToPlay.y = (this._height - touchHereToPlay.height) / 2;

		removeEventListener(MouseEvent.CLICK, onTouchHereToPlay);
		touchHereSprite.removeEventListener(MouseEvent.MOUSE_OVER, overTouchHereToPlay);
		touchHereSprite.removeEventListener(MouseEvent.MOUSE_OUT, outTouchHereToPlay);
		touchHereSprite.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownTouchHereToPlay);

		immediatelyStartGame();
	}
	#end

	static final TOTAL_STEPS:Int = 11;
	static final ELLIPSIS_TIME:Float = 0.5;

	function updateGraphics(percent:Float, elapsed:Float):Void
	{
		if (completeTime > 0.0)
		{
			var elapsedFinished:Float = renderLogoFadeOut(elapsed);
			if (elapsedFinished > LOGO_FADE_TIME)
			{
				#if TOUCH_HERE_TO_PLAY
				currentState = FunkinPreloaderState.TouchHereToPlay;
				#else
				immediatelyStartGame();
				#end
			}
		}
		else
		{
			renderLogoFadeIn(elapsed);

			var maxWidth = this._width - BAR_PADDING * 2;
			var barWidth = maxWidth * percent;
			var piecesToRender:Int = Std.int(percent * progressBarPieces.length);

			for (i => piece in progressBarPieces)
			{
				piece.alpha = i <= piecesToRender ? 0.9 : 0.1;
			}
		}


		var ellipsisCount:Int = Std.int(elapsed / ELLIPSIS_TIME) % 3 + 1;
		var ellipsis:String = '';
		for (i in 0...ellipsisCount)
			ellipsis += '.';

		var percentage:Int = Math.floor(percent * 100);
		switch (currentState)
		{
			default:
				updateProgressLeftText('Loading \n0/$TOTAL_STEPS $ellipsis');
			case FunkinPreloaderState.DownloadingAssets:
				updateProgressLeftText('Downloading assets \n1/$TOTAL_STEPS $ellipsis');
			case FunkinPreloaderState.PreloadingPlayAssets:
				updateProgressLeftText('Preloading assets \n2/$TOTAL_STEPS $ellipsis');
			case FunkinPreloaderState.InitializingScripts:
				updateProgressLeftText('Initializing scripts \n3/$TOTAL_STEPS $ellipsis');
			case FunkinPreloaderState.CachingGraphics:
				updateProgressLeftText('Caching graphics \n4/$TOTAL_STEPS $ellipsis');
			case FunkinPreloaderState.CachingAudio:
				updateProgressLeftText('Caching audio \n5/$TOTAL_STEPS $ellipsis');
			case FunkinPreloaderState.CachingData:
				updateProgressLeftText('Caching data \n6/$TOTAL_STEPS $ellipsis');
			case FunkinPreloaderState.ParsingSpritesheets:
				updateProgressLeftText('Parsing spritesheets \n7/$TOTAL_STEPS $ellipsis');
			case FunkinPreloaderState.ParsingStages:
				updateProgressLeftText('Parsing stages \n8/$TOTAL_STEPS $ellipsis');
			case FunkinPreloaderState.ParsingCharacters:
				updateProgressLeftText('Parsing characters \n9/$TOTAL_STEPS $ellipsis');
			case FunkinPreloaderState.ParsingSongs:
				updateProgressLeftText('Parsing songs \n10/$TOTAL_STEPS $ellipsis');
			case FunkinPreloaderState.Complete:
				updateProgressLeftText('Finishing up \n$TOTAL_STEPS/$TOTAL_STEPS $ellipsis');
			#if TOUCH_HERE_TO_PLAY
			case FunkinPreloaderState.TouchHereToPlay:
				updateProgressLeftText(null);
			#end
		}

		progressRightText.text = '$percentage%';

		super.update(percent);
	}

	function updateProgressLeftText(text:Null<String>):Void
	{
		if (progressLeftText != null)
		{
			if (text == null)
			{
				progressLeftText.alpha = 0.0;
			}
			else if (progressLeftText.text != text)
			{
				var progressLeftTextFormat = new TextFormat("DS-Digital", 32, 0xFFA4FF11, true);
				progressLeftTextFormat.align = TextFormatAlign.LEFT;
				progressLeftText.defaultTextFormat = progressLeftTextFormat;
				progressLeftText.text = text;

				dspText.defaultTextFormat = new TextFormat("Quantico", 20, 0x000000, false);
				dspText.text = 'DSP'; 
				dspText.textColor = 0x000000;

				fnfText.defaultTextFormat = new TextFormat("Quantico", 20, 0x000000, false);
				fnfText.text = 'FNF';
				fnfText.textColor = 0x000000;

				enhancedText.defaultTextFormat = new TextFormat("Inconsolata Black", 16, 0xFFA4FF11, false);
				enhancedText.text = 'ENHANCED';
				enhancedText.textColor = 0xFFA4FF11;

				stereoText.defaultTextFormat = new TextFormat("Inconsolata Bold", 36, 0xFFA4FF11, false);
				stereoText.text = 'NATURAL STEREO';
			}
		}
	}

	function immediatelyStartGame():Void
	{
		_loaded = true;
	}

	function renderLogoFadeOut(elapsed:Float):Float
	{
		var elapsedFinished = elapsed - completeTime;

		logo.alpha = 1.0 - MathUtil.easeInOutCirc(elapsedFinished / LOGO_FADE_TIME);
		logo.scaleX = (1.0 - MathUtil.easeInBack(elapsedFinished / LOGO_FADE_TIME)) * ratio;
		logo.scaleY = (1.0 - MathUtil.easeInBack(elapsedFinished / LOGO_FADE_TIME)) * ratio;
		logo.x = (this._width - logo.width) / 2;
		logo.y = (this._height - logo.height) / 2;

		progressLeftText.alpha = logo.alpha;
		progressRightText.alpha = logo.alpha;
		box.alpha = logo.alpha;
		dspText.alpha = logo.alpha;
		fnfText.alpha = logo.alpha;
		enhancedText.alpha = logo.alpha;
		stereoText.alpha = logo.alpha;
		progressLines.alpha = logo.alpha;

		for (piece in progressBarPieces)
			piece.alpha = logo.alpha;

		return elapsedFinished;
	}

	function renderLogoFadeIn(elapsed:Float):Void
	{
		logo.alpha = MathUtil.easeInOutCirc(elapsed / LOGO_FADE_TIME);
		logo.scaleX = MathUtil.easeOutBack(elapsed / LOGO_FADE_TIME) * ratio;
		logo.scaleY = MathUtil.easeOutBack(elapsed / LOGO_FADE_TIME) * ratio;
		logo.x = (this._width - logo.width) / 2;
		logo.y = (this._height - logo.height) / 2;
	}

	#if html5

	override function createSiteLockFailureScreen():Void
	{
	}

	override function adjustSiteLockTextFields(titleText:TextField, bodyText:TextField, hyperlinkText:TextField):Void
	{
		var titleFormat = titleText.defaultTextFormat;
		titleFormat.align = TextFormatAlign.CENTER;
		titleFormat.color = 0xCCCCCC;
		titleText.setTextFormat(titleFormat);

		var bodyFormat = bodyText.defaultTextFormat;
		bodyFormat.align = TextFormatAlign.CENTER;
		bodyFormat.color = 0xCCCCCC;
		bodyText.setTextFormat(bodyFormat);

		var hyperlinkFormat = hyperlinkText.defaultTextFormat;
		hyperlinkFormat.align = TextFormatAlign.CENTER;
		hyperlinkFormat.color = 0xEEB211;
		hyperlinkText.setTextFormat(hyperlinkFormat);
	}
	#end

	override function destroy():Void
	{
		removeChild(logo);
		logo = null;
		super.destroy();
	}

	override function onLoaded():Void
	{
		super.onLoaded();
		_loaded = false;
		downloadingAssetsComplete = true;
	}
}

enum FunkinPreloaderState
{
	NotStarted;

	DownloadingAssets;

	PreloadingPlayAssets;

	InitializingScripts;

	CachingGraphics;

	CachingAudio;

	CachingData;

	ParsingSpritesheets;

	ParsingStages;

	ParsingCharacters;

	ParsingSongs;

	Complete;

	#if TOUCH_HERE_TO_PLAY
	TouchHereToPlay;
	#end
}
