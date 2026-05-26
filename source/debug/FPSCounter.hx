package debug;

import flixel.FlxG;
import openfl.Lib;
import haxe.Timer;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;
import lime.app.Application;
import backend.Language;

class FPSCounter extends TextField
{
	public var currentFPS(default, null):Int;
	public var memoryMegas(get, never):Float;
	public var memoryPeak:Float = 0;

	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var lastFramerateUpdateTime:Float;
	@:noCompletion private var updateTime:Int;
	@:noCompletion private var framesCount:Int;
	@:noCompletion private var prevTime:Int;

	public var os:String = '';

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		#if !officialBuild
		var systemText:String = Language.getPhrase('debug_system', 'System');
		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			os = '\n$systemText: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			os = '\n$systemText: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';
		#end

		positionFPS(x, y);

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		
		// VCR Font Ayarı
		var fontName:String = Paths.font("vcr.ttf");
		defaultTextFormat = new TextFormat(fontName, 14, color);
		embedFonts = true;
		
		width = FlxG.width;
		multiline = true;
		text = "FPS: ";

		times = [];
		lastFramerateUpdateTime = Timer.stamp();
		prevTime = Lib.getTimer();
		updateTime = prevTime + 500;
	}

	public dynamic function updateText():Void
	{
		if (memoryMegas > memoryPeak) memoryPeak = memoryMegas;

		// Dil dosyasından anahtarları çekiyoruz
		var memoryText:String = Language.getPhrase('debug_memory', 'Memory');
		var peakText:String = Language.getPhrase('debug_peak', 'Peak');
		var versionText:String = Language.getPhrase('debug_version', 'Version');
		var systemText:String = Language.getPhrase('debug_system', 'System'); // <--- Burayı ekledik

		// İşletim sistemi bilgisini de anlık dile göre oluşturuyoruz
		var osText:String = '';
		#if !officialBuild
		if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
			osText = '\n$systemText: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
		else
			osText = '\n$systemText: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';
		#end

		text = 
			'FPS: $currentFPS' + 
			'\n$memoryText: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)} ($peakText: ${flixel.util.FlxStringUtil.formatBytes(memoryPeak)})' +
			'\n$versionText: ${Application.current.meta.get('version')}' +
			osText; // Artık her güncellemede yeni sistem metnini kullanır

		textColor = 0xFFFFFFFF;
		if (currentFPS < FlxG.stage.window.frameRate * 0.5)
			textColor = 0xFFFF0000;
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		if (ClientPrefs.data.fpsRework) {
			var currentTime = openfl.Lib.getTimer();
			framesCount++;
			if (currentTime >= updateTime) {
				var elapsed = currentTime - prevTime;
				currentFPS = Math.ceil((framesCount * 1000) / elapsed);
				framesCount = 0;
				prevTime = currentTime;
				updateTime = currentTime + 500;
			}
		} else {
			final now:Float = haxe.Timer.stamp() * 1000;
			times.push(now);
			while (times[0] < now - 1000) times.shift();
			currentFPS = times.length;
		}

		updateText();
	}

	inline function get_memoryMegas():Float
		return cast(OpenFlSystem.totalMemory, Float);

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;
	}

	#if cpp
	private function getArch():String { 
		// ... (Önceki getArch fonksiyonun burada durmalı)
		return "Unknown"; 
	}
	#end
}