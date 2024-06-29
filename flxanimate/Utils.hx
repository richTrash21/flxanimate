package flxanimate;

#if ANIMATE_SYS_PATHS
import sys.FileSystem;
import sys.io.File;
import openfl.display.BitmapData;
#else
import openfl.Assets;
#end

class Utils
{
	public static function directory(path:String)
	{
		path = path.substring(0, path.lastIndexOf("/") + 1);
		return path.substring(path.lastIndexOf("/") + 1);
	}
	public static function extension(path:String):String
	{
		var cp = path.lastIndexOf(".");
		return cp == -1 ? "" : path.substring(cp + 1);
	}

	public static function withoutDirectory(path:String)
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