package flxanimate.animate;


import flxanimate.data.AnimationData.LayerType;
import flixel.math.FlxMath;
import haxe.extern.EitherType;
import flxanimate.data.AnimationData.Frame;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flxanimate.data.AnimationData.Layers;
import flxanimate.Utils;


class FlxLayer implements IFlxDestroyable
{
	@:allow(flxanimate.animate.FlxTimeline)
	var _parent(default, set):FlxTimeline;

	public var name(default, null):String;

	@:allow(flxanimate.animate.FlxKeyFrame)
	var _labels:Map<String, FlxKeyFrame>;

	public var type:LayerType;
	var _keyframes(default, null):Array<FlxKeyFrame>;

	public var visible:Bool;

	public var length(get, null):Int;

	public function new(?name:String, ?keyframes:Array<FlxKeyFrame>)
	{
		this.name = name;
		type = Normal;
		_keyframes = (keyframes != null) ? keyframes : [];
		visible = true;
		_labels = [];
	}

	public function hide()
	{
		visible = false;
	}
	public function show()
	{
		visible = true;
	}
	public function destroy()
	{
	}
	public function get(frame:EitherType<String, Int>)
	{
		var index = 0;
		if (frame is String)
		{
			if (!_labels.exists(frame)) return null;

			return _labels.get(frame);
		}
		else
		{
			index = frame;
			if (index > length) return null;
		}

		for (keyframe in _keyframes)
		{
			if (keyframe.index + keyframe.duration > index)
				return keyframe;
		}
		return null;
	}

	public function add(keyFrame:FlxKeyFrame)
	{
		if (keyFrame == null) return null;
		var index = keyFrame.index;
		if (keyFrame.name != null)
			_labels.set(keyFrame.name, keyFrame);

		var preKeyFrame:FlxKeyFrame;
		if (length == 0)
		{
			preKeyFrame = new FlxKeyFrame(0, 1);
			_keyframes.push(preKeyFrame);
		}
		else
		{
			preKeyFrame = get(cast FlxMath.bound(index, 0, length - 1));
		}
		var difference:Int = cast Math.abs(index - preKeyFrame.index);

		if (index == preKeyFrame.index)
		{
			keyFrame.duration += preKeyFrame.duration - 1;

			_keyframes.insert(_keyframes.indexOf(preKeyFrame), keyFrame);
			_keyframes.remove(preKeyFrame);
			preKeyFrame.destroy();
		}
		else
		{
			var dur = preKeyFrame.duration;
			preKeyFrame.duration += difference - dur;
			keyFrame.duration += cast FlxMath.bound(dur - difference - 1, 0);
			_keyframes.insert(_keyframes.indexOf(preKeyFrame) + 1, keyFrame);
		}

		keyFrame._parent = this;
		return keyFrame;
	}
	public function remove(frame:EitherType<Int, FlxKeyFrame>)
	{
		if ((frame is FlxKeyFrame))
		{
			_keyframes.remove(frame);
			return frame;
		}
		var index:Int = frame;
		if (length > index)
		{
			var keyframe = get(index);
			(keyframe.duration > 1) ? keyframe.duration-- : _keyframes.remove(keyframe);
			return keyframe;
		}
		return null;
	}
	public function rename(name:String = "")
	{
		if (Utils.isValidStr(name) && Utils.isValidStr(this.name))
		{
			name = 'Layer ${(_parent != null) ? _parent.getList().length : 1}';
		}
		if (_parent != null && _parent.get(name) != null)
		{
			name += " copy";
		}
		if (!Utils.isValidStr(name))
			this.name = name;
	}
	function set__parent(par:FlxTimeline)
	{
		_parent = par;
		rename();
		return par;
	}
	function get_length()
	{
		var keyframe = _keyframes[_keyframes.length - 1];
		return (keyframe != null) ? keyframe.index + keyframe.duration : 0;
	}
	public static function fromJSON(layer:Layers)
	{
		if (layer == null) return null;
		var frames = [];
		var l = new FlxLayer(layer.LN);
		if (layer.LT != null || layer.Clpb != null)
		{
			l.type = (layer.LT != null) ? Clipper : Clipped(layer.Clpb);
		}
		if (layer.FR != null)
		{
			for (frame in layer.FR)
			{
				l.add(FlxKeyFrame.fromJSON(frame));
			}
		}

		return l;
	}
}