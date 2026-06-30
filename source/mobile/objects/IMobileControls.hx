package mobile.objects;

import flixel.util.FlxSignal.FlxTypedSignal;
import mobile.flixel.controls.InputHandler;
import mobile.flixel.controls.MobileControls;
import mobile.input.MobileInputID;

interface IMobileControls
{
	public var instance:MobileControls;

	public var onButtonDown:FlxTypedSignal<(InputHandler, String) -> Void>;
	public var onButtonUp:FlxTypedSignal<(InputHandler, String) -> Void>;

	public var buttonLeft:VirtualButton;
	public var buttonUp:VirtualButton;
	public var buttonRight:VirtualButton;
	public var buttonDown:VirtualButton;
	public var buttonExtra:VirtualButton;
	public var buttonExtra2:VirtualButton;

	public function anyPressed(keys:Array<MobileInputID>):Bool;
	public function anyJustPressed(keys:Array<MobileInputID>):Bool;
	public function anyJustReleased(keys:Array<MobileInputID>):Bool;
	public function anyReleased(keys:Array<MobileInputID>):Bool;
}