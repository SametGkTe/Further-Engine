package mobile.objects;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxSignal.FlxTypedSignal;
import mobile.input.MobileInputManager;

class BaseMobileControls extends FlxTypedSpriteGroup<MobileInputManager> implements IMobileControls
{
	public var buttonLeft:TouchButton = null;
	public var buttonUp:TouchButton = null;
	public var buttonRight:TouchButton = null;
	public var buttonDown:TouchButton = null;
	public var buttonExtra:TouchButton = null;
	public var buttonExtra2:TouchButton = null;
	public var instance:MobileInputManager = null;
	public var onButtonDown:FlxTypedSignal<TouchButton->Void> = null;
	public var onButtonUp:FlxTypedSignal<TouchButton->Void> = null;

	public function new()
	{
		super();
	}

	public function bindControl(control:MobileInputManager):Void
	{
		instance = control;
		buttonLeft = cast Reflect.field(control, 'buttonLeft');
		buttonUp = cast Reflect.field(control, 'buttonUp');
		buttonRight = cast Reflect.field(control, 'buttonRight');
		buttonDown = cast Reflect.field(control, 'buttonDown');
		buttonExtra = cast Reflect.field(control, 'buttonExtra');
		buttonExtra2 = cast Reflect.field(control, 'buttonExtra2');
		onButtonDown = cast Reflect.field(control, 'onButtonDown');
		onButtonUp = cast Reflect.field(control, 'onButtonUp');
	}

	public function clearBindings():Void
	{
		instance = null;
		buttonLeft = null;
		buttonUp = null;
		buttonRight = null;
		buttonDown = null;
		buttonExtra = null;
		buttonExtra2 = null;
		onButtonDown = null;
		onButtonUp = null;
	}
}