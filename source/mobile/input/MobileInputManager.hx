/*
 * Copyright (C) 2025 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package mobile.input;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import haxe.ds.Map;

class MobileInputManager extends FlxTypedSpriteGroup<TouchButton>
{
	public var trackedButtons:Map<MobileInputID, TouchButton> = new Map<MobileInputID, TouchButton>();

	public function new()
	{
		super();
		updateTrackedButtons();
	}

	public inline function buttonPressed(button:MobileInputID):Bool
	{
		return anyPressed([button]);
	}

	public inline function buttonJustPressed(button:MobileInputID):Bool
	{
		return anyJustPressed([button]);
	}

	public inline function buttonJustReleased(button:MobileInputID):Bool
	{
		return anyJustReleased([button]);
	}

	public inline function buttonReleased(button:MobileInputID):Bool
	{
		return anyReleased([button]);
	}

	public inline function anyPressed(buttonsArray:Array<MobileInputID>):Bool
	{
		return checkButtonArrayState(buttonsArray, PRESSED);
	}

	public inline function anyJustPressed(buttonsArray:Array<MobileInputID>):Bool
	{
		return checkButtonArrayState(buttonsArray, JUST_PRESSED);
	}

	public inline function anyJustReleased(buttonsArray:Array<MobileInputID>):Bool
	{
		return checkButtonArrayState(buttonsArray, JUST_RELEASED);
	}

	public inline function anyReleased(buttonsArray:Array<MobileInputID>):Bool
	{
		return checkButtonArrayState(buttonsArray, RELEASED);
	}

	public function checkStatus(button:MobileInputID, state:ButtonsStates = JUST_PRESSED):Bool
	{
		switch (button)
		{
			case MobileInputID.ANY:
				for (button in trackedButtons.keys())
					if (checkStatusUnsafe(button, state) == true)
						return true;

			case MobileInputID.NONE:
				return false;

			default:
				if (trackedButtons.exists(button))
					return checkStatusUnsafe(button, state);
		}
		return false;
	}

	function checkButtonArrayState(Buttons:Array<MobileInputID>, state:ButtonsStates = JUST_PRESSED):Bool
	{
		if (Buttons == null)
			return false;

		for (button in Buttons)
			if (checkStatus(button, state))
				return true;

		return false;
	}

	function checkStatusUnsafe(button:MobileInputID, state:ButtonsStates = JUST_PRESSED):Bool
	{
		return switch (state)
		{
			case RELEASED: trackedButtons.get(button).released;
			case JUST_RELEASED: trackedButtons.get(button).justReleased;
			case PRESSED: trackedButtons.get(button).pressed;
			case JUST_PRESSED: trackedButtons.get(button).justPressed;
		}
	}

	public function updateTrackedButtons()
	{
		trackedButtons.clear();
		forEachExists(function(button:TouchButton)
		{
			if (button.IDs != null)
			{
				for (id in button.IDs)
				{
					if (!trackedButtons.exists(id))
					{
						trackedButtons.set(id, button);
					}
				}
			}
		});
	}
}

enum ButtonsStates
{
	PRESSED;
	JUST_PRESSED;
	RELEASED;
	JUST_RELEASED;
}
