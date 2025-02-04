package flxanimate.animate;

import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;
import openfl.geom.ColorTransform;
import flxanimate.data.AnimationData;

class SymbolParameters
{
	public var instance:String;

	public var type(default, set):SymbolT;

	public var loop(default, set):Loop;

	public var reverse:Bool;

	public var firstFrame:Int;

	public var name:String;

	public var colorEffect(default, set):ColorEffect;

	public var filters:Array<openfl.filters.BitmapFilter>;

	@:allow(flxanimate.FlxAnimate)
	@:allow(flxanimate.animate.FlxAnim)
	var _colorEffect(default, null):ColorTransform;

	public var transformationPoint:FlxPoint;


	public function new(?name = null, ?instance:String = "", ?type:SymbolT = Graphic, ?loop:Loop = Loop)
	{
		this.name = name;
		this.instance = instance;
		this.type = type;
		this.loop = loop;
		firstFrame = 0;
		transformationPoint = FlxPoint.get();
		colorEffect = None;
	}

	public function destroy()
	{
		instance = null;
		type = null;
		reverse = false;
		firstFrame = 0;
		name = null;
		if (_colorEffect != null)
			FlxAnimate.colorTransformsPool.release(_colorEffect);
		_colorEffect = null;
		transformationPoint = FlxDestroyUtil.put(transformationPoint);
		if (filters != null)
		{
			filters.splice(0, filters.length);
			filters = null;
		}
	}

	function set_type(type:SymbolT)
	{
		this.type = type;
		loop = type == null ? null : Loop;

		return type;
	}

	function set_loop(loop:Loop)
	{
		if (type == null) return this.loop = null;
		this.loop = switch (type)
		{
			case MovieClip:	Loop;
			case Button:	SingleFrame;
			default:		loop;
		}
		return loop;
	}

	function set_colorEffect(newEffect:ColorEffect)
	{
		// if (colorEffect != newEffect)
			_colorEffect = AnimationData.parseColorEffect(colorEffect = newEffect, _colorEffect);
		return newEffect;
	}
}
