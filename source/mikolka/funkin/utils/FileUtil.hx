package mikolka.funkin.utils;

import haxe.io.Path;
import lime.utils.Bytes;

class FileUtil
{
	public static function createDirIfNotExists(dir:String):Void
	{
		#if sys
		if (!doesFileExist(dir))
		{
			sys.FileSystem.createDirectory(dir);
		}
		#end
	}

	public static function doesFileExist(path:String):Bool
	{

		return NativeFileSystem.exists(path);

	}
    public static function openFolder(pathFolder:String)
        {
          #if windows
          Sys.command('explorer', [pathFolder]);
          #elseif mac
          Sys.command('open', [pathFolder]);
          #elseif linux
          Sys.command('xdg-open', [pathFolder]);
          #end
      
        }

  public static function writeBytesToPath(path:String, data:Bytes, mode:FileWriteMode = Skip):Void
    {
      #if sys
      createDirIfNotExists(Path.directory(path));
      switch (mode)
      {
        case Force:
          sys.io.File.saveBytes(path, data);
        case Skip:
          if (!doesFileExist(path))
          {
            sys.io.File.saveBytes(path, data);
          }
          else
          {
          }
        case Ask:
          if (doesFileExist(path))
          {
            throw 'File already exists: $path';
          }
          else
          {
            sys.io.File.saveBytes(path, data);
          }
      }
      #else
      throw 'Direct file writing by path not supported on this platform.';
      #end
    }
}

enum FileWriteMode
{
  Force;

  Ask;

  Skip;
}
