package mobile.objects;

#if TOUCH_CONTROLS_ALLOWED
import flixel.FlxG;
import flixel.FlxObject;
import flixel.input.touch.FlxTouch;
import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;
import mobile.backend.TouchUtil;
import backend.Controls;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;

class ScrollableObject extends TouchZone
{
	public var onFullScroll(default, never):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	public var onPartialScroll(default, never):FlxTypedSignal<Float->Void> = new FlxTypedSignal<Float->Void>();
	public var onFullScrollSnap(default, never):FlxSignal = new FlxSignal();
	public var onTap(default, never):FlxSignal = new FlxSignal();

	private var isDragging:Bool = false;
	private var isTapping:Bool = false;
	private var lastYPos:Float = 0;
	private var partialScrollTracker:Float = 0;
	private var scrollScale:Float = 0;
	private var clickButton:FlxObject;

	public function new(scrollScale:Float, x:Float, y:Float, width:Float, height:Float, clickButton:FlxObject)
	{
		this.scrollScale = scrollScale;
		this.clickButton = clickButton;
		super(x, y, width, height);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var curDelta = getDeltaY();

		if (
			#if mobile
			(TouchUtil.justPressed && TouchUtil.overlaps(this))
			#else
			(FlxG.mouse.justPressed && FlxG.mouse.overlaps(this, this.camera))
			#end
		)
		{
			isDragging = false;
			isTapping = true;
		}
		else if (#if mobile TouchUtil.justReleased #else FlxG.mouse.justReleased #end)
		{
			if (isTapping)
			{
				#if mobile
				var releasedTouch = getJustReleasedTouch();
				if (releasedTouch != null && releasedTouch.overlaps(clickButton, clickButton.camera))
					onTap.dispatch();
				#else
				if (FlxG.mouse.overlaps(clickButton, clickButton.camera))
					onTap.dispatch();
				#end

				isTapping = false;
			}
			else if (isDragging)
			{
				onFullScrollSnap.dispatch();
				isDragging = false;

				var curDpad = Controls.instance.isInSubstate
					? MusicBeatSubstate.instance.touchPad
					: MusicBeatState.getState().touchPad;

				if (curDpad != null)
					curDpad.active = true;
			}
			else
				return;

			partialScrollTracker = 0;
		}
		else if ((#if mobile TouchUtil.pressed || #end FlxG.mouse.pressed) && Math.abs(curDelta) > 3)
		{
			if (isTapping)
			{
				isDragging = true;

				var curDpad = Controls.instance.isInSubstate
					? MusicBeatSubstate.instance.touchPad
					: MusicBeatState.getState().touchPad;

				if (curDpad != null)
					curDpad.active = false;

				isTapping = false;
			}
			else if (!isDragging)
				return;

			var dragMove = curDelta * scrollScale;

			partialScrollTracker += dragMove;
			onPartialScroll.dispatch(dragMove);

			if (Math.abs(Math.round(partialScrollTracker)) >= 1)
			{
				var fullScroll = Math.round(partialScrollTracker);
				partialScrollTracker -= fullScroll;
				onFullScroll.dispatch(fullScroll);
			}
		}
	}

	private function getJustReleasedTouch():FlxTouch
	{
		for (touch in FlxG.touches.list)
			if (touch.justReleased)
				return touch;
		return null;
	}

	private function getDeltaY():Float
	{
		#if mobile
		var firstTouch = FlxG.touches.getFirst();
		if (firstTouch == null)
		{
			lastYPos = 0;
			return 0;
		}

		var curY:Float = firstTouch.screenY;

		if (lastYPos == 0)
		{
			lastYPos = curY;
			return 0;
		}

		var delta = curY - lastYPos;
		lastYPos = curY;
		return delta;
		#else
		return FlxG.mouse.deltaViewY;
		#end
	}
}
#end