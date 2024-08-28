package flxanimate;

import openfl.display.BitmapData;
#if ANIMATE_SYS_PATHS
import sys.FileSystem;
import sys.io.File;
#else
import openfl.Assets;
#end

class Utils
{
	public inline static function directory(path:String)
	{
		return path.substring(0, path.lastIndexOf("/"));
	}
	public inline static function withoutExtension(path:String):String
	{
		var cp = path.lastIndexOf(".");
		return cp == -1 ? path : path.substring(0, cp);
	}
	public inline static function extension(path:String):String
	{
		var cp = path.lastIndexOf(".");
		return cp == -1 ? null : path.substring(cp + 1);
	}

	@:access(openfl.display.BitmapData)
	public static function dispose(bmp:BitmapData)
	{
		if (bmp != null)
		{
			bmp.__texture?.dispose();
			bmp.dispose();
		}	
		return null;
	}

	public inline static function withoutDirectory(path:String)
		return path.substring(path.lastIndexOf("/") + 1);

	public inline static function getText(path:String)
		return #if ANIMATE_SYS_PATHS File.getContent(path)      #else Assets.getText(path) #end;
	
	public inline static function getBytes(path:String)
		return #if ANIMATE_SYS_PATHS File.getBytes(path)        #else Assets.getBytes(path) #end;

	public inline static function getBitmapData(path:String)
		return #if ANIMATE_SYS_PATHS BitmapData.fromFile(path)  #else Assets.getBitmapData(path) #end;

	public inline static function exists(path:String)
		return #if ANIMATE_SYS_PATHS FileSystem.exists(path)    #else Assets.exists(path) #end;
}