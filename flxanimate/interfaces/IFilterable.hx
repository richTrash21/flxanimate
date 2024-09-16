package flxanimate.interfaces;

import flxanimate.FlxAnimate.FlxPooledCamera;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;

interface IFilterable
{
	// @:allow(flxanimate.FlxAnimate)
	private var _filterCamera:FlxPooledCamera;
	@:allow(flxanimate.FlxAnimate)
	@:allow(flxanimate.filters.FlxAnimateFilterRenderer)
	private var _filterFrame:FlxFrame;
	@:allow(flxanimate.FlxAnimate)
	@:allow(flxanimate.filters.FlxAnimateFilterRenderer)
	private var _bmp1:BitmapData;
	@:allow(flxanimate.FlxAnimate)
	@:allow(flxanimate.filters.FlxAnimateFilterRenderer)
	private var _bmp2:BitmapData;
	@:allow(flxanimate.FlxAnimate)
	private var _filterMatrix:FlxMatrix;

	@:allow(flxanimate.FlxAnimate)
	private function updateBitmaps(rect:Rectangle):Void;
}