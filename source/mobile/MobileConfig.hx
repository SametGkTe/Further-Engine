package mobile;

import flixel.util.FlxSave;
import mobile.backend.MobileData;

using StringTools;

enum ButtonModes {
	ACTION;
	DPAD;
	HITBOX;
}

class MobileConfig {
	public static var actionModes:Map<String, Dynamic> = new Map();
	public static var dpadModes:Map<String, Dynamic> = new Map();
	public static var hitboxModes:Map<String, Dynamic> = new Map();
	public static var mobileFolderPath:String = 'mobile/';
	public static var save:FlxSave;

	public static function init(saveName:String, savePath:String, mobilePath:String = 'mobile/', folders:Array<Array<Dynamic>>) {
		save = new FlxSave();
		save.bind(saveName, savePath);
		if (mobilePath != null && mobilePath != '') mobileFolderPath = (mobilePath.endsWith('/') ? mobilePath : mobilePath + '/');

		MobileData.init();
		actionModes = MobileData.actionModes;
		dpadModes = MobileData.dpadModes;
		hitboxModes = new Map();
	}
}

typedef MobileButtonsData = {
	buttons:Array<ButtonsData>
}

typedef CustomHitboxData = {
	hints:Array<HitboxData>,
	none:Array<HitboxData>,
	single:Array<HitboxData>,
	double:Array<HitboxData>,
	triple:Array<HitboxData>,
	quad:Array<HitboxData>
}

typedef HitboxData = {
	button:String,
	buttonIDs:Array<String>,
	buttonUniqueID:Dynamic,
	x:Dynamic,
	y:Dynamic,
	width:Dynamic,
	height:Dynamic,
	position:Array<Float>,
	scale:Array<Int>,
	color:String,
	returnKey:String,
	extraKeyMode:Null<Int>,
	topPosition:Array<Float>,
	topScale:Array<Int>,
	topColor:String,
	topReturnKey:String,
	topExtraKeyMode:Null<Int>,
	middlePosition:Array<Float>,
	middleScale:Array<Int>,
	middleColor:String,
	middleReturnKey:String,
	middleExtraKeyMode:Null<Int>,
	bottomPosition:Array<Float>,
	bottomScale:Array<Int>,
	bottomColor:String,
	bottomReturnKey:String,
	bottomExtraKeyMode:Null<Int>
}

typedef ButtonsData = {
	button:String,
	buttonIDs:Array<String>,
	buttonUniqueID:Dynamic,
	graphic:String,
	position:Array<Null<Float>>,
	color:String,
	scale:Null<Float>,
	returnKey:String
}
