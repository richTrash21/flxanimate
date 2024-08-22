package flxanimate;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPool;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;

import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Sprite;
import openfl.filters.BitmapFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.Assets;

import flxanimate.animate.FlxAnim;
import flxanimate.animate.*;
import flxanimate.data.AnimationData;
import flxanimate.display.FlxAnimateFilterRenderer;
import flxanimate.frames.FlxAnimateFrames;
import flxanimate.geom.FlxMatrix3D;
import flxanimate.interfaces.IFilterable;
import flxanimate.zip.Zip;
import flxanimate.Utils;

import haxe.extern.EitherType;
import haxe.io.BytesInput;

typedef Settings = {
	?ButtonSettings:Map<String, flxanimate.animate.FlxAnim.ButtonSettings>,
	?FrameRate:Float,
	?Reversed:Bool,
	?OnComplete:String->String->Void,
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

	public var filters:Array<BitmapFilter> = null; // TODO?

	var _pivot:FlxFrame;
	var _indicator:FlxFrame;

	static var renderer:FlxAnimateFilterRenderer;

	// TODO: FlxCamerasPool
	var filterCamera(get, default):FlxCamera;
	inline function get_filterCamera():FlxCamera
	{
		if (filterCamera == null)
			filterCamera = new FlxCamera(0, 0, 0, 0, 1);
		return filterCamera;
	}
	var maskCamera(get, default):FlxCamera;
	inline function get_maskCamera():FlxCamera
	{
		if (maskCamera == null)
			maskCamera = new FlxCamera(0, 0, 0, 0, 1);
		return maskCamera;
	}

	@:isVar
	public var metadata(get, never):FlxMetaData;
	inline function get_metadata()
	{
		return anim.metadata;
	}
	
	@:isVar
	public var skipFilters(get, set):Bool;
	inline function get_skipFilters()
	{
		return metadata.skipFilters;
	}
	inline function set_skipFilters(i)
	{
		return metadata.skipFilters = i;
	}
	
	@:isVar
	public var skipBlends(get, set):Bool;
	inline function get_skipBlends()
	{
		return metadata.skipBlends ?? false;
	}
	inline function set_skipBlends(i)
	{
		return metadata.skipBlends = i;
	}

	@:isVar
	public var showHiddenLayers(get, set):Bool;
	inline function get_showHiddenLayers()
	{
		return metadata.showHiddenLayers ?? false;
	}
	inline function set_showHiddenLayers(i)
	{
		return metadata.showHiddenLayers = i;
	}
	
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
	 * @param predraw  Optional thing for init sizes.
	 */
	public function new(X:Float = 0, Y:Float = 0, ?Path:String, ?Settings:Settings)
	{
		if (FlxAnimate.renderer == null)
			FlxAnimate.renderer = new FlxAnimateFilterRenderer();
		super(X, Y);
		anim = new FlxAnim(this);
		showPivot = false;
		if (Path != null)
			loadAtlas(Path);
		if (Settings != null)
			setTheSettings(Settings);

		rect = Rectangle.__pool.get();
			
	}

	public var isValid(default, null):Bool = false;
	/**
	 * Loads a regular atlas.
	 * @param Path The path where the atlas is located. Must be the folder, **NOT** any of the contents of it!
	 */
	public function loadAtlas(Path:String)
	{
		if (!Utils.exists('$Path/Animation.json') && Utils.extension(Path) != "zip")
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
		if(alpha == 0) return;

		updateTrig();
		updateSkewMatrix();
	
		if (anim.curInstance != null)
		{
			_flashRect.setEmpty();
	
			anim.curInstance.updateRender(_lastElapsed, anim.curFrame, anim.symbolDictionary, anim.swfRender);
			_matrix.identity();
			if (flipX != anim.curInstance.flipX)
			{
				_matrix.a *= -1;
				// _matrix.tx += width;
			}
			if (flipY != anim.curInstance.flipY)
			{
				_matrix.d *= -1;
				// _matrix.ty += height;
			}
			if (frames != null)
				parseElement(anim.curInstance, _matrix, colorTransform, blend, cameras);
			width = _flashRect.width;
			height = _flashRect.height;
			frameWidth = Math.round(width);
			frameHeight = Math.round(height);
	
			relativeX = _flashRect.x - x;
			relativeY = _flashRect.y - y;	
		}

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

	function updateSkewMatrix():Void
	{
		_skewMatrix.identity();

		if (skew.x != 0 || skew.y != 0)
		{
			_skewMatrix.b = Math.tan(skew.y * FlxAngle.TO_RAD);
			_skewMatrix.c = Math.tan(skew.x * FlxAngle.TO_RAD);
		}
	}
	
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

	function parseElement(instance:FlxElement, m:FlxMatrix, colorFilter:ColorTransform, ?filterInstance:FlxElement = null, ?blendMode:BlendMode, ?cameras:Array<FlxCamera> = null)
	{
		if (instance == null || !instance.visible)
			return;

		var mainSymbol = instance == anim.curInstance;
		var filterin = filterInstance != null;

		if (cameras == null)
			cameras = this.cameras;

		var matrix = instance._matrix;

		matrix.copyFrom(instance.matrix);
		matrix.translate(instance.x, instance.y);
		matrix.concat(m);

		var colorEffect = instance._color;
		colorEffect.__copyFrom(colorFilter);

		var symbol:FlxSymbol = (instance.symbol != null) ? anim.symbolDictionary.get(instance.symbol.name) : null;

		if (instance.bitmap == null && symbol == null)
			return;

		if (!skipBlends && instance.symbol != null && instance.symbol.blendMode != NORMAL)
			blendMode = instance.symbol.blendMode;

		if (instance.bitmap != null)
		{
			drawLimb(frames.getByName(instance.bitmap), matrix, colorEffect, filterin, blendMode, cameras);
			return;
		}

		var cacheToBitmap = !skipFilters && (instance.symbol.cacheAsBitmap || this.filters != null && mainSymbol) && (!filterin || filterin && filterInstance != instance);

		if (cacheToBitmap)
		{
			if (instance.symbol._renderDirty)
			{
				instance.symbol._filterMatrix.identity();
				// instance.symbol._filterMatrix.copyFrom(instance.matrix);

				var colTr = ColorTransform.__pool.get();
				parseElement(instance, instance.symbol._filterMatrix, colTr, instance, blendMode, [filterCamera]);
				ColorTransform.__pool.release(colTr);

				@:privateAccess
				renderFilter(instance.symbol, instance.symbol.filters);
				instance.symbol._renderDirty = false;
			}

			if (instance.symbol._filterFrame != null)
			{
				if (instance.symbol.colorEffect != null)
					colorEffect.concat(instance.symbol.colorEffect.c_Transform);

				matrix.copyFrom(instance.symbol._filterMatrix);
				matrix.translate(instance.x, instance.y);
				matrix.concat(m);

				// matrix.concat(instance.symbol._filterMatrix);

				// matrix.concat(instance.matrix);
				// matrix.translate(instance.x, instance.y);
				// matrix.concat(m);
				// // matrix.copyFrom(instance.matrix);
				// // matrix.concat(instance.symbol._filterMatrix);
				// matrix.concat(instance.matrix);
				// matrix.translate(instance.x, instance.y);
				// matrix.concat(m);
				// matrix.concat(instance.matrix);
				// matrix.translate(instance.x, instance.y);
				// matrix.concat(m);

				drawLimb(instance.symbol._filterFrame, matrix, colorEffect, filterin, blendMode, cameras);
			}
		}
		else
		{
			if (instance.symbol.colorEffect != null && (!filterin || filterInstance != instance))
				colorEffect.concat(instance.symbol.colorEffect.c_Transform);

			final curIndexFrame:Int = switch (instance.symbol.type)
			{
				case Button: setButtonFrames();
				default:	 instance.symbol._curFrame;
			}

			var layers = symbol.timeline.getList();

			var mat_temp = matrixesPool.get();
			for (i in 0...layers.length)
			{
				var layer = layers[layers.length - 1 - i];

				if (!layer.visible && (!filterin && mainSymbol || !showHiddenLayers) || layer.type == Clipper && layer._correctClip) continue;

				if (layer._clipper != null)
				{
					var layer = layer._clipper;
					layer._setCurFrame(curIndexFrame);
					var frame = layer._currFrame;
					if (frame != null && frame._renderDirty)
					{
						var colTr = ColorTransform.__pool.get();
						layer._filterMatrix.identity();

						// var mat = matrixesPool.get();
						renderLayer(frame, layer._filterMatrix, colTr, null, blendMode, [filterCamera]);
						ColorTransform.__pool.release(colTr);
						// matrixesPool.put(mat);

						frame._renderDirty = false;
					}
				}

				layer._setCurFrame(curIndexFrame);

				var frame = layer._currFrame;

				if (frame == null) continue;

				var toBitmap = !skipFilters && ((frame.filters != null && frame.filters.length > 0) || layer.type == Clipper);

				var coloreffect = ColorTransform.__pool.get();
				coloreffect.__copyFrom(colorEffect);
				if (frame.colorEffect != null)
					coloreffect.concat(frame.colorEffect.__create());

				if (toBitmap && !frame._renderDirty && layer._filterFrame != null)
				{
					// mat_temp.copyFrom(matrix);
					// mat_temp.concat(layer._filterMatrix);
					mat_temp.copyFrom(layer._filterMatrix);
					mat_temp.translate(instance.x, instance.y);
					mat_temp.concat(m);
					// mat.concat(instance.matrix);
					// mat.translate(instance.x, instance.y);
					// mat.concat(matrix);

					drawLimb(layer._filterFrame, mat_temp, coloreffect, filterin, blendMode, cameras);
					ColorTransform.__pool.release(coloreffect);
					continue;
				}

				// var mat = toBitmap ? layer._filterMatrix : matrix;
				// if (toBitmap)
				// 	mat.identity();
				renderLayer(frame, matrix, coloreffect, toBitmap ? null : filterInstance, blendMode, toBitmap ? [filterCamera] : cameras);

				if (toBitmap)
				{
					// matrixesPool.put(cast mat);
					// mat.identity();
					renderFilter(layer, frame.filters, (layer._clipper != null) ? maskCamera : null);

					frame._renderDirty = false;

					// mat_temp.copyFrom(matrix);
					// mat_temp.concat(layer._filterMatrix);

					mat_temp.copyFrom(layer._filterMatrix);
					mat_temp.translate(instance.x, instance.y);
					mat_temp.concat(m);

					// mat.concat(matrix);
					// mat.concat(m);
					// mat.concat(matrix);

					drawLimb(layer._filterFrame, mat_temp, coloreffect, filterin, blendMode, cameras);
				}
				ColorTransform.__pool.release(coloreffect);
			}
			matrixesPool.put(mat_temp);
		}
	}
	inline function renderLayer(frame:FlxKeyFrame, matrix:FlxMatrix, colorEffect:ColorTransform, ?instance:FlxElement = null, ?blendMode:BlendMode, ?cameras:Array<FlxCamera>)
	{
		for (element in frame.getList())
			parseElement(element, matrix, colorEffect, instance, blendMode, cameras);
	}
	@:access(flixel.FlxCamera)
	@:access(openfl.display.DisplayObject)
	@:access(openfl.filters.BitmapFilter)
	function renderFilter(filterInstance:IFilterable, filters:Array<BitmapFilter>, ?mask:FlxCamera)
	{
		var masking = mask != null;
		filterCamera.render();

		var rect = filterCamera.canvas.getBounds(null);

		if (filters != null && filters.length > 0)
		{
			var extension = Rectangle.__pool.get();

			for (filter in filters)
			{
				extension.__expand(-filter.__leftExtension, -filter.__topExtension,
					filter.__leftExtension + filter.__rightExtension,
					filter.__topExtension + filter.__bottomExtension);
			}
			rect.width += extension.width * 1.5;
			rect.height += extension.height * 1.5;
			rect.x = extension.x * 1.5;
			rect.y = extension.y * 1.5;

			Rectangle.__pool.release(extension);
		}
		else
		{
			rect.x = rect.y = 0;
		}

		filterInstance.updateBitmaps(rect);

		var gfx = FlxAnimate.renderer.graphicstoBitmapData(filterCamera.canvas.graphics, filterInstance._bmp1);

		if (gfx == null) return;

		var gfxMask = null;
		if (masking)
		{
			mask.render();
			gfxMask = FlxAnimate.renderer.graphicstoBitmapData(mask.canvas.graphics);
		}

		var b = Rectangle.__pool.get();

		static var staticLocalMatrixLol = new Matrix();
		filterCamera.canvas.__getBounds(b, staticLocalMatrixLol);

		var point:FlxPoint = null;

		if (masking && gfxMask != null)
		{
			var extension = Rectangle.__pool.get();

			mask.canvas.__getBounds(extension, staticLocalMatrixLol);

			point = FlxPoint.get(extension.x / b.width, extension.y / b.height);

			Rectangle.__pool.release(extension);
		}

		FlxAnimate.renderer.applyFilter(gfx, filterInstance._filterFrame.parent.bitmap, filterInstance._bmp1, filterInstance._bmp2, filters, rect, gfxMask, point);
		point = FlxDestroyUtil.put(point);

		filterInstance._filterMatrix.identity();
		// filterInstance._filterMatrix.translate(Math.round(b.x + rect.x), Math.round(b.y + rect.y));
		 filterInstance._filterMatrix.translate(b.x + rect.x, b.y + rect.y);
		// filterInstance._filterMatrix.translate(b.x, b.y);
		// filterInstance._filterMatrix.translate(rect.x, rect.y);
		filterCamera.clearDrawStack();
		filterCamera.canvas.graphics.clear();

		if (masking)
		{
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
					new ButtonEvent((event.Callbacks != null) ? event.Callbacks.OnClick : null #if FLX_SOUND_SYSTEM , event.Sound #end).fire();
				pressed = true;
			}
			frame = (FlxG.mouse.pressed) ? 2 : 1;

			if (FlxG.mouse.justReleased && pressed)
			{
				if (event != null)
					new ButtonEvent((event.Callbacks != null) ? event.Callbacks.OnRelease : null #if FLX_SOUND_SYSTEM , event.Sound #end).fire();
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
	static var _mat:FlxMatrix = new FlxMatrix();
	function drawLimb(limb:FlxFrame, _matrix:FlxMatrix, ?colorTransform:ColorTransform = null, filterin:Bool = false, ?blendMode:BlendMode, cameras:Array<FlxCamera> = null)
	{
		if (/*colorTransform != null && (colorTransform.alphaMultiplier == 0 || colorTransform.alphaOffset == -255) ||*/ limb == null || limb.type == EMPTY)
			return;

		if (cameras == null)
			cameras = this.cameras;

		for (camera in cameras)
		{
			if (camera == null || !camera.visible || !camera.exists)
				return;

			limb.prepareMatrix(_mat);
			_mat.concat(_matrix);

			if (!filterin)
			{
				getScreenPosition(_point, camera).subtractPoint(offset);
				if (limb == _pivot || limb == _indicator)
				{
					_mat.scale(0.9, 0.9);

					_mat.a /= camera.zoom;
					_mat.d /= camera.zoom;
					_mat.tx /= camera.zoom;
					_mat.ty /= camera.zoom;
				}
				else
				{
					_mat.translate(-origin.x, -origin.y);

					_mat.scale(scale.x, scale.y);

					if (bakedRotationAngle <= 0)
					{
						if (angle != 0)
							_mat.rotateWithTrig(_cosAngle, _sinAngle);
					}

					_point.addPoint(origin);
				}

				if (isPixelPerfectRender(camera))
				{
					_point.floor();
				}

				_mat.concat(matrixExposed ? transformMatrix : _skewMatrix);

				_mat.translate(_point.x, _point.y);

				if (!limbOnScreen(limb, _mat, camera))
					continue;
				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}
			camera.drawPixels(limb, null, _mat, colorTransform, blendMode, filterin || antialiasing, this.shader);
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug && limb != _pivot && limb != _indicator)
		{
			width = rect.width;
			height = rect.height;
			frameWidth = Std.int(width);
			frameHeight = Std.int(height);
	
			var oldX = x;
			var oldY = y;

			x = rect.x;
			y = rect.y;
			drawDebug();
			x = oldX;
			y = oldY;
		}
		#end
	}

	function limbOnScreen(limb:FlxFrame, m:FlxMatrix, ?Camera:FlxCamera = null)
	{
		if (Camera == null)
			Camera = FlxG.camera;

		limb.frame.copyToFlash(rect);

		rect.setTo(0, 0, rect.width, rect.width);

		rect.__transform(rect, m);

		_point.set(rect.x, rect.y);

		if (_indicator != limb && _pivot != limb)
		{
			if (_flashRect.width == 0 || _flashRect.height == 0)
			{
				_flashRect.copyFrom(rect);
			}
			else if (rect.width != 0 && rect.height != 0)
			{
				var x0 = _flashRect.x > rect.x ? rect.x : _flashRect.x;
				var y0 = _flashRect.y > rect.y ? rect.y : _flashRect.y;
				var x1 = _flashRect.right < rect.right ? rect.right : _flashRect.right;
				var y1 = _flashRect.bottom < rect.bottom ? rect.bottom : _flashRect.bottom;
	
				_flashRect.setTo(x0, y0, x1 - x0, y1 - y0);
			}	
		}

		return Camera.containsPoint(_point, rect.width, rect.height);
	}

	override function destroy()
	{
		anim = FlxDestroyUtil.destroy(anim);
		filterCamera = FlxDestroyUtil.destroy(filterCamera);
		maskCamera = FlxDestroyUtil.destroy(maskCamera);
		// #if FLX_SOUND_SYSTEM
		// if (audio != null)
		// 	audio.destroy();
		// #end
		super.destroy();
	}

	var _lastElapsed:Float;
	public override function updateAnimation(elapsed:Float)
	{
		anim.update(_lastElapsed = elapsed);
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

			if (showPivot)
			{
				if (_pivot == null)
					_pivot = FlxGraphic.fromBitmapData(Assets.getBitmapData("flxanimate/images/pivot.png"), "__pivot").imageFrame.frame;
				if (_indicator == null)
					_indicator = FlxGraphic.fromBitmapData(Assets.getBitmapData("flxanimate/images/indicator.png"), "__indicator").imageFrame.frame;
			}
		}

		return value;
	}

	/**
	 * Sets variables via a typedef. Something similar as having an ID class.
	 * @param Settings
	 */
	@:access(flxanimate.animate.FlxAnim)
	public function setTheSettings(?Settings:Settings):Void
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
				anim.framerate = (Settings.FrameRate > 0) ? metadata.frameRate : Settings.FrameRate;
			if (Settings.OnComplete != null)
				anim.onComplete.add(Settings.OnComplete);
			if (Settings.ShowPivot != null)
				showPivot = Settings.ShowPivot;
			if (Settings.Antialiasing != null)
				antialiasing = Settings.Antialiasing;
			if (Settings.ScrollFactor != null)
				scrollFactor = Settings.ScrollFactor;
			if (Settings.Offset != null)
				offset = Settings.Offset;
	}

	public static function fromSettings()
	{}

	function atlasSetting(Path:String)
	{
		var jsontxt:String = null;
		if (Utils.extension(Path) == "zip")
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
