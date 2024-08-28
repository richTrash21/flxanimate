package flxanimate;

import flixel.animation.FlxAnimationController;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
#if FLX_SOUND_SYSTEM
import flixel.sound.FlxSound;
import flixel.sound.FlxSoundGroup;
#end
import flixel.system.FlxAssets.FlxGraphicAsset;
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
import haxe.ds.StringMap;
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

class FlxPooledMatrix extends FlxMatrix implements IFlxPooled
{
	static var pool:FlxPool<FlxPooledMatrix> = new FlxPool(FlxPooledMatrix);
	public function put()
	{
		pool.put(this);
	}
	public inline static function get()
	{
		return pool.get();
	}
	public function destroy() {
		identity();
	}
}

class FlxPooledCamera extends FlxCamera implements IFlxPooled
{
	static var pool:FlxPool<FlxPooledCamera> = new FlxPool(FlxPooledCamera);
	public function put()
	{
		pool.put(this);
	}
	public inline static function get()
	{
		return pool.get();
	}
	public override function destroy() {
		clearDrawStack();
		canvas.graphics.clear();
	}
	public function superDestroy()
	{
		super.destroy();
	}
}

@:access(openfl.geom.ColorTransform)
@:access(openfl.geom.Rectangle)
@:access(flixel.graphics.frames.FlxFrame)
@:access(flixel.FlxCamera)
class FlxAnimate extends FlxSprite // TODO: MultipleAnimateAnims suppost
{
	public var useAtlas(default, set):Bool = false;

	public var anim(default, null):FlxAnim;

	#if FLX_SOUND_SYSTEM
	public var audioGroup:FlxSoundGroup;
	#end

	var rect:Rectangle;

	public var showPivot(default, set):Bool;
	public var showPosPoint:Bool = true;
	public var showMidPoint:Bool = true;
	public var pivotScale:Float = 0.8;

	public var filters:Array<BitmapFilter> = null; // TODO?

	var _pivot:FlxFrame;
	var _indicator:FlxFrame;

	static var renderer:FlxAnimateFilterRenderer;

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
	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset, ?Settings:Settings)
	{
		if (FlxAnimate.renderer == null)
			FlxAnimate.renderer = new FlxAnimateFilterRenderer();
		super(X, Y);
		atlasIsValid = false;
		if (SimpleGraphic != null)
		{
			if (Std.isOfType(SimpleGraphic, String))
				loadAtlas(cast SimpleGraphic);
			else
				loadGraphic(SimpleGraphic);
		}
		if (Settings != null)
			setTheSettings(Settings);

		rect = Rectangle.__pool.get();
	}

	public var atlasIsValid(default, null):Bool = false;

	/**
	 * Loads a regular atlas.
	 * @param Path The path where the atlas is located. Must be the folder, **NOT** any of the contents of it!
	 */
	public function loadAtlas(Path:String)
	{
		if (!Utils.exists('$Path/Animation.json') && Utils.extension(Path) != "zip")
		{
			// kill();
			FlxG.log.error('Animation file not found in specified path: "$Path", have you written the correct path?');
			return;
		}
		// if (!atlasIsValid) revive();
		anim = FlxDestroyUtil.destroy(anim);
		anim = new FlxAnim(this);
		atlasIsValid = true;
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

	var _camerasCashePoints(default, null):Array<FlxPoint> = [];
	/**
	 * the function `draw()` renders the symbol that `anim` has currently plus a pivot that you can toggle on or off.
	 */
	public override function draw():Void
	{
		if(alpha == 0) return;
		updateSkewMatrix();

		if (useAtlas && atlasIsValid)
		{
			for (i => camera in cameras)
			{
				final _point:FlxPoint = getScreenPosition(_camerasCashePoints[i], camera).subtractPoint(offset);
				_point.addPoint(origin);
				_camerasCashePoints[i] = _point;
			}

			updateTrig();
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
				width = Math.abs(_flashRect.width);
				height = Math.abs(_flashRect.height);
				frameWidth = Math.round(width / scale.x);
				frameHeight = Math.round(height / scale.y);

				relativeX = _flashRect.x - x;
				relativeY = _flashRect.y - y;
			}
		}
		else
		{
			relativeX = relativeY = 0;
			super.draw();
		}

		if (showPivot && (showPosPoint || showMidPoint))
		{
			var mat = FlxPooledMatrix.get();
			if (showMidPoint)
			{
				mat.translate(-_pivot.frame.width * 0.5, -_pivot.frame.height * 0.5);
				mat.scale(pivotScale / camera.zoom, pivotScale / camera.zoom);
				mat.translate(origin.x, origin.y);
				// mat.translate(-offset.x, -offset.y);
				drawPivotLimb(_pivot, mat, cameras);
				mat.identity();
			}
			if (showPosPoint)
			{
				mat.translate(-_indicator.frame.width * 0.5, -_indicator.frame.height * 0.5);
				mat.scale(pivotScale / camera.zoom, pivotScale / camera.zoom);
				// mat.translate(-offset.x, -offset.y);
				drawPivotLimb(_indicator, mat, cameras);
			}
			mat.put();
		}
	}
	public override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		if (newRect == null)
			newRect = FlxRect.get();

		if (camera == null)
			camera = FlxG.camera;
		newRect.setPosition(x - relativeX, y - relativeY);
		if (pixelPerfectPosition)
			newRect.floor();
		_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);
		newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x;
		newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y;
		if (isPixelPerfectRender(camera))
			newRect.floor();
		newRect.setSize(frameWidth * Math.abs(scale.x), frameHeight * Math.abs(scale.y));
		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
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
	public var transformMatrix(default, null):FlxMatrix = new FlxMatrix();

	/**
	 * Bool flag showing whether transformMatrix is used for rendering or not.
	 * False by default, which means that transformMatrix isn't used for rendering
	 */
	public var matrixExposed:Bool = false;

	@:noCompletion
	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
		_matrix.concat(matrixExposed ? transformMatrix : _skewMatrix);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}

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

		final curIndexFrame:Int = switch (instance.symbol.type)
		{
			case Button: setButtonFrames(instance, matrix);
			default:	 instance.symbol._curFrame;
		}

		// var cacheToBitmap = !skipFilters && (instance.symbol.cacheAsBitmap/* || this.filters != null && mainSymbol*/) && filterInstance != instance;
		var cacheToBitmap = !skipFilters && (instance.symbol.cacheAsBitmap && filterInstance != instance);

		if (cacheToBitmap)
		{
			if (instance.symbol._renderDirty || instance.symbol._filterFrame == null)
			{
				instance.symbol._filterMatrix.identity();
				// instance.symbol._filterMatrix.concat(instance.matrix);

				var colTr = ColorTransform.__pool.get();
				var filterCamera = FlxPooledCamera.get();
				parseElement(instance, instance.symbol._filterMatrix, colTr, instance, null, [filterCamera]);

				@:privateAccess
				renderFilter(instance.symbol, instance.symbol.filters, filterCamera);
				instance.symbol._renderDirty = false;

				filterCamera.put();
				ColorTransform.__pool.release(colTr);
			}

			if (instance.symbol._filterFrame != null)
			{
				if (instance.symbol.colorEffect != null)
					colorEffect.concat(instance.symbol.colorEffect.getColor());

				matrix.copyFrom(instance.symbol._filterMatrix);
				matrix.translate(instance.x, instance.y);
				matrix.concat(m);

				drawLimb(instance.symbol._filterFrame, matrix, colorEffect, filterin, blendMode, cameras);
			}
		}
		else
		{
			if (instance.symbol.colorEffect != null && filterInstance != instance)
				colorEffect.concat(instance.symbol.colorEffect.getColor());

			var layers = symbol.timeline.getList();

			var mat_temp = FlxPooledMatrix.get();
			var colorEffect_temp = ColorTransform.__pool.get();
			var layer:FlxLayer;
			var frame:FlxKeyFrame;
			var maskCamera:FlxPooledCamera = null;
			for (i in 0...layers.length)
			{
				layer = layers[layers.length - 1 - i];

				if (!layer.visible && (!filterin && mainSymbol || !showHiddenLayers) || layer.type == Clipper && layer._correctClip) continue;

				/*
				if (layer._clipper != null)
				{
					var layer = layer._clipper;
					layer._setCurFrame(curIndexFrame);
					frame = layer._currFrame;
					if (frame != null && frame._renderDirty)
					{
						maskCamera = FlxPooledCamera.get();
						mat_temp.identity();
						colorEffect_temp.__identity();
						renderLayer(frame, mat_temp, colorEffect_temp, instance, null, [maskCamera]);

						frame._renderDirty = false;
					}
				}
				*/

				layer._setCurFrame(curIndexFrame);

				frame = layer._currFrame;

				if (frame == null) continue;

				colorEffect_temp.__copyFrom(colorEffect);
				if (frame.colorEffect != null)
					colorEffect_temp.concat(frame.colorEffect.getColor());

				if (!skipFilters && (frame.filters != null || layer.type.match(Clipped(_))))
				{
					if (frame._renderDirty || layer._filterFrame == null)
					{
						// render layer to _filterFrame
						var filterCamera = FlxPooledCamera.get();
						var colTr = ColorTransform.__pool.get();
						mat_temp.identity();
						layer._filterMatrix.identity();
						// layer._filterMatrix.concat(instance.matrix);
						renderLayer(frame, mat_temp, colTr, instance, null, [filterCamera]);
						renderFilter(layer, frame.filters, filterCamera, maskCamera);

						filterCamera.put();
						// maskCamera = FlxDestroyUtil.put();
						ColorTransform.__pool.release(colTr);

						frame._renderDirty = false;
					}

					mat_temp.copyFrom(layer._filterMatrix);
					mat_temp.translate(instance.x, instance.y);
					mat_temp.concat(m);

					drawLimb(layer._filterFrame, mat_temp, colorEffect_temp, filterin, blendMode, cameras);
				}
				else
				{
					renderLayer(frame, matrix, colorEffect_temp, filterInstance, blendMode, cameras);
				}
			}
			mat_temp.put();
			ColorTransform.__pool.release(colorEffect_temp);
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
	function renderFilter(filterInstance:IFilterable, filters:Array<BitmapFilter>, filterCamera:FlxCamera, ?mask:FlxCamera)
	{
		var masking = mask != null;
		filterCamera.render();

		var graphicSize = filterCamera.canvas.getBounds(null);

		if (filters != null && filters.length > 0)
		{
			var extension = Rectangle.__pool.get();

			for (filter in filters)
			{
				extension.__expand(-filter.__leftExtension, -filter.__topExtension,
					filter.__leftExtension + filter.__rightExtension,
					filter.__topExtension + filter.__bottomExtension);
			}
			graphicSize.width += extension.width * 1.5;
			graphicSize.height += extension.height * 1.5;
			graphicSize.x = extension.x * 1.5;
			graphicSize.y = extension.y * 1.5;

			Rectangle.__pool.release(extension);
		}
		else
		{
			graphicSize.x = graphicSize.y = 0;
		}

		filterInstance.updateBitmaps(graphicSize);

		var gfx = FlxAnimate.renderer.graphicstoBitmapData(filterCamera.canvas.graphics, filterInstance._bmp1);

		if (gfx == null) return;

		var gfxMask = null;
		if (masking)
		{
			mask.render();
			gfxMask = FlxAnimate.renderer.graphicstoBitmapData(mask.canvas.graphics);
		}

		var bounds = Rectangle.__pool.get();

		static var staticLocalMatrixLol = new Matrix();
		filterCamera.canvas.__getBounds(bounds, staticLocalMatrixLol);

		var point:FlxPoint = null;

		if (masking && gfxMask != null)
		{
			var maskBounds = Rectangle.__pool.get();

			mask.canvas.__getBounds(maskBounds, staticLocalMatrixLol);

			point = FlxPoint.get(maskBounds.x / bounds.width, maskBounds.y / bounds.height);

			Rectangle.__pool.release(maskBounds);
		}

		FlxAnimate.renderer.applyFilter(gfx, filterInstance._filterFrame.parent.bitmap, filterInstance._bmp1, filterInstance._bmp2, filters, graphicSize, gfxMask, point);
		point = FlxDestroyUtil.put(point);

		// filterInstance._filterMatrix.identity();
		filterInstance._filterMatrix.translate(bounds.x + graphicSize.x, bounds.y + graphicSize.y);

		Rectangle.__pool.release(bounds);
	}

	static var _mousePoint:FlxPoint = new FlxPoint();
	var pressed:Bool = false;
	function setButtonFrames(instance:FlxElement, matrix:FlxMatrix) // TODO
	{
		var frame:Int = 0;
		#if (FLX_MOUSE && !mobile)
		var limb = frames.getByName(instance.bitmap);
		if (limb == null)
		{
			// trace("no boobs " + Std.string(instance));
			return 0;
		}
		var badPress:Bool = false;
		var goodPress:Bool = false;
		var isOverlaped:Bool = false;
		for (i in cameras)
		{
			FlxG.mouse.getScreenPosition(camera, _mousePoint);

			limb.frame.copyToFlash(rect);
			rect.setTo(0, 0, rect.width, rect.width);
			rect.__transform(rect, matrix);

			if (isOverlaped = FlxMath.pointInCoordinates(_mousePoint.x, _mousePoint.y, rect.x, rect.y, rect.width, rect.height))
				break;
		}
		final isPressed = FlxG.mouse.pressed;
		if (isPressed && isOverlaped)
		{
			goodPress = true;
		}
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
			frame = (isPressed) ? 2 : 1;

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
	function drawPivotLimb(limb:FlxFrame, _matrix:FlxMatrix, cameras:Array<FlxCamera> = null)
	{
		if (limb == null || limb.type == EMPTY)
			return;

		if (cameras == null)
			cameras = this.cameras;

		for (camera in cameras)
		{
			if (camera == null || !camera.visible || !camera.exists)
				return;

			_mat.copyFrom(_matrix);

			getScreenPosition(_point, camera);

			_mat.translate(_point.x, _point.y);

			if (isPixelPerfectRender(camera))
			{
				_mat.tx = Math.floor(_mat.tx);
				_mat.ty = Math.floor(_mat.ty);
			}

			if (limbOnScreen(limb, _mat, camera))
			{
				camera.drawPixels(limb, null, _mat, null, null, antialiasing, this.shader);
				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}
		}
	}

	function drawLimb(limb:FlxFrame, _matrix:FlxMatrix, ?colorTransform:ColorTransform = null, filterin:Bool = false, ?blendMode:BlendMode, cameras:Array<FlxCamera> = null)
	{
		if (/*colorTransform != null && (colorTransform.alphaMultiplier == 0 || colorTransform.alphaOffset == -255) ||*/ limb == null || limb.type == EMPTY)
			return;

		if (cameras == null)
			cameras = this.cameras;

		for (i => camera in cameras)
		{
			if (camera == null || !camera.visible || !camera.exists)
				return;

			limb.prepareMatrix(_mat);
			_mat.concat(_matrix);

			if (!filterin)
			{
				_mat.translate(-origin.x, -origin.y);

				_mat.scale(scale.x, scale.y);

				if (bakedRotationAngle <= 0)
				{
					if (angle != 0)
						_mat.rotateWithTrig(_cosAngle, _sinAngle);
				}

				_mat.concat(matrixExposed ? transformMatrix : _skewMatrix);

				_mat.translate(_camerasCashePoints[i].x, _camerasCashePoints[i].y);

				if (isPixelPerfectRender(camera))
				{
					_mat.tx = Math.floor(_mat.tx);
					_mat.ty = Math.floor(_mat.ty);
				}

				if (!limbOnScreen(limb, _mat, camera))
					continue;
				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}
			camera.drawPixels(limb, null, _mat, colorTransform, blendMode, filterin || antialiasing, filterin ? null : this.shader);
		}

		#if FLX_DEBUG
		if (!filterin && FlxG.debugger.drawDebug)
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

	function limbOnScreen(limb:FlxFrame, m:FlxMatrix, ?Camera:FlxCamera)
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
		_camerasCashePoints = FlxDestroyUtil.putArray(_camerasCashePoints);
		super.destroy();
	}

	var _lastElapsed:Float;
	public override function updateAnimation(elapsed:Float)
	{
		_lastElapsed = elapsed;
		if (useAtlas && atlasIsValid)
		{
			anim.update(elapsed);
		}
		else
		{
			animation.update(elapsed);
		}
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

	#if FLX_ANIMATE_PSYCH_SUPPOST
	public function loadAtlasEx(img:FlxGraphicAsset, pathOrStr:String, myJson:Dynamic)
	{
		var animJson:AnimAtlas = null;
		var trimmed:String = StringTools.trim(pathOrStr);
		trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

		if(myJson is String)
		{
			if(trimmed == '.json') myJson = Utils.getText(myJson); //is a path
			animJson = cast haxe.Json.parse(_removeBOM(myJson));
		}
		else animJson = cast myJson;

		var isXml:Null<Bool> = null;
		var myData:Dynamic = pathOrStr;

		if(trimmed == '.json') //Path is json
		{
			myData = _removeBOM(Utils.getText(pathOrStr));
			isXml = false;
		}
		else if (trimmed.substr(1) == '.xml') //Path is xml
		{
			myData = _removeBOM(Utils.getText(pathOrStr));
			isXml = true;
		}

		// Automatic if everything else fails
		switch(isXml)
		{
			case true:
				myData = Xml.parse(myData);
			case false:
				myData = haxe.Json.parse(myData);
			case null:
				try
				{
					myData = haxe.Json.parse(myData);
					isXml = false;
					//trace('JSON parsed successfully!');
				}
				catch(e)
				{
					myData = Xml.parse(myData);
					isXml = true;
					//trace('XML parsed successfully!');
				}
		}

		anim._loadAtlas(animJson);
		frames = isXml ? FlxAnimateFrames.fromSparrow(cast myData, img) : FlxAnimateFrames.fromAnimateAtlas(cast myData, img);
		origin = anim.curInstance.symbol.transformationPoint;
	}

	static function _removeBOM(str:String) //Removes BOM byte order indicator
	{
		if (str.charCodeAt(0) == 0xFEFF) str = str.substr(1); //myData = myData.substr(2);
		return str;
	}
	#end

	@:noCompletion
	function set_useAtlas(i:Bool)
	{
		if (useAtlas != i)
		{
			useAtlas = i;
			if (!useAtlas)
			{
				resetHelpers();
			}
		}
		return useAtlas;
	}
}
