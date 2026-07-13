package states.stages;
import objects.Note;

import states.stages.objects.*;

class Template extends BaseStage
{

	override function create()
	{
	}
	
	override function createPost()
	{
	}

	override function update(elapsed:Float)
	{
	}

	override function destroy()
	{
	}

	
	override function countdownTick(count:Countdown, num:Int)
	{
		switch(count)
		{
			case THREE: 
			case TWO: 
			case ONE: 
			case GO: 
			case START: 
		}
	}

	override function startSong()
	{
	}

	override function stepHit()
	{
	}
	override function beatHit()
	{
	}
	override function sectionHit()
	{
	}

	override function closeSubState()
	{
		if(paused)
		{
		}
	}

	override function openSubState(SubState:flixel.FlxSubState)
	{
		if(paused)
		{
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "My Event":
		}
	}
	override function eventPushed(event:objects.Note.EventNote)
	{
		switch(event.event)
		{
			case "My Event":
		}
	}
	override function eventPushedUnique(event:objects.Note.EventNote)
	{
		switch(event.event)
		{
			case "My Event":
				switch(event.value1)
				{
					case 'blah blah':

					case 'coolswag':
					
					default:
				}
		}
	}

	override function goodNoteHit(note:Note)
	{
	}

	override function opponentNoteHit(note:Note)
	{
	}

	override function noteMiss(note:Note)
	{
	}

	override function noteMissPress(direction:Int)
	{
	}
}