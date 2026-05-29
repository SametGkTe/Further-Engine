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

package mobile.backend;

import haxe.io.Path;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if android
import sys.io.Process;
#end

/**
 * A merged storage class for mobile.
 * @author Karim Akra, Homura Akemi (HomuHomu833), ArkoseLabs
 */
class StorageUtil
{
	#if sys

	#if android
	public static var currentExternalStorageDirectory:String = null;
	public static var lastGettedPermission:Int = 0;
	#end

	public static function getStorageDirectory():String
		return #if android Path.addTrailingSlash(AndroidContext.getExternalFilesDir()) #elseif ios lime.system.System.documentsDirectory #else Sys.getCwd() #end;

	public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Void
	{
		final folder:String = #if android getExternalStorageDirectory() + #else Sys.getCwd() + #end 'saves/';
		try
		{
			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			File.saveContent('$folder/$fileName', fileData);
			if (alert)
				CoolUtil.showPopUp(Language.getPhrase('file_save_success', '{1} has been saved.', [fileName]), Language.getPhrase('mobile_success', "Success!"));
		}
		catch (e:Dynamic)
			if (alert)
				CoolUtil.showPopUp(Language.getPhrase('file_save_fail', '{1} couldn\'t be saved.\n({2})', [fileName, Std.string(e)]), Language.getPhrase('mobile_error', "Error!"));
			else
				trace('$fileName couldn\'t be saved. (${Std.string(e)})');
	}

	public static function getStorageRootDirectory():String
		return #if android Path.addTrailingSlash(getExternalStorageDirectory()) #elseif ios Path.addTrailingSlash(lime.system.System.documentsDirectory) #else Path.addTrailingSlash(Sys.getCwd()) #end;

	public static function getModsDirectory():String
		return getStorageRootDirectory() + 'mods/';

	public static function getModpackCacheDirectory():String
		return getStorageRootDirectory() + 'modpack-cache/';

	public static function getModpackDownloadDirectory():String
		return getModpackCacheDirectory() + 'downloads/';

	public static function getModpackTempDirectory():String
		return getModpackCacheDirectory() + 'temp/';

	public static function getModpackInstalledDirectory():String
		return getModpackCacheDirectory() + 'installed/';

	public static function ensureDirectory(path:String):Void
	{
		if (path == null || StringTools.trim(path) == '')
			return;
		if (!FileSystem.exists(path))
			FileSystem.createDirectory(path);
	}

	public static function ensureModpackDirectories():Void
	{
		final dirs:Array<String> = [
			getStorageRootDirectory(),
			getModsDirectory(),
			getModpackCacheDirectory(),
			getModpackDownloadDirectory(),
			getModpackTempDirectory(),
			getModpackInstalledDirectory()
		];

		for (dir in dirs)
		{
			try
			{
				ensureDirectory(dir);
			}
			catch (e:Dynamic)
			{
				trace('Directory create failed: $dir (${Std.string(e)})');
			}
		}
	}

	#if android
	public static function getExternalStorageDirectory():String
	{
		if (currentExternalStorageDirectory == null || StringTools.trim(currentExternalStorageDirectory) == '')
			return initExternalStorageDirectory();
		return Path.addTrailingSlash(currentExternalStorageDirectory);
	}

	public static inline function getCustomStoragePath():String
		return Path.addTrailingSlash(AndroidContext.getExternalFilesDir()) + 'storageModes.txt';

	public static function getCustomStorageDirectories(?doNotSeperate:Bool):Array<String>
	{
		var result:Array<String> = [];
		var curTextFile:String = getCustomStoragePath();

		if (!FileSystem.exists(curTextFile))
			return result;

		for (mode in CoolUtil.coolTextFile(curTextFile))
		{
			if (mode == null)
				continue;

			mode = StringTools.trim(mode);
			if (mode.length < 1)
				continue;

			mode = StringTools.replace(mode, 'Name: ', '');
			mode = StringTools.replace(mode, ' Folder: ', '|');

			var dat = mode.split("|");

			if (doNotSeperate == true)
				result.push(mode);
			else if (dat.length > 0)
				result.push(dat[0]);
		}

		return result;
	}

	public static function initExternalStorageDirectory():String
	{
		var daPath:String = '';
		var curStorageType:String = ClientPrefs.data.storageType;

		var rootDir:String = Path.addTrailingSlash(lime.system.System.applicationStorageDirectory);

		try
		{
			ensureDirectory(rootDir);

			if (!FileSystem.exists(rootDir + 'storagetype.txt'))
				File.saveContent(rootDir + 'storagetype.txt', curStorageType);
			else
			{
				var content:String = StringTools.trim(File.getContent(rootDir + 'storagetype.txt'));
				if (content != '')
					curStorageType = content;
			}
		}
		catch (e:Dynamic)
		{
			trace('Failed to read storagetype.txt: ${Std.string(e)}');
		}

		for (line in getCustomStorageDirectories(true))
		{
			if (line == null || StringTools.trim(line) == '')
				continue;
			if (StringTools.startsWith(line, curStorageType))
			{
				var dat = line.split("|");
				if (dat.length > 1)
					daPath = dat[1];
			}
		}

		var appFile:String = 'PsychEngine';
		try
		{
			var meta:Dynamic = lime.app.Application.current.meta;
			if (meta != null)
			{
				var f:Dynamic = meta.get('file');
				if (f != null)
				{
					var s:String = Std.string(f);
					if (StringTools.trim(s) != '')
						appFile = s;
				}
			}
		}
		catch (e:Dynamic) {}

		var appPackage:String = 'com.shadowmario.psychengine';
		try
		{
			var meta:Dynamic = lime.app.Application.current.meta;
			if (meta != null)
			{
				var p:Dynamic = meta.get('packageName');
				if (p != null)
				{
					var s:String = Std.string(p);
					if (StringTools.trim(s) != '')
						appPackage = s;
				}
			}
		}
		catch (e:Dynamic) {}

		switch (curStorageType)
		{
			case 'EXTERNAL':
				daPath = AndroidEnvironment.getExternalStorageDirectory() + '/.' + appFile;
			case 'EXTERNAL_OBB':
				daPath = AndroidContext.getObbDir();
			case 'EXTERNAL_MEDIA':
				daPath = AndroidEnvironment.getExternalStorageDirectory() + '/Android/media/' + appPackage;
			case 'EXTERNAL_DATA':
				daPath = AndroidContext.getExternalFilesDir();
			default:
				if (daPath == null || StringTools.trim(daPath) == '')
				{
					var ext:String = getExternalDirectory(curStorageType);
					if (ext != null && StringTools.trim(ext) != '')
						daPath = ext + '.' + appFile;
				}
		}

		if (daPath == null || StringTools.trim(daPath) == '')
			daPath = '/sdcard/.PsychEngine/';

		daPath = Path.addTrailingSlash(daPath);
		currentExternalStorageDirectory = daPath;

		try
		{
			ensureDirectory(getStorageDirectory());
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp(
				Language.getPhrase('create_directory_error', 'Please create directory to\n{1}\nPress OK to close the game', [getStorageDirectory()]),
				Language.getPhrase('mobile_error', "Error!")
			);
			lime.system.System.exit(1);
		}

		ensureModpackDirectories();

		try
		{
			ensureDirectory(getExternalStorageDirectory() + 'mods');
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp(
				Language.getPhrase('create_directory_error', 'Please create directory to\n{1}\nPress OK to close the game', [getExternalStorageDirectory()]),
				Language.getPhrase('mobile_error', "Error!")
			);
			lime.system.System.exit(1);
		}

		return daPath;
	}

	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions([
				'READ_MEDIA_IMAGES',
				'READ_MEDIA_VIDEO',
				'READ_MEDIA_AUDIO',
				'READ_MEDIA_VISUAL_USER_SELECTED'
			]);
		else
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

		if (!AndroidEnvironment.isExternalStorageManager())
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');

		if ((AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU
			&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_MEDIA_IMAGES'))
			|| (AndroidVersion.SDK_INT < AndroidVersionCode.TIRAMISU
				&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')))
		{
			CoolUtil.showPopUp(
				Language.getPhrase('permissions_message', 'İzinleri kabul ettiyseniz oyununuz sorunsuz açılacaktır, etmediyseniz izinler bölümünden tüm dosyalara erişime izin verin'),
				Language.getPhrase('mobile_notice', "Uyarı!")
			);
		}

		initExternalStorageDirectory();
	}

	public static function chmodPermission(fullPath:String):Int
	{
		var process = new Process("sh", ["-c", 'stat -c %a "$fullPath"']);
		var stringOutput:String = process.stdout.readAll().toString();
		process.close();
		lastGettedPermission = Std.parseInt(StringTools.trim(stringOutput));
		return lastGettedPermission;
	}

	public static function chmod(permissions:Int, fullPath:String):Void
	{
		var process = new Process("sh", ["-c", 'chmod -R $permissions "$fullPath"']);
		var exitCode:Int = process.exitCode();
		if (exitCode == 0)
			trace('Basarili: $fullPath dosyasinin izinleri ($permissions) olarak ayarlandi');
		else
		{
			var errorOutput:String = process.stderr.readAll().toString();
			trace('HATA: ($fullPath) dosyasi icin izin degistirme basarisiz. Cikis Kodu: $exitCode, Hata: $errorOutput');
		}
		process.close();
	}

	public static function checkExternalPaths(?splitStorage:Bool = false):Array<String>
	{
		var process = new Process("sh", ["-c", 'grep -o "/storage/....-...." /proc/mounts | paste -sd ","']);
		var paths:String = StringTools.trim(process.stdout.readAll().toString());
		process.close();

		if (paths == null || paths == '')
			return [];

		if (splitStorage)
			paths = StringTools.replace(paths, '/storage/', '');

		return paths.split(',');
	}

	public static function getExternalDirectory(externalDir:String):String
	{
		var daPath:String = '';
		for (path in checkExternalPaths())
		{
			if (path != null && path.indexOf(externalDir) != -1)
				daPath = StringTools.trim(path);
		}
		if (daPath == null || daPath == '')
			return '';
		return Path.addTrailingSlash(daPath);
	}

	#else
	// Non-android fallback
	public static function getExternalStorageDirectory():String
		return #if ios Path.addTrailingSlash(lime.system.System.documentsDirectory) #else Path.addTrailingSlash(Sys.getCwd()) #end;

	public static function requestPermissions():Void {}
	#end

	#end
}