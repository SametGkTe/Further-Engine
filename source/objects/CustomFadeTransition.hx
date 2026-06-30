package objects;

import flixel.FlxSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import backend.Language;

class CustomFadeTransition extends FlxSubState {
	public static var finishCallback:Void->Void;
	public static var nextCamera:FlxCamera;
	var isTransIn:Bool = false;
	var duration:Float;
	var callbackFired:Bool = false;

	var loadLeft:FlxSprite;
	var loadRight:FlxSprite;
	var waterMark:FlxText;
	var eventText:FlxText;

	public function new(duration:Float, isTransIn:Bool) {
		this.isTransIn = isTransIn;
		this.duration = duration;
		super();
	}

	override function create() {
		var cam:FlxCamera = new FlxCamera();
		cam.bgColor = 0x00;
		FlxG.cameras.add(cam, false);
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var halfW:Int = Std.int(FlxG.width / 2) + 2;

		loadLeft = new FlxSprite(isTransIn ? 0 : -halfW, 0).makeGraphic(halfW, FlxG.height, FlxColor.fromRGB(12, 12, 18));
		loadLeft.scrollFactor.set();
		add(loadLeft);

		loadRight = new FlxSprite(isTransIn ? halfW : FlxG.width, 0).makeGraphic(halfW, FlxG.height, FlxColor.fromRGB(12, 12, 18));
		loadRight.scrollFactor.set();
		add(loadRight);

		var accentLine:FlxSprite = new FlxSprite(0, Std.int(FlxG.height / 2) - 1).makeGraphic(FlxG.width, 2, FlxColor.fromRGB(80, 160, 255));
		accentLine.scrollFactor.set();
		accentLine.alpha = 0;
		add(accentLine);

		waterMark = new FlxText(0, FlxG.height - 90, FlxG.width, "PET Engine", 28);
		waterMark.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.fromRGB(80, 160, 255), CENTER);
		waterMark.scrollFactor.set();
		waterMark.alpha = 0;
		add(waterMark);

		eventText = new FlxText(0, FlxG.height - 55, FlxG.width,
			isTransIn ? Language.getPhrase("transition_complete", "Tamamlandı!") : Language.getPhrase("transition_loading", "Yükleniyor..."), 22);
		eventText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.fromRGB(180, 180, 200), CENTER);
		eventText.scrollFactor.set();
		eventText.alpha = 0;
		add(eventText);

		if (!isTransIn) {
			FlxTween.tween(loadLeft, {x: 0}, duration, {ease: FlxEase.expoInOut});

			FlxTween.tween(loadRight, {x: halfW - 2}, duration, {
				ease: FlxEase.expoInOut,
				onComplete: function(_) {
					fireCallback();
				}
			});

			FlxTween.tween(accentLine, {alpha: 0.6}, duration * 0.6, {startDelay: duration * 0.3, ease: FlxEase.sineOut});
			FlxTween.tween(waterMark, {alpha: 1}, duration * 0.4, {startDelay: duration * 0.5, ease: FlxEase.sineOut});
			FlxTween.tween(eventText, {alpha: 1}, duration * 0.4, {startDelay: duration * 0.55, ease: FlxEase.sineOut});
		} else {
			accentLine.alpha = 0.6;
			waterMark.alpha = 1;
			eventText.alpha = 1;

			FlxTween.tween(waterMark, {alpha: 0}, duration * 0.3, {ease: FlxEase.sineIn});
			FlxTween.tween(eventText, {alpha: 0}, duration * 0.3, {ease: FlxEase.sineIn});
			FlxTween.tween(accentLine, {alpha: 0}, duration * 0.4, {ease: FlxEase.sineIn});

			FlxTween.tween(loadLeft, {x: -halfW}, duration, {ease: FlxEase.expoInOut});

			FlxTween.tween(loadRight, {x: FlxG.width}, duration, {
				ease: FlxEase.expoInOut,
				onComplete: function(_) {
					close();
				}
			});
		}

		super.create();
	}

	function fireCallback():Void {
		if (callbackFired) return;
		callbackFired = true;
		if (finishCallback != null) {
			finishCallback();
		}
	}
}