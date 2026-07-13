package mikolka.vslice.components.crash;

import mikolka.funkin.custom.mobile.MobileScaleMode;
import mikolka.compatibility.VsliceOptions;
import mikolka.compatibility.ModsHelper;
import haxe.CallStack.StackItem;
import flixel.util.typeLimit.OneOfTwo;
import states.TitleState;
import states.MainMenuState;

class UserErrorSubstate extends MusicBeatSubstate
{
	var textBg:FlxSprite;

	var error:CrashData;
	var isCritical:Bool;
	var allowClosing:Bool = false;

	var camOverlay:FlxCamera;

	public static function makeMessage(errorMessage:String, description:String)
	{
		var state = FlxG.state;
		while (state.subState != null)
			state = state.subState;
		state.persistentUpdate = false;
		state.openSubState(new UserErrorSubstate(UserErrorSubstate.collectMessageData(errorMessage, description)));
	}

	public static function makeError(error:CrashData, isCritical:Bool = false)
	{
		var state = FlxG.state;
		while (state.subState != null)
			state = state.subState;
		state.persistentUpdate = false;
		state.openSubState(new UserErrorSubstate(error, isCritical));
	}

	public function new(error:CrashData, isCritical:Bool = false)
	{
		this.error = error;
		this.isCritical = isCritical;
		camOverlay = new FlxCamera();
		camOverlay.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(camOverlay);
		super();
	}

	override function create()
	{
		super.create();
		_parentState.persistentUpdate = false;
		textBg = new FlxSprite();
		FunkinTools.makeSolidColor(textBg, Math.floor(FlxG.width * 0.73), FlxG.height, 0x86000000);
		textBg.screenCenter();
		textBg.camera = camOverlay;
		add(textBg);

		printError(error);
	}

	public static function collectErrorData(errorMessage:String, callStack:Array<StackItem>):CrashData
	{
		var errMsg = new Array<Array<String>>();
		var errExtended = new Array<String>();
		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, pos_line, column):
					var line = new Array<String>();
					switch (s)
					{
						case Module(m):
							line.push("MD:" + m);
						case CFunction:
							line.push("Native function");
						case Method(classname, method):
							var regex = ~/(([A-Z]+[A-z]*)\.?)+/g;
							regex.match(classname);
							line.push("CLS:" + regex.matched(0) + ":" + method + "()");
						default:
							#if sys Sys.println #else trace #end (stackItem);
					}
					line.push("Line:" + pos_line);
					errMsg.push(line);
					errExtended.push('In file ${file}: ${line.join("  ")}');
				default:
					#if sys Sys.println #else trace #end (stackItem);
			}
		}
		return {
			logToFile: true,
			message: errorMessage,
			trace: errMsg,
			extendedTrace: errExtended,
			date: Date.now().toString(),
			systemName: getPlatform(),
			activeMod: ModsHelper.getActiveMod()
		}
	}

	public static function collectMessageData(errorMessage:String, description:String):CrashData
	{
		var tbl = new Array<Array<String>>();
		for (x in description.split("\n"))
		{
			tbl.push([x]);
		}
		return {
			logToFile: false,
			extendedTrace: [],
			trace: tbl,
			message: errorMessage,
			date: Date.now().toString(),
			systemName: getPlatform(),
			activeMod: ModsHelper.getActiveMod()
		};
	}

	public inline static function getPlatform():String
	{
		return #if android
			'Android'
		#elseif linux
			'Linux'
		#elseif mac
			'macOS'
		#elseif ios
			'iOS'
		#elseif windows
			'Windows'
		#elseif html5
			FlxG.html5.platform.getName() + '(${FlxG.html5.browser.getName()})'
		#else
			'Unknown'
		#end;
	}
    public inline static function getLogger():String
        {
            return switch(VsliceOptions.LOGGING){
                case "File": "Logs available in the 'latest.log' file";
                case "Console": "Check the console for logs";
                case "None": "Logs disabled!";
                default: "Is the logger corrupted???";
            }
        }

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!allowClosing)
			return;
		if (TouchUtil.justPressed || controls.ACCEPT)
		{
			FlxG.cameras.remove(camOverlay);
			if (!isCritical)
			{
				_parentState.persistentUpdate = true;
				close();
				return;
			}
			TitleState.initialized = false;
            ScreenshotPlugin.instance.destroy();
            ScreenshotPlugin.instance = null;
			TitleState.closedState = false;
			#if LEGACY_PSYCH
			if (Main.fpsVar != null)
				Main.fpsVar.visible = ClientPrefs.data.showFPS;
			#else
			if (Main.fpsVar != null)
				Main.fpsVar.visible = ClientPrefs.data.showFPS;
			#end
			FlxG.sound.pause();
			FlxTween.globalManager.clear();
			FlxG.resetGame();
		}
		#if sys
		else if (controls.BACK && isCritical)
		{
			Sys.exit(1);
		}
		#end
	}

	function printError(error:CrashData)
	{
		var star = #if (CHECK_FOR_UPDATES || debug) "" #else "*" #end;
		printToTrace('P-SLICE ${states.MainMenuState.psychEngineVersion}$star  (${error.message})');
		textNextY += 35;
		TimerUtil.wait(1 / 24, () ->
		{
			printSpaceToTrace();
			var linesPrinted = 0;
			for (line in error.trace)
			{
				linesPrinted += 1;
				switch (line.length)
				{
					case 1:
						if(line[0].length>43){
							var remText = line[0];
							while(remText.length>43){
								printToTrace(remText.substr(0,43));
								linesPrinted += 1;
								remText = remText.substr(42);
							}
							printToTrace(remText);
						}
						else printToTrace(line[0]);
					case 2:
						var first_line = line[0].rpad(" ", 33).replace("_", "");
						printToTrace('${first_line}${line[1]}');
					default:
						printToTrace(" ");
				}
			}
			var remainingLines = 11 - linesPrinted;
			if (remainingLines > 0)
			{
				for (x in 0...remainingLines)
				{
					printToTrace(" ");
				}
			}
			printSpaceToTrace();
			printToTrace('RUNTIME INFORMATION');
			var date_split = error.date.split(" ");
			printToTrace('TIME:${date_split[1].rpad(" ", 9)} DATE:${date_split[0]}');
			printToTrace('MOD:${error.activeMod.rpad(" ", 10)} PE:${MainMenuState.psychEngineVersion.rpad(" ", 5)} SYS:${error.systemName}');
			printSpaceToTrace();
            printToTrace(getLogger());
			if (isCritical)
				printToTrace('REPORT TO GITHUB.COM/MIKOLKA9144/P-SLICE');
			else
				printToTrace('');
			if (isCritical)
			{
				if (controls.mobileC)
					printToTrace('TAP ANYWHERE TO RESTART');
				else
					printToTrace('PRESS \'ACCEPT\' TO RESTART | \'BACK\' TO QUIT');
			}
			else
			{
				if (controls.mobileC)
					printToTrace('TAP ANYWHERE TO CONTINUE');
				else
					printToTrace('PRESS \'ACCEPT\' TO CONTINUE');
			}
			allowClosing = true;
		});
	}

	var textNextY = 5;

	function printToTrace(text:String):FlxText
	{
		var test_text = new FlxText(180+MobileScaleMode.gameCutoutSize.x/4, textNextY, FlxG.width * 0.71, text.toUpperCase());
		test_text.setFormat(Paths.font('vcr.ttf'), 35, FlxColor.WHITE, LEFT);
		test_text.updateHitbox();
		test_text.camera = camOverlay;
		add(test_text);
		textNextY += 35;
		return test_text;
	}

	function printSpaceToTrace()
	{
		textNextY += 10;
	}

}

typedef CrashData =
{
	logToFile:Bool,
	message:String,
	trace:Array<Array<String>>,
	extendedTrace:Array<String>,
	date:String,
	systemName:String,
	activeMod:String
}
