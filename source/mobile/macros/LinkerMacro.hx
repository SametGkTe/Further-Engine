package mobile.macros;

import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.xml.Printer;
import sys.FileSystem;

using haxe.io.Path;

@:nullSafety
class LinkerMacro
{
	public static macro function xml(?file_name:String = 'Build.xml'):Array<Field>
	{
		final pos = Context.currentPos();
		final sourcePath:String = FileSystem.absolutePath(Context.getPosInfos(pos).file.directory()).removeTrailingSlashes();
		final includeName:String = (file_name != null && file_name.length > 0) ? file_name : 'Build.xml';
		final fileToInclude:String = Path.join([sourcePath, includeName]);

		if (!FileSystem.exists(fileToInclude))
		{
			Context.error('The specified file "$fileToInclude" could not be found at "$sourcePath".', pos);
		}

		final includeElement:Xml = Xml.createElement('include');
		includeElement.set('name', fileToInclude);

		Context.getLocalClass().get().meta.add(':buildXml', [
			macro $v{Printer.print(includeElement, true)}
		], pos);

		return Context.getBuildFields();
	}
}