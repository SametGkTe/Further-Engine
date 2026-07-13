package mikolka.vslice.freeplay.pslice;

import mikolka.vslice.freeplay.backcards.BoyfriendCard;


class FreeplayColorTweener
{
	private static final twnOptions:TweenOptions = {
		startDelay: 0.15,
		ease: FlxEase.circIn
	};
	private var targetState:BoyfriendCard;
	private var intendedColor:Null<FlxColor>;
	var tweens:List<FlxTween>;

	public function new(state:BoyfriendCard)
	{
		targetState = state;
		intendedColor = null;
		tweens = new List<FlxTween>();
	}

	public function cancelTween()
	{
		for (tw in tweens)
		{
			tw.cancel();
			tw.destroy();
		}
		tweens.clear();
	}

	public function tweenColor(newColor:FlxColor)
	{
		if (newColor != intendedColor && targetState != null)
		{
			cancelTween();
			intendedColor = newColor;
			@:privateAccess {
				tweens.add(twnSprite(targetState.pinkBack, [0, 0, 0])); 
				tweens.add(twnText(targetState.funnyScroll, [-20, -63, -20])); 
				tweens.add(twnText(targetState.funnyScroll2, [-20, -63, -20])); 

				tweens.add(twnText(targetState.funnyScroll3, [-21, -52, -99])); 

				tweens.add(twnSprite(targetState.orangeBackShit, [4, -20, -70])); 
				tweens.add(twnSprite(targetState.alsoOrangeLOL, [5, -14, -70])); 
				tweens.add(twnText(targetState.txtNuts, [20, 39, 156]));

				tweens.add(twnText(targetState.moreWays, [0, 27, 32])); 
				tweens.add(twnText(targetState.moreWays2, [0, 27, 32])); 
			}
		}
	}

	private function twnSprite(sprite:FlxSprite, offset:Array<Int>)
	{
		var realColor = FlxColor.fromRGB(addClrComp(intendedColor.red, offset[0]), addClrComp(intendedColor.green, offset[1]),
			addClrComp(intendedColor.blue, offset[2]));
		return FlxTween.color(sprite, 1, sprite.color, realColor,twnOptions);
	}

	private function twnText(sprite:BGScrollingText, offset:Array<Int>)
	{
		var textCurColor = sprite.color;
		var realColor = FlxColor.fromRGB(addClrComp(intendedColor.red, offset[0]), addClrComp(intendedColor.green, offset[1]),
			addClrComp(intendedColor.blue, offset[2]));
		return FlxTween.num(0, 1, 1, twnOptions, f ->
		{
			sprite.color = FlxColor.interpolate(textCurColor, realColor, f);
		});
	}

	private function addClrComp(clr1:Int, clr2:Int)
	{
		var rawResult = clr1 + clr2;
		return Std.int(FlxMath.bound(0, 255, rawResult));
	}
}
