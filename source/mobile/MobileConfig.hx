package mobile;

import haxe.Json;
import haxe.io.Path;
import flixel.util.FlxSave;
import openfl.utils.Assets;

using StringTools;

enum ButtonModes
{
	ACTION;
	DPAD;
	HITBOX;
}

class MobileConfig
{
	public static var actionModes:Map<String, MobileButtonsData> = new Map();
	public static var dpadModes:Map<String, MobileButtonsData> = new Map();
	public static var hitboxModes:Map<String, CustomHitboxData> = new Map();
	public static var mobileFolderPath:String = 'mobile/';

	public static var save:FlxSave;

	public static function init(saveName:String, savePath:String, mobilePath:String = 'mobile/', folders:Array<String>, modes:Array<ButtonModes>)
	{
		save = new FlxSave();
		save.bind(saveName, savePath);

		if (mobilePath != null && mobilePath != '')
			mobileFolderPath = mobilePath.endsWith('/') ? mobilePath : mobilePath + '/';

		for (i in 0...folders.length)
		{
			switch (modes[i])
			{
				case ACTION:
					readDirectoryPart1(mobileFolderPath + folders[i], actionModes, ACTION);

				case DPAD:
					readDirectoryPart1(mobileFolderPath + folders[i], dpadModes, DPAD);

				case HITBOX:
					readDirectoryPart1(mobileFolderPath + folders[i], hitboxModes, HITBOX);
			}
		}
	}

	static function readDirectoryPart1(folder:String, map:Dynamic, mode:ButtonModes)
	{
		folder = folder.contains(':') ? folder.split(':')[1] : folder;

		for (file in readDirectoryPart2(folder))
		{
			if (Path.extension(file) == 'json')
			{
				file = Path.join([folder, Path.withoutDirectory(file)]);

				if (!Assets.exists(file))
					continue;

				var str:String = Assets.getText(file);
				var mapKey:String = Path.withoutDirectory(Path.withoutExtension(file));

				if (mode == HITBOX)
				{
					var json:CustomHitboxData = cast Json.parse(str);
					normalizeHitboxData(json);
					map.set(mapKey, json);
				}
				else
				{
					var json:MobileButtonsData = cast Json.parse(str);
					normalizeButtonsData(json);
					map.set(mapKey, json);
				}
			}
		}
	}

	static function normalizeButtonsData(data:MobileButtonsData):Void
	{
		if (data == null || data.buttons == null)
			return;

		for (button in data.buttons)
		{
			if (button.position == null)
			{
				var x:Dynamic = Reflect.field(button, "x");
				var y:Dynamic = Reflect.field(button, "y");
				if (x != null && y != null)
					button.position = [x, y];
			}

			if (button.returned == null)
			{
				var r:Dynamic = Reflect.field(button, "returnKey");
				if (r != null)
					button.returned = Std.string(r);
			}
		}
	}

	static function normalizeHitboxData(data:CustomHitboxData):Void
	{
		normalizeHitboxArray(data.hints);
		normalizeHitboxArray(data.none);
		normalizeHitboxArray(data.single);
		normalizeHitboxArray(data.double);
		normalizeHitboxArray(data.triple);
		normalizeHitboxArray(data.quad);
	}

	static function normalizeHitboxArray(arr:Array<HitboxData>):Void
	{
		if (arr == null)
			return;

		for (button in arr)
		{
			if (button.position == null)
			{
				var x:Dynamic = Reflect.field(button, "x");
				var y:Dynamic = Reflect.field(button, "y");
				if (x != null && y != null)
					button.position = [x, y];
			}

			if (button.scale == null)
			{
				var w:Dynamic = Reflect.field(button, "width");
				var h:Dynamic = Reflect.field(button, "height");
				if (w != null && h != null)
					button.scale = [w, h];
			}

			if (button.returned == null)
			{
				var r:Dynamic = Reflect.field(button, "returnKey");
				if (r != null)
					button.returned = Std.string(r);
			}
		}
	}

	static function readDirectoryPart2(directory:String):Array<String>
	{
		var dirs:Array<String> = [];

		for (dir in Assets.list().filter(folder -> folder.startsWith(directory)))
		{
			@:privateAccess
			for (library in lime.utils.Assets.libraries.keys())
			{
				if (library != 'default' && Assets.exists('$library:$dir') && (!dirs.contains('$library:$dir') || !dirs.contains(dir)))
					dirs.push('$library:$dir');
				else if (Assets.exists(dir) && !dirs.contains(dir))
					dirs.push(dir);
			}
		}
		return dirs;
	}
}

typedef MobileButtonsData =
{
	var buttons:Array<ButtonsData>;
}

typedef CustomHitboxData =
{
	@:optional var hints:Array<HitboxData>;
	@:optional var none:Array<HitboxData>;
	@:optional var single:Array<HitboxData>;
	@:optional var double:Array<HitboxData>;
	@:optional var triple:Array<HitboxData>;
	@:optional var quad:Array<HitboxData>;
}

typedef HitboxData =
{
	var button:String;
	@:optional var buttonIDs:Array<String>;
	@:optional var buttonUniqueID:Dynamic;

	// library-compatible fields
	@:optional var position:Array<Float>;
	@:optional var scale:Array<Int>;

	// project-compatible fields
	@:optional var x:Dynamic;
	@:optional var y:Dynamic;
	@:optional var width:Dynamic;
	@:optional var height:Dynamic;

	var color:String;
	@:optional var returned:String;
	@:optional var returnKey:String;
	@:optional var extraKeyMode:Null<Int>;

	// Top
	@:optional var topX:Dynamic;
	@:optional var topY:Dynamic;
	@:optional var topWidth:Dynamic;
	@:optional var topHeight:Dynamic;
	@:optional var topColor:String;
	@:optional var topReturnKey:String;
	@:optional var topExtraKeyMode:Null<Int>;

	// Middle
	@:optional var middleX:Dynamic;
	@:optional var middleY:Dynamic;
	@:optional var middleWidth:Dynamic;
	@:optional var middleHeight:Dynamic;
	@:optional var middleColor:String;
	@:optional var middleReturnKey:String;
	@:optional var middleExtraKeyMode:Null<Int>;

	// Bottom
	@:optional var bottomX:Dynamic;
	@:optional var bottomY:Dynamic;
	@:optional var bottomWidth:Dynamic;
	@:optional var bottomHeight:Dynamic;
	@:optional var bottomColor:String;
	@:optional var bottomReturnKey:String;
	@:optional var bottomExtraKeyMode:Null<Int>;
}

typedef ButtonsData =
{
	var button:String;
	@:optional var buttonIDs:Array<String>;
	@:optional var buttonUniqueID:Dynamic;
	var graphic:String;

	// library-compatible
	@:optional var position:Array<Float>;

	// project-compatible
	@:optional var x:Float;
	@:optional var y:Float;

	var color:String;
	@:optional var scale:Null<Float>;
	@:optional var returned:String;
	@:optional var returnKey:String;
}