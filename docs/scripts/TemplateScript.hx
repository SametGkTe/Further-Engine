
function onCreate()
{
}

function onCreatePost()
{
}

function onDestroy()
{
}


function onSectionHit()
{
}

function onBeatHit()
{
}

function onStepHit()
{
}

function onUpdate(elapsed:Float)
{
}

function onUpdatePost(elapsed:Float)
{
}

function onStartCountdown()
{
	return Function_Continue;
}

function onCountdownStarted()
{
}

function onCountdownTick(tick:Countdown, counter:Int)
{
	switch(tick)
	{
		case Countdown.THREE:
		case Countdown.TWO:
		case Countdown.ONE:
		case Countdown.GO:
		case Countdown.START:
	}
}

function onSpawnNote(note:Note)
{
}

function onSongStart()
{
}

function onEndSong()
{
	return Function_Continue;
}


function onPause()
{
	return Function_Continue;
}

function onResume()
{
}

function onGameOver()
{
	return Function_Continue;
}

function onGameOverStart()
{
}

function onGameOverConfirm(retry:Bool)
{
}


function onNextDialogue(line:Int)
{
}

function onSkipDialogue(line:Int)
{
}


function onKeyPressPre(key:Int)
{
}

function onKeyReleasePre(key:Int)
{
}

function onKeyPress(key:Int)
{
}

function onKeyRelease(key:Int)
{
}

function onGhostTap(key:Int)
{
}


function goodNoteHitPre(note:Note)
{
}
function opponentNoteHitPre(note:Note)
{
}

function goodNoteHit(note:Note)
{
}
function opponentNoteHit(note:Note)
{
}

function noteMissPress(direction:Int)
{
}

function noteMiss(note:Note)
{
}


function preUpdateScore(miss:Bool)
{
	return Function_Continue;
}

function onUpdateScore(miss:Bool)
{
}

function onRecalculateRating()
{
	return Function_Continue;
}

function onMoveCamera(focus:String)
{

	if (focus == 'boyfriend')
	{
	}
	else if (focus == 'dad')
	{
	}
	else if (focus == 'gf')
	{
	}
}


function onEvent(name:String, value1:String, value2:String, strumTime:Float)
{

}

function onEventPushed(name:String, value1:String, value2:String, strumTime:Float)
{
}

function eventEarlyTrigger(name:String, value1:String, value2:String, strumTime:Float)
{

}


function onCustomSubstateCreate(name:String)
{
}

function onCustomSubstateCreatePost(name:String)
{
}

function onCustomSubstateUpdate(name:String, elapsed:Float)
{
}

function onCustomSubstateUpdatePost(name:String, elapsed:Float)
{
}

function onCustomSubstateDestroy(name:String)
{
}
