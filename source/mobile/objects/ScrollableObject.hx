package mobile.objects;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.util.FlxSignal;
import flixel.input.touch.FlxTouch;
import mobile.backend.TouchUtil;

class ScrollableObject extends TouchZone
{
	// Olaylar
	public var onFullScroll:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	public var onPartialScroll:FlxTypedSignal<Float->Void> = new FlxTypedSignal<Float->Void>();
	public var onFullScrollSnap:FlxSignal = new FlxSignal();
	public var onTap:FlxSignal = new FlxSignal();
	public var onSwipeRight:FlxSignal = new FlxSignal();
	public var onSwipeLeft:FlxSignal = new FlxSignal();

	// Durumlar
	private var isDragging:Bool = false;
	private var isTapping:Bool = false;
	private var gestureDecided:Bool = false;
	private var gestureIsScroll:Bool = false;
	private var gestureIsSwipe:Bool = false;
	private var swipeFired:Bool = false;

	// Pozisyon takibi
	private var lastYPos:Float = 0;
	private var lastXPos:Float = 0;
	private var startX:Float = 0;
	private var startY:Float = 0;
	private var totalDeltaX:Float = 0;
	private var totalDeltaY:Float = 0;

	// Ayarlar
	private var partialScrollTracker:Float = 0;
	private var scrollScale:Float = 0;
	private var clickButton:FlxObject;

	/**
	 * Swipe olarak sayılması için gereken minimum yatay mesafe (piksel)
	 */
	public var swipeThreshold:Float = 120;

	/**
	 * Scroll olarak sayılması için gereken minimum dikey mesafe (piksel)
	 */
	public var scrollDeadzone:Float = 15;

	/**
	 * Gesture yönüne karar vermek için gereken minimum hareket (piksel)
	 */
	public var gestureDecisionThreshold:Float = 15;

	public function new(scrollScale:Float, x:Float, y:Float, width:Float, height:Float, ?clickButton:FlxObject)
	{
		this.scrollScale = scrollScale;
		this.clickButton = clickButton;
		super(x, y, width, height);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Dokunma başlangıcı
		#if mobile
		if (TouchUtil.justPressed && TouchUtil.overlaps(this))
		#else
		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(this, this.camera))
		#end
		{
			var pos = getCurrentPos();
			startX = pos.x;
			startY = pos.y;
			lastXPos = pos.x;
			lastYPos = pos.y;
			totalDeltaX = 0;
			totalDeltaY = 0;

			isDragging = false;
			isTapping = true;
			gestureDecided = false;
			gestureIsScroll = false;
			gestureIsSwipe = false;
			swipeFired = false;
			partialScrollTracker = 0;
		}
		// Dokunma bırakıldı
		else if (#if mobile TouchUtil.justReleased #else FlxG.mouse.justReleased #end)
		{
			if (isTapping && !isDragging)
			{
				// Tap = Accept
				if (clickButton != null)
				{
					#if mobile
					var touch:FlxTouch = getJustReleased();
					if (touch != null && clickButton.camera != null && touch.overlaps(clickButton, clickButton.camera))
						onTap.dispatch();
					#else
					if (clickButton.camera != null && FlxG.mouse.overlaps(clickButton, clickButton.camera))
						onTap.dispatch();
					#end
				}
				else
				{
					onTap.dispatch();
				}
			}
			else if (gestureIsScroll)
			{
				onFullScrollSnap.dispatch();
				setTouchPadActive(true);
			}

			// Reset
			isDragging = false;
			isTapping = false;
			gestureDecided = false;
			gestureIsScroll = false;
			gestureIsSwipe = false;
			swipeFired = false;
			partialScrollTracker = 0;
		}
		// Basılı tutma / sürükleme
		else if (#if mobile TouchUtil.pressed #else FlxG.mouse.pressed #end)
		{
			var pos = getCurrentPos();
			var curDeltaX:Float = pos.x - lastXPos;
			var curDeltaY:Float = pos.y - lastYPos;
			lastXPos = pos.x;
			lastYPos = pos.y;

			totalDeltaX = pos.x - startX;
			totalDeltaY = pos.y - startY;

			var absX:Float = Math.abs(totalDeltaX);
			var absY:Float = Math.abs(totalDeltaY);

			// Henüz gesture kararı verilmediyse
			if (!gestureDecided)
			{
				var totalMovement:Float = Math.sqrt(absX * absX + absY * absY);

				if (totalMovement > gestureDecisionThreshold)
				{
					gestureDecided = true;
					isTapping = false;
					isDragging = true;

					if (absX > absY)
					{
						// Yatay hareket baskın = swipe
						gestureIsSwipe = true;
						gestureIsScroll = false;
					}
					else
					{
						// Dikey hareket baskın = scroll
						gestureIsSwipe = false;
						gestureIsScroll = true;
						setTouchPadActive(false);
					}
				}
			}

			// Scroll işlemi
			if (gestureIsScroll && Math.abs(curDeltaY) > 0)
			{
				var dragMove:Float = curDeltaY * scrollScale;
				partialScrollTracker += dragMove;
				onPartialScroll.dispatch(dragMove);

				if (Math.abs(Math.round(partialScrollTracker)) >= 1)
				{
					var fullScroll:Int = Math.round(partialScrollTracker);
					partialScrollTracker -= fullScroll;
					onFullScroll.dispatch(fullScroll);
				}
			}

			// Swipe işlemi
			if (gestureIsSwipe && !swipeFired)
			{
				if (totalDeltaX > swipeThreshold)
				{
					// Sağa swipe = Back
					swipeFired = true;
					onSwipeRight.dispatch();
				}
				else if (totalDeltaX < -swipeThreshold)
				{
					// Sola swipe (opsiyonel)
					swipeFired = true;
					onSwipeLeft.dispatch();
				}
			}
		}
	}

	private function getCurrentPos():{x:Float, y:Float}
	{
		#if mobile
		var touch:FlxTouch = FlxG.touches.getFirst();
		if (touch == null)
			return {x: lastXPos, y: lastYPos};
		return {x: touch.screenX, y: touch.screenY};
		#else
		return {x: FlxG.mouse.screenX, y: FlxG.mouse.screenY};
		#end
	}

	private function setTouchPadActive(active:Bool):Void
	{
		try
		{
			var state = MusicBeatState.getState();
			if (state != null && state.touchPad != null)
				state.touchPad.active = active;
		}
		catch (e:Dynamic) {}
	}

	private function getJustReleased():FlxTouch
	{
		for (touch in FlxG.touches.list)
			if (touch.justReleased)
				return touch;
		return null;
	}
}