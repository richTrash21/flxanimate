package flxanimate.interfaces;

import flxanimate.FlxAnimate.FlxPooledCamera;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;

@:allow(flxanimate.FlxAnimate)
@:allow(flxanimate.filters.FlxAnimateFilterRenderer)
interface IFilterable
{
	private var _filterCamera:FlxPooledCamera;
	private var _filterFrame:FlxFrame;
	private var _bmp1:BitmapData;
	private var _bmp2:BitmapData;
	private var _filterMatrix:FlxMatrix;

	private function updateBitmaps(rect:Rectangle):Void;
}