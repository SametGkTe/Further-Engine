package objects;

import openfl.Lib;
import objects.PopupThing;
import flixel.FlxG;
import backend.AuthManager;

class UPPopup
{
	static inline var COUNT_DURATION:Float = 2.0;
	static inline var MIN_TICK_INTERVAL:Float = 0.02;
	static inline var MAX_TICK_INTERVAL:Float = 0.12;
	static inline var ACCEL_FACTOR:Float = 3.0;

	static var _targetUP:Int = 0;
	static var _currentUP:Float = 0;
	static var _tickTimer:Float = 0;
	static var _finished:Bool = false;
	static var _totalElapsed:Float = 0;

	static function _getTips():Array<String>
	{
		var name:String = AuthManager.currentUsername;
		if (name == null || name == "" || name == "Player")
			name = "Oyuncu";

		return [
			"AYNEN BOYLE DEVAM ET, " + name + "!",
			"HARIKASIN " + name + "!",
			"DAHA İYİSİNİ YAPABİLİRSİN, " + name + "!",
			"DURDURULAMAZ " + name + "!",
			"MÜKEMMELİMSİ, " + name + "!",
			"KOMBO CANAVARI " + name + "!",
			"WOHOOO " + name + "!",
			"AYNI YAĞMUR GİBİ, " + name + "!",
			name + ", SEN BİR EFSANESİN!",
			name + ", YANIYORSUN!",
			"BU SKOR SANA YAKIŞTI, " + name + "!",
			name + ", KİMSE SENI DURDURAMAZ!",
			"HARIKA OYNUYORSUN, " + name + "!",
			name + " SAHNEYE ÇIKIYOR!",
			"TAM GAZ DEVAM, " + name + "!",
			name + ", NOTALAR SENİNLE DANS EDİYOR!"
		];
	}

	public static function show(earnedUP:Int, totalUP:Float, level:Int):Void
	{
		if (PopupMgr.instance == null)
			return;
		if (earnedUP <= 0)
			return;

		_targetUP = earnedUP;
		_currentUP = 0;
		_tickTimer = 0;
		_finished = false;
		_totalElapsed = 0;

		var tips = _getTips();
		var tip:String = tips[Std.int(Math.random() * tips.length)];

		var lines:Array<PopupLine> = [
			new PopupLine("KAZANILAN PUANLAR!", 16, 0xCCCCCC, true),
			new PopupLine("0 UP", 28, 0xFFD740, true),
			new PopupLine("", 11, 0x333333, false),
			new PopupLine(tip, 14, 0x69F0AE, false)
		];

		var holdTime:Float = COUNT_DURATION + 3.5;

		PopupMgr.instance.spawn(lines, holdTime, 0xFFFFD740, BOTTOM_RIGHT, null, function(popup:PopupThing, dt:Float) {
			if (_finished)
				return;

			_totalElapsed += dt;

			var progress:Float = _totalElapsed / COUNT_DURATION;
			if (progress > 1)
				progress = 1;

			var eased:Float = 1 - Math.pow(1 - progress, ACCEL_FACTOR);

			var interval:Float = MAX_TICK_INTERVAL - (MAX_TICK_INTERVAL - MIN_TICK_INTERVAL) * eased;

			_tickTimer += dt;

			if (_tickTimer >= interval)
			{
				_tickTimer = 0;

				var newVal:Int = Std.int(eased * _targetUP);
				if (newVal > _targetUP)
					newVal = _targetUP;

				if (newVal != Std.int(_currentUP))
				{
					_currentUP = newVal;

					var prefix:String = newVal >= _targetUP ? "" : "+";
					popup.updateLine(1, prefix + newVal + " UP");

					if (newVal >= _targetUP)
					{
						_finished = true;
						popup.updateLine(1, "+" + _targetUP + " UP");
						popup.updateLineColor(1, 0x69F0AE);
						_playSound('confirmMenu');
					}
					else
					{
						popup.shake(2.5, 0.06);
						_playSound('scrollMenu');
					}
				}
			}
		});
	}

	static function _playSound(name:String):Void
	{
		try
		{
			FlxG.sound.play(Paths.sound(name), 0.5);
		}
		catch (e:Dynamic)
		{
			trace('[UPPopup] Sound error: $e');
		}
	}
}