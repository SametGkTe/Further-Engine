package backend;

import flixel.FlxState;
import flixel.FlxObject;
import backend.PsychCamera;
import mobile.MobileConfig;
import mobile.objects.FunkinMobilePad;
import mobile.objects.FunkinHitbox;

class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

	// ============ ESKİ MOBİL SİSTEM (geriye uyumluluk) ============
	public var touchPad:Dynamic;
	public var touchPadCam:FlxCamera;
	public var mobileControls:IMobileControls;
	public var mobileControlsCam:FlxCamera;

	// ============ YENİ MOBİL SİSTEM ============
	public var mobileManager:MobileControlManager;

	public inline function mobileButtonJustPressed(buttons:Dynamic):Bool
	{
		return mobileManager != null && mobileManager.mobilePad != null && mobileManager.mobilePad.justPressed(buttons);
	}

	public inline function mobileButtonPressed(buttons:Dynamic):Bool
	{
		return mobileManager != null && mobileManager.mobilePad != null && mobileManager.mobilePad.pressed(buttons);
	}

	public inline function mobileButtonJustReleased(buttons:Dynamic):Bool
	{
		return mobileManager != null && mobileManager.mobilePad != null && mobileManager.mobilePad.justReleased(buttons);
	}
	
	public function addTouchPadCamera(defaultDrawTarget:Bool = false):Void
	{
		#if mobile
		if (ClientPrefs.isTouchMode())
			return;
		#end

		if (touchPad != null)
		{
			touchPadCam = new FlxCamera();
			touchPadCam.bgColor.alpha = 0;
			FlxG.cameras.add(touchPadCam, defaultDrawTarget);
			touchPad.cameras = [touchPadCam];
		}
	}

	public inline function mobileButtonReleased(buttons:Dynamic):Bool
	{
		return mobileManager != null && mobileManager.mobilePad != null && mobileManager.mobilePad.released(buttons);
	}

	public function addTouchPad(DPad:String, Action:String, ?onScroll:Int->Void, ?onAccept:Void->Void, ?onBack:Void->Void)
	{
		#if mobile
		if (ClientPrefs.isTouchMode())
		{
			if (scrollableObject == null)
			{
				scrollableObject = new ScrollableObject(
					0.15,
					0,
					0,
					FlxG.width,
					FlxG.height
				);

				if (onScroll != null)
					scrollableObject.onFullScroll.add(onScroll);
				if (onAccept != null)
					scrollableObject.onTap.add(onAccept);
				if (onBack != null)
					scrollableObject.onSwipeRight.add(onBack);

				add(scrollableObject);
			}
			return;
		}
		#end

		if (MobileConfig.dpadModes != null
			&& MobileConfig.actionModes != null
			&& (MobileConfig.dpadModes.exists(DPad) || MobileConfig.actionModes.exists(Action) || DPad == 'NONE' || Action == 'NONE'))
		{
			touchPad = new FunkinMobilePad(DPad, Action, ClientPrefs.data.mobilePadAlpha);
		}
		else
		{
			touchPad = new TouchPad(DPad, Action);
		}

		add(touchPad);
	}

	public function removeTouchPad()
	{
		if (touchPad != null)
		{
			remove(touchPad);
			touchPad = FlxDestroyUtil.destroy(touchPad);
		}

		if (touchPadCam != null)
		{
			FlxG.cameras.remove(touchPadCam);
			touchPadCam = FlxDestroyUtil.destroy(touchPadCam);
		}
	}

	public function addMobileControls(defaultDrawTarget:Bool = false):Void
	{
		#if mobile
		if (ClientPrefs.isTouchMode())
			return;
		#end

		var extraMode = MobileData.extraActions.get(ClientPrefs.data.extraButtons);

		switch (MobileData.mode)
		{
			case 0: // RIGHT_FULL
				if (MobileConfig.dpadModes != null && MobileConfig.dpadModes.exists('RIGHT_FULL'))
				{
					var pad = new FunkinMobilePad('RIGHT_FULL', 'NONE', ClientPrefs.data.mobilePadAlpha);
					mobileControls = cast pad;
				}
				else
				{
					mobileControls = new TouchPad('RIGHT_FULL', 'NONE', extraMode);
				}

			case 1: // LEFT_FULL
				if (MobileConfig.dpadModes != null && MobileConfig.dpadModes.exists('LEFT_FULL'))
				{
					var pad = new FunkinMobilePad('LEFT_FULL', 'NONE', ClientPrefs.data.mobilePadAlpha);
					mobileControls = cast pad;
				}
				else
				{
					mobileControls = new TouchPad('LEFT_FULL', 'NONE', extraMode);
				}

			case 2: // CUSTOM
				// Şimdilik eski custom sistemi kalsın
				mobileControls = MobileData.getTouchPadCustom(new TouchPad('RIGHT_FULL', 'NONE', extraMode));

			case 3: // HITBOX
				if (ClientPrefs.data.ogGameControls)
				{
					var hitbox = new FunkinHitbox("V Slice", ClientPrefs.data.hitboxHint, ClientPrefs.data.hitboxAlpha);
					mobileControls = cast hitbox;
				}
				else
				{
					var hitboxMode:String = ClientPrefs.data.hitboxMode;
					if (hitboxMode == null || hitboxMode.trim() == "")
						hitboxMode = "Normal (New)";

					var hitbox = new FunkinHitbox(hitboxMode, ClientPrefs.data.hitboxHint, ClientPrefs.data.hitboxAlpha);
					mobileControls = cast hitbox;
				}
		}

		if (mobileControls != null && mobileControls.instance != null)
			mobileControls.instance = MobileData.setButtonsColors(mobileControls.instance);

		mobileControlsCam = new FlxCamera();
		mobileControlsCam.bgColor.alpha = 0;
		FlxG.cameras.add(mobileControlsCam, defaultDrawTarget);

		if (mobileControls != null && mobileControls.instance != null)
		{
			mobileControls.instance.cameras = [mobileControlsCam];
			mobileControls.instance.visible = false;
			add(mobileControls.instance);
		}
	}

	public function removeMobileControls()
	{
		if (mobileControls != null)
		{
			if (mobileControls.instance != null)
			{
				if (members.contains(mobileControls.instance))
					remove(mobileControls.instance);
				mobileControls.instance = FlxDestroyUtil.destroy(mobileControls.instance);
			}
			mobileControls = null;
		}

		if (mobileControlsCam != null)
		{
			FlxG.cameras.remove(mobileControlsCam);
			mobileControlsCam = FlxDestroyUtil.destroy(mobileControlsCam);
		}
	}
	
	public var scrollableObject:ScrollableObject;
	public function addTouchGestures(?scrollScale:Float = 1.0, ?clickButton:FlxObject, ?onScroll:Int->Void, ?onAccept:Void->Void, ?onBack:Void->Void):Void
	{
		#if mobile
		if (scrollableObject != null)
			removeTouchGestures();

		scrollableObject = new ScrollableObject(
			scrollScale,
			0,
			0,
			FlxG.width,
			FlxG.height,
			clickButton
		);

		if (onScroll != null)
			scrollableObject.onFullScroll.add(onScroll);

		if (onAccept != null)
			scrollableObject.onTap.add(onAccept);

		if (onBack != null)
			scrollableObject.onSwipeRight.add(onBack);

		add(scrollableObject);
		#end
	}

	public function removeTouchGestures():Void
	{
		#if mobile
		if (scrollableObject != null)
		{
			if (members.contains(scrollableObject))
				remove(scrollableObject);
			scrollableObject.destroy();
			scrollableObject = null;
		}
		#end
	}

	override function destroy()
	{
		removeTouchPad();
		removeMobileControls();
		removeTouchGestures();
		if (mobileManager != null)
			mobileManager.destroy();
		if (scrollableObject != null)
		{
			remove(scrollableObject);
			scrollableObject.destroy();
			scrollableObject = null;
		}

		super.destroy();
	}

	var _psychCameraInitialized:Bool = false;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static function getVariables()
		return getState().variables;

	override function create()
	{
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if (!_psychCameraInitialized)
			initPsychCamera();

		// YENİ: MobileControlManager oluştur
		mobileManager = new MobileControlManager(this);
		
		#if mobile
		scrollableObject = new ScrollableObject(
			1.0,
			0,
			0,
			FlxG.width,
			FlxG.height
		);
		add(scrollableObject);
		#end

		super.create();

		if (!skip)
		{
			openSubState(new CustomFadeTransition(0.5, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}

	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		stagesFunc(function(stage:BaseStage)
		{
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null)
	{
		if (nextState == null)
			nextState = FlxG.state;
		if (nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(nextState);
		else
			startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState()
	{
		if (FlxTransitionableState.skipNextTransIn)
			FlxG.resetState();
		else
			startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function startTransition(nextState:FlxState = null)
	{
		if (nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.5, false));
		if (nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState
	{
		return cast(FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	public var stages:Array<BaseStage> = [];

	public function beatHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if (stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}