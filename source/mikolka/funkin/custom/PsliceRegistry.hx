package mikolka.funkin.custom;

import haxe.Json;
import mikolka.compatibility.funkin.FunkinPath;
import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.AssetType;
import backend.Paths;

class PsliceRegistry
{
	final regPath:String;

	public function new(registryName:String)
	{
		regPath = 'registry/$registryName';
	}

	function readJson(id:String):Dynamic
	{
		var relativePath = '$regPath/$id.json';
		var nativePath = FunkinPath.getPath(relativePath);
		var sharedPath = Paths.getSharedPath(relativePath);

		trace('[PsliceRegistry] Requested: ' + relativePath);
		trace('[PsliceRegistry] Resolved to: ' + nativePath);
		trace('[PsliceRegistry] Native exists: ' + NativeFileSystem.exists(nativePath));
		trace('[PsliceRegistry] Shared exists: ' + OpenFlAssets.exists(sharedPath, AssetType.TEXT));

		var text:String = null;

		if (NativeFileSystem.exists(nativePath))
		{
			text = NativeFileSystem.getContent(nativePath);
		}
		else if (OpenFlAssets.exists(sharedPath, AssetType.TEXT))
		{
			text = OpenFlAssets.getText(sharedPath);
		}

		if (text == null || text.length < 1)
			return null;

		return Json.parse(text);
	}

	function listJsons():Array<String>
	{
		var charPath = FunkinPath.getPath(regPath);

		if (NativeFileSystem.exists(charPath))
		{
			var basedCharFiles = NativeFileSystem.readDirectory(charPath);

			if (charPath == 'mods/$regPath')
			{
				var nativeChars = NativeFileSystem.readDirectory(FunkinPath.getPath(regPath, true));
				basedCharFiles = basedCharFiles.concat(nativeChars);
			}

			return basedCharFiles.filter(s -> s.endsWith(".json")).map(s -> s.substr(0, s.length - 5));
		}

		trace('[PsliceRegistry] listJsons() native path missing: ' + charPath);
		return [];
	}
}