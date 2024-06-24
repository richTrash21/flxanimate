package flxanimate;

import openfl.geom.Matrix;
import openfl.geom.Point;
import flxanimate.Utils;
import flxanimate.interfaces.IFilterable;
import openfl.display.BlendMode;
import flixel.graphics.frames.FlxFramesCollection;
import haxe.extern.EitherType;
import flxanimate.display.FlxAnimateFilterRenderer;
import openfl.filters.BitmapFilter;
import flxanimate.geom.FlxMatrix3D;
import openfl.display.Sprite;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.FlxCamera;
import flxanimate.animate.*;
import flxanimate.zip.Zip;
import openfl.Assets;
import haxe.io.BytesInput;
import flixel.sound.FlxSound;
import flixel.FlxG;
import flxanimate.data.AnimationData;
import flixel.FlxSprite;
import flxanimate.animate.FlxAnim;
import flxanimate.frames.FlxAnimateFrames;
import flixel.math.FlxMatrix;
import openfl.geom.ColorTransform;
import flixel.math.FlxMath;
import flixel.FlxBasic;
import flixel.util.FlxPool;

typedef Settings = {
	?ButtonSettings:Map<String, flxanimate.animate.FlxAnim.ButtonSettings>,
	?FrameRate:Float,
	?Reversed:Bool,
	?OnComplete:Void->Void,
	?ShowPivot:Bool,
	?Antialiasing:Bool,
	?ScrollFactor:FlxPoint,
	?Offset:FlxPoint,
}

class DestroyableFlxMatrix extends FlxMatrix implements IFlxDestroyable {
	public function destroy() {
		identity();
	}
}

@:access(openfl.geom.ColorTransform)
@:access(openfl.geom.Rectangle)
@:access(flixel.graphics.frames.FlxFrame)
@:access(flixel.FlxCamera)
class FlxAnimate extends FlxSprite
{
	public static var matrixesPool:FlxPool<DestroyableFlxMatrix> = new FlxPool(DestroyableFlxMatrix);

	public var anim(default, null):FlxAnim;

	// #if FLX_SOUND_SYSTEM
	// public var audio:FlxSound;
	// #end

	var rect:Rectangle;

	var _symbols:Array<FlxSymbol>;

	public var showPivot(default, set):Bool;

	var _pivot:FlxFrame;
	var _indicator:FlxFrame;

	var renderer:FlxAnimateFilterRenderer = new FlxAnimateFilterRenderer();

	var filterCamera:FlxCamera;
	var filterCamera2:FlxCamera;

	public var relativeX:Float = 0;

	public var relativeY:Float = 0;

	/**
	 * # Description
	 * The `FlxAnimate` class calculates in real time a texture atlas through
	 * ## WARNINGS
	 * - This does **NOT** convert the frames into a spritesheet
	 * - Since this is some sort of beta, expect that there could be some inconveniences (bugs, crashes, etc).
	 *
	 * @param X 		The initial X position of the sprite.
	 * @param Y 		The initial Y position of the sprite.
	 * @param Path      The path to the texture atlas, **NOT** the path of the any of the files inside the texture atlas (`Animation.json`, `spritemap.json`, etc).
	 * @param Settings  Optional settings for the animation (antialiasing, framerate, reversed, etc.).
	 */
	public function new(X:Float = 0, Y:Float = 0, ?Path:String, ?Settings:Settings)
	{
		super(X, Y);
		anim = new FlxAnim(this);
		showPivot = false;
		if (Path != null)
			loadAtlas(Path);
		if (Settings != null)
			setTheSettings(Settings);


		rect = Rectangle.__pool.get();
	}

	public var isValid(default, null):Bool;
	/**
	 * Loads a regular atlas.
	 * @param Path The path where the atlas is located. Must be the folder, **NOT** any of the contents of it!
	 */
	public function loadAtlas(Path:String)
	{
		if (!Utils.exists('$Path/Animation.json') && haxe.io.Path.extension(Path) != "zip")
		{
			isValid = false;
			kill();
			FlxG.log.error('Animation file not found in specified path: "$Path", have you written the correct path?');
			return;
		}
		if (!isValid) revive();
		isValid = true;
		loadSeparateAtlas(atlasSetting(Path), FlxAnimateFrames.fromTextureAtlas(Path));
	}
	/**
	 * Function in handy to load atlases that share same animation/frames but dont necessarily mean it comes together.
	 * @param animation The animation file. This should be the content of the `JSON`, **NOT** the path of it.
	 * @param frames The collection of frames.
	 */
	public function loadSeparateAtlas(?animation:String = null, ?frames:FlxFramesCollection = null)
	{
		if (frames != null)
			this.frames = frames;
		if (animation != null)
		{
			/*
			var eReg = ~/"(F|filters)": /,
				eReg2 = ~/(\{([^{}]|(?R))*\})/s,
				eReg3 = ~/("(.+)")/;

			var lastMatch = 0, position, filterPos = null;


			while (eReg.matchSub(animation, lastMatch))
			{
				position = eReg.matchedPos();

				if (eReg2.matchSub(animation, position.pos + position.len))
				{

					var string = eReg2.matched(0);
					if (lastMatch == 0)
					{
						var pos = eReg2.matchedPos();
						filterPos = {pos: position.pos, len: position.len + (pos.pos - position.pos + pos.len)};
					}
					position = eReg2.matchedPos();

					var len = 0;
					var repeated:Map<String, Int> = [];
					while (eReg3.matchSub(animation, position.pos + len, filterPos.pos + filterPos.len))
					{
						var filter = eReg3.matched(0);
						position = eReg3.matchedPos();


						if (repeated.exists(filter))
						{
							var mod = '"${filter.substring(1, filter.length - 1)}_${repeated.get(filter) + 1}"';

							animation = animation.substring(0, position.pos) + mod + animation.substring(position.pos + position.len);
							repeated.set(filter, repeated.get(filter) + 1);
						}
						else
							repeated.set(filter, 0);

						len += position.len;

						if (eReg2.matchSub(animation, position.pos + len))
						{
							var pos = eReg2.matchedPos();
							len += (pos.pos - position.pos) + pos.len;
						}
					}

					position = eReg2.matchedPos();
				}

				lastMatch = position.pos + position.len;
			}
			*/
			var json:AnimAtlas = haxe.Json.parse(animation);

			anim._loadAtlas(json);
		}
		if (anim != null)
			origin = anim.curInstance.symbol.transformationPoint;
	}

	/**
	 * the function `draw()` renders the symbol that `anim` has currently plus a pivot that you can toggle on or off.
	 */
	public override function draw():Void
	{
		_matrix.identity();
		if (flipX)
		{
			_matrix.a *= -1;

			_matrix.tx += width;

		}
		if (flipY)
		{
			_matrix.d *= -1;
			_matrix.ty += height;
		}

		_flashRect.setEmpty();


		parseElement(anim.curInstance, _matrix, colorTransform, cameras, scrollFactor);

		width = _flashRect.width;
		height = _flashRect.height;
		frameWidth = Math.round(width);
		frameHeight = Math.round(height);

		relativeX = _flashRect.x - x;
		relativeY = _flashRect.y - y;

		if (showPivot)
		{
			var mat = matrixesPool.get();
			mat.tx = origin.x - _pivot.frame.width * 0.5;
			mat.ty = origin.y - _pivot.frame.height * 0.5;
			drawLimb(_pivot, mat, cameras);
			mat.tx = -_indicator.frame.width * 0.5;
			mat.ty = -_indicator.frame.height * 0.5;
			drawLimb(_indicator, mat, cameras);
			matrixesPool.put(mat);
		}
	}

	public var skew(default, null):FlxPoint = FlxPoint.get();

	static var _skewMatrix:FlxMatrix = new FlxMatrix();

	/**
	 * Tranformation matrix for this sprite.
	 * Used only when matrixExposed is set to true
	 */
	public var transformMatrix(default, null):Matrix = new Matrix();

	/**
	 * Bool flag showing whether transformMatrix is used for rendering or not.
	 * False by default, which means that transformMatrix isn't used for rendering
	 */
	public var matrixExposed:Bool = false;

	var st = 0;
	function parseElement(instance:FlxElement, m:FlxMatrix, colorFilter:ColorTransform, ?filterInstance:FlxElement = null, ?cameras:Array<FlxCamera> = null, ?scrollFactor:FlxPoint = null)
	{
		if (instance == null || !instance.visible)
			return;

		var mainSymbol = instance == anim.curInstance;
		var filterin = filterInstance != null;

		if (cameras == null)
			cameras = this.cameras;


		//if (scrollFactor == null)
		//	scrollFactor = FlxPoint.get();

		//var scroll = new FlxPoint().copyFrom(scrollFactor);

		var matrix = instance._matrix;

		matrix.copyFrom(instance.matrix);
		matrix.translate(instance.x, instance.y);
		matrix.concat(m);


		var colorEffect = instance._color;
		colorEffect.__copyFrom(colorFilter);


		var symbol = (instance.symbol != null) ? anim.symbolDictionary.get(instance.symbol.name) : null;

		if (instance.bitmap == null && symbol == null)
			return;

		if (instance.bitmap != null)
		{
			drawLimb(frames.getByName(instance.bitmap), matrix, colorEffect, filterin, cameras);
			return;
		}

		if (instance.symbol.cacheAsBitmap && (!filterin || filterInstance != instance))
		{
			if (instance.symbol._renderDirty)
			{
				instance.symbol._filterMatrix.copyFrom(instance.symbol.cacheAsBitmapMatrix);

				if (filterCamera == null)
					filterCamera = new FlxCamera(0, 0, 0, 0, 1);
				var colTr = ColorTransform.__pool.get();
				parseElement(instance, instance.symbol._filterMatrix, colTr, instance, [filterCamera]);
				ColorTransform.__pool.release(colTr);


				@:privateAccess
				renderFilter(instance.symbol, instance.symbol.filters, renderer);
				instance.symbol._renderDirty = false;

			}
			if (instance.symbol._filterFrame != null)
			{
				if (instance.symbol.colorEffect != null)
					colorEffect.concat(instance.symbol.colorEffect.c_Transform);

				matrix.copyFrom(instance.symbol._filterMatrix);
				matrix.concat(m);


				drawLimb(instance.symbol._filterFrame, matrix, colorEffect, filterin, instance.symbol.blendMode, cameras);
			}
		}
		else
		{
			if (instance.symbol.colorEffect != null && (!filterin || filterInstance != instance))
				colorEffect.concat(instance.symbol.colorEffect.c_Transform);

			final firstFrame:Int = switch (instance.symbol.type)
			{
				case Button: setButtonFrames();
				default: instance.symbol._curFrame;
			}

			var layers = symbol.timeline.getList();

			for (i in 0...layers.length)
			{
				var layer = layers[layers.length - 1 - i];

				if (!layer.visible && (!filterin && mainSymbol || !anim.metadata.showHiddenLayers) || layer.type == Clipper && layer._correctClip) continue;

				if (layer._clipper != null)
				{
					var layer = layer._clipper;
					layer._setCurFrame(firstFrame);
					var frame = layer._currFrame;
					if (frame._renderDirty)
					{
						if (filterCamera == null)
							filterCamera = new FlxCamera(0, 0, 0, 0, 1);
						var colTr = ColorTransform.__pool.get();
						var mat = matrixesPool.get();
						renderLayer(frame, mat, colTr, null, [filterCamera]);
						ColorTransform.__pool.release(colTr);
						matrixesPool.put(mat);

						layer._filterMatrix.identity();

						frame._renderDirty = false;
					}
				}

				layer._setCurFrame(firstFrame);

				var frame = layer._currFrame;

				if (frame == null) continue;

				var toBitmap = frame.filters != null || layer.type.getName() == "Clipped";

				var coloreffect = ColorTransform.__pool.get();
				coloreffect.__copyFrom(colorEffect);
				if (frame.colorEffect != null)
					coloreffect.concat(frame.colorEffect.__create());

				if (toBitmap)
				{
					if (!frame._renderDirty && layer._filterFrame != null)
					{
						var mat = matrixesPool.get();
						mat.copyFrom(layer._filterMatrix);
						mat.concat(matrix);

						drawLimb(layer._filterFrame, mat, coloreffect, filterin, cameras);
						matrixesPool.put(mat);
						continue;
					}
				}

				var mat = toBitmap ? matrixesPool.get() : matrix;
				renderLayer(frame, mat, coloreffect, toBitmap ? null : filterInstance, toBitmap ? [filterCamera] : cameras);

				if (toBitmap)
				{
					matrixesPool.put(cast mat);
					layer._filterMatrix.identity();

					if (filterCamera2 == null)
						filterCamera2 = new FlxCamera(0, 0, 0, 0, 1);
					renderFilter(layer, frame.filters, renderer, (layer._clipper != null) ? filterCamera2 : null);

					frame._renderDirty = false;

					var mat = matrixesPool.get();
					mat.copyFrom(layer._filterMatrix);
					mat.concat(matrix);

					drawLimb(layer._filterFrame, mat, coloreffect, filterin, cameras);
					matrixesPool.put(mat);
				}
				ColorTransform.__pool.release(coloreffect);
			}
		}
	}
	inline function renderLayer(frame:FlxKeyFrame, matrix:FlxMatrix, colorEffect:ColorTransform, ?instance:FlxElement = null, ?cameras:Array<FlxCamera>)
	{
		for (element in frame.getList())
			parseElement(element, matrix, colorEffect, instance, cameras);
	}
	function renderFilter(filterInstance:IFilterable, filters:Array<BitmapFilter>, renderer:FlxAnimateFilterRenderer, ?mask:FlxCamera)
	{
		var masking = mask != null;
		if (filterCamera == null)
			filterCamera = new FlxCamera(0, 0, 0, 0, 1);
		filterCamera.render();

		var rect = filterCamera.canvas.getBounds(null);

		if (filters != null && filters.length > 0)
		{
			var extension = Rectangle.__pool.get();

			for (filter in filters)
			{
				@:privateAccess
				extension.__expand(-filter.__leftExtension,
					-filter.__topExtension, filter.__leftExtension
					+ filter.__rightExtension,
					filter.__topExtension
					+ filter.__bottomExtension);
			}
			rect.width += extension.width;
			rect.height += extension.height;
			rect.x = extension.x;
			rect.y = extension.y;

			Rectangle.__pool.release(extension);
		}

		filterInstance.updateBitmaps(rect);

		var gfx = renderer.graphicstoBitmapData(filterCamera.canvas.graphics, filterInstance._bmp1);

		if (gfx == null) return;

		var gfxMask = null;
		if (masking)
		{
			mask.render();
			gfxMask = renderer.graphicstoBitmapData(mask.canvas.graphics);
		}

		var b = Rectangle.__pool.get();

		@:privateAccess
		filterCamera.canvas.__getBounds(b, filterInstance._filterMatrix);

		var point:FlxPoint = null;

		@:privateAccess
		if (masking && gfxMask != null)
		{
			var extension = Rectangle.__pool.get();

			mask.canvas.__getBounds(extension, filterInstance._filterMatrix);

			point = FlxPoint.get(extension.x / b.width, extension.y / b.height);

			Rectangle.__pool.release(extension);
		}

		renderer.applyFilter(filterInstance._bmp1, filterInstance._filterFrame.parent.bitmap, filterInstance._bmp1, filterInstance._bmp2, filters, rect, gfxMask, point);
		point = FlxDestroyUtil.put(point);

		filterInstance._filterMatrix.translate(Math.round(b.x + rect.x), Math.round(b.y + rect.y));
		@:privateAccess
		filterCamera.clearDrawStack();
		filterCamera.canvas.graphics.clear();

		if (masking)
		{
			@:privateAccess
			mask.clearDrawStack();
			mask.canvas.graphics.clear();
		}

		Rectangle.__pool.release(b);
	}

	var pressed:Bool = false;
	function setButtonFrames()
	{
		var frame:Int = 0;
		#if (FLX_MOUSE && !mobile)
		var badPress:Bool = false;
		var goodPress:Bool = false;
		final isOverlaped:Bool = FlxG.mouse.overlaps(this);
		final isPressed = FlxG.mouse.pressed;
		if (isPressed && isOverlaped)
			goodPress = true;
		if (isPressed && !isOverlaped && !goodPress)
		{
			badPress = true;
		}
		if (!isPressed)
		{
			badPress = false;
			goodPress = false;
		}
		if (isOverlaped && !badPress)
		{
			@:privateAccess
			var event = anim.buttonMap.get(anim.curSymbol.name);
			if (FlxG.mouse.justPressed && !pressed)
			{
				if (event != null)
					new ButtonEvent((event.Callbacks != null) ? event.Callbacks.OnClick : null #if FLX_SOUND_SYSTEM, event.Sound #end).fire();
				pressed = true;
			}
			frame = (FlxG.mouse.pressed) ? 2 : 1;

			if (FlxG.mouse.justReleased && pressed)
			{
				if (event != null)
					new ButtonEvent((event.Callbacks != null) ? event.Callbacks.OnRelease : null #if FLX_SOUND_SYSTEM, event.Sound #end).fire();
				pressed = false;
			}
		}
		else
		{
			frame = 0;
		}
		#else
		FlxG.log.error("Button stuff isn't available");
		#end
		return frame;
	}
	var _mat:FlxMatrix = new FlxMatrix();
	function drawLimb(limb:FlxFrame, _matrix:FlxMatrix, ?colorTransform:ColorTransform = null, filterin:Bool = false, blendMode:BlendMode = NORMAL, ?scrollFactor:FlxPoint = null, cameras:Array<FlxCamera> = null)
	{
		if (colorTransform != null && (colorTransform.alphaMultiplier == 0 || colorTransform.alphaOffset == -255) || limb == null || limb.type == EMPTY)
			return;

		if (cameras == null)
			cameras = this.cameras;

		for (camera in cameras)
		{
			_mat.identity();
			limb.prepareMatrix(_mat);
			var matrix = _mat;
			matrix.concat(_matrix);

			if (camera == null || !camera.visible || !camera.exists)
				return;


			if (!filterin)
			{
				getScreenPosition(_point, camera).subtractPoint(offset);
				if (limb == _pivot || limb == _indicator)
				{
					matrix.scale(0.9, 0.9);

					matrix.a /= camera.zoom;
					matrix.d /= camera.zoom;
					matrix.tx /= camera.zoom;
					matrix.ty /= camera.zoom;
				}
				else
				{
					matrix.translate(-origin.x, -origin.y);

					matrix.scale(scale.x, scale.y);

					if (bakedRotationAngle <= 0)
					{
						updateTrig();

						if (angle != 0)
							matrix.rotateWithTrig(_cosAngle, _sinAngle);
					}

					_point.addPoint(origin);
				}

				if (isPixelPerfectRender(camera))
				{
					_point.floor();
				}

				matrix.concat(matrixExposed ? transformMatrix : _skewMatrix);

				matrix.translate(_point.x, _point.y);

				if (!limbOnScreen(limb, matrix, camera))
					continue;
			}
			camera.drawPixels(limb, null, matrix, colorTransform, blendMode, (!filterin) ? antialiasing : true, null);
		}

		width = rect.width;
		height = rect.height;
		frameWidth = Std.int(width);
		frameHeight = Std.int(height);

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug && limb != _pivot && limb != _indicator)
		{
			var oldX = x;
			var oldY = y;

			x = rect.x;
			y = rect.y;
			drawDebug();
			x = oldX;
			y = oldY;
		}
		#end
		#if FLX_DEBUG
		FlxBasic.visibleCount++;
		#end
	}

	function limbOnScreen(limb:FlxFrame, m:FlxMatrix, ?Camera:FlxCamera = null)
	{
		if (Camera == null)
			Camera = FlxG.camera;

		limb.frame.copyToFlash(rect);

		rect.offset(-rect.x, -rect.y);

		rect.__transform(rect, m);

		_point.copyFromFlash(rect.topLeft);

		//if ([_indicator, _pivot].indexOf(limb) == -1)
		if (_indicator != limb && _pivot != limb)
			_flashRect = _flashRect.union(rect);

		return Camera.containsPoint(_point, rect.width, rect.height);
	}

	override function destroy()
	{
		if (anim != null)
			anim.destroy();
		anim = null;

		filterCamera = FlxDestroyUtil.destroy(filterCamera);
		filterCamera2 = FlxDestroyUtil.destroy(filterCamera2);
		// #if FLX_SOUND_SYSTEM
		// if (audio != null)
		// 	audio.destroy();
		// #end
		super.destroy();
	}

	public override function updateAnimation(elapsed:Float)
	{
		anim.update(elapsed);
	}

	public function setButtonPack(button:String, callbacks:ClickStuff #if FLX_SOUND_SYSTEM , sound:FlxSound #end):Void
	{
		@:privateAccess
		anim.buttonMap.set(button, {Callbacks: callbacks, #if FLX_SOUND_SYSTEM Sound:  sound #end});
	}

	function set_showPivot(value:Bool)
	{
		if (value != showPivot)
		{
			showPivot = value;

			if (showPivot && _pivot == null)
			{
				_pivot = FlxGraphic.fromBitmapData(Assets.getBitmapData("flxanimate/images/pivot.png"), "__pivot").imageFrame.frame;
				_indicator = FlxGraphic.fromBitmapData(Assets.getBitmapData("flxanimate/images/indicator.png"), "__indicator").imageFrame.frame;
			}
		}

		return value;
	}

	/**
	 * Sets variables via a typedef. Something similar as having an ID class.
	 * @param Settings
	 */
	public function setTheSettings(?Settings:Settings):Void
	{
		@:privateAccess
		if (true)
		{
			antialiasing = Settings.Antialiasing;
			if (Settings.ButtonSettings != null)
			{
				anim.buttonMap = Settings.ButtonSettings;
				if (anim.symbolType != Button)
					anim.symbolType = Button;
			}
			if (Settings.Reversed != null)
				anim.reversed = Settings.Reversed;
			if (Settings.FrameRate != null)
				anim.framerate = (Settings.FrameRate > 0) ? anim.metadata.frameRate : Settings.FrameRate;
			if (Settings.OnComplete != null)
				anim.onComplete = Settings.OnComplete;
			if (Settings.ShowPivot != null)
				showPivot = Settings.ShowPivot;
			if (Settings.Antialiasing != null)
				antialiasing = Settings.Antialiasing;
			if (Settings.ScrollFactor != null)
				scrollFactor = Settings.ScrollFactor;
			if (Settings.Offset != null)
				offset = Settings.Offset;
		}
	}

	public static function fromSettings()
	{}

	function atlasSetting(Path:String)
	{
		var jsontxt:String = null;
		if (haxe.io.Path.extension(Path) == "zip")
		{
			var thing = Zip.readZip(Utils.getBytes(Path));

			for (list in Zip.unzip(thing))
			{
				if (list.fileName.indexOf("Animation.json") != -1)
				{
					jsontxt = list.data.toString();
					thing.remove(list);
					continue;
				}
			}
			@:privateAccess
			FlxAnimateFrames.zip = thing;
		}
		else
			jsontxt = Utils.getText('$Path/Animation.json');

		return jsontxt;
	}
}
