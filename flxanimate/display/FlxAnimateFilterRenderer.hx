package flxanimate.display;

import flxanimate.filters.MaskShader;

import flixel.math.FlxPoint;
import flixel.FlxG;

import openfl.display._internal.Context3DGraphics;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.DisplayObjectRenderer;
import openfl.display.Graphics;
import openfl.display.OpenGLRenderer;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DClearMask;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;

import lime.graphics.cairo.Cairo;

#if (js && html5)
import openfl.display.CanvasRenderer;
import openfl.display._internal.CanvasGraphics as GfxRenderer;
import lime._internal.graphics.ImageCanvasUtil;
#else
import openfl.display.CairoRenderer;
import openfl.display._internal.CairoGraphics as GfxRenderer;
#end


@:access(openfl.display.OpenGLRenderer)
@:access(openfl.filters.BitmapFilter)
@:access(openfl.geom.Rectangle)
@:access(openfl.display.Stage)
@:access(openfl.display.Graphics)
@:access(openfl.display.Shader)
@:access(openfl.display.BitmapData)
@:access(openfl.geom.ColorTransform)
@:access(openfl.display.DisplayObject)
@:access(openfl.display3D.Context3D)
@:access(openfl.display.CanvasRenderer)
@:access(openfl.display.CairoRenderer)
@:access(openfl.display3D.Context3D)
class FlxAnimateFilterRenderer
{
	var renderer:OpenGLRenderer;
	var context:Context3D;

	static var maskShader:MaskShader = new MaskShader();
	static var maskFilter:ShaderFilter = new ShaderFilter(maskShader);

	public function new()
	{
		// context = new openfl.display3D.Context3D(null);
		renderer = new OpenGLRenderer(FlxG.game.stage.context3D);
		renderer.__worldTransform = new Matrix();
		renderer.__worldColorTransform = new ColorTransform();
	}

	@:noCompletion function setRenderer(renderer:DisplayObjectRenderer, rect:Rectangle)
	{
		@:privateAccess
		if (true)
		{
			var displayObject = FlxG.game;
			var pixelRatio = FlxG.game.stage.__renderer.__pixelRatio;

			var offsetX = rect.x > 0 ? Math.ceil(rect.x) : Math.floor(rect.x);
			var offsetY = rect.y > 0 ? Math.ceil(rect.y) : Math.floor(rect.y);
			if (renderer.__worldTransform == null)
			{
				renderer.__worldTransform = new Matrix();
				renderer.__worldColorTransform = new ColorTransform();
			}
			if (displayObject.__cacheBitmapColorTransform == null) displayObject.__cacheBitmapColorTransform = new ColorTransform();

			renderer.__stage = displayObject.stage;

			renderer.__allowSmoothing = true;
			renderer.__setBlendMode(NORMAL);
			renderer.__worldAlpha = 1 / displayObject.__worldAlpha;

			renderer.__worldTransform.identity();
			renderer.__worldTransform.invert();
			//renderer.__worldTransform.concat(new Matrix());
			renderer.__worldTransform.tx -= offsetX;
			renderer.__worldTransform.ty -= offsetY;

			renderer.__pixelRatio = pixelRatio;

		}
	}

	public function applyFilter(startBmp:BitmapData, outBmp:BitmapData, casheBmp:BitmapData, casheBmp2:BitmapData, filters:Array<BitmapFilter>, ?rect:Rectangle, ?mask:BitmapData, ?maskPos:FlxPoint)
	{
		if (mask != null)
		{
			if (maskPos == null)
			{
				maskShader.relativePos.value[0] = maskShader.relativePos.value[1] = 0;
			}
			else
			{
				maskShader.relativePos.value[0] = maskPos.x;
				maskShader.relativePos.value[1] = maskPos.y;
			}
			maskShader.mainPalette.input = mask;
			maskFilter.invalidate();
			if (filters == null)
				filters = [maskFilter];
			else
				filters.push(maskFilter);
		}
		renderer.__setBlendMode(NORMAL);
		renderer.__worldAlpha = 1;

		renderer.__worldTransform.identity();
		renderer.__worldColorTransform.__identity();

		var bitmap:BitmapData = outBmp;
		var bitmap2:BitmapData = casheBmp;
		var bitmap3:BitmapData = casheBmp2;

		if (rect == null)
		{
			renderer.__setRenderTarget(outBmp);
			if (startBmp != bitmap)
				renderer.__renderFilterPass(startBmp, renderer.__defaultDisplayShader, true);
		}
		else
		{
			startBmp.__renderTransform.translate(-rect.x, -rect.y);
			renderer.__setRenderTarget(outBmp);
			if (startBmp != bitmap)
				renderer.__renderFilterPass(startBmp, renderer.__defaultDisplayShader, true);
			startBmp.__renderTransform.translate(rect.x, rect.y);
		}
		// startBmp.__renderTransform.identity();

		if (filters != null)
		{
			for (filter in filters)
			{
				if (filter.__preserveObject)
				{
					renderer.__setRenderTarget(bitmap3);
					renderer.__renderFilterPass(bitmap, renderer.__defaultDisplayShader, filter.__smooth);
				}

				for (i in 0...filter.__numShaderPasses)
				{
					renderer.__setBlendMode(filter.__shaderBlendMode);
					renderer.__setRenderTarget(bitmap2);
					renderer.__renderFilterPass(bitmap, filter.__initShader(renderer, i, (filter.__preserveObject) ? bitmap3 : null), filter.__smooth);

					renderer.__setRenderTarget(bitmap);
					renderer.__renderFilterPass(bitmap2, renderer.__defaultDisplayShader, filter.__smooth);
				}

				filter.__renderDirty = false;
			}

			if (mask != null)
				filters.pop();

			var gl = renderer.__gl;

			var renderBuffer = bitmap.getTexture(renderer.__context3D);
			@:privateAccess
			gl.readPixels(0, 0, bitmap.width, bitmap.height, renderBuffer.__format, gl.UNSIGNED_BYTE, bitmap.image.data);
			bitmap.image.version = 0;
			@:privateAccess
			bitmap.__textureVersion = -1;
		}
	}

	public function applyBlend(blend:BlendMode, bitmap:BitmapData)
	{
		bitmap.__update(false, true);
		var bmp = new BitmapData(bitmap.width, bitmap.height, 0);

		#if (js && html5)
		ImageCanvasUtil.convertToCanvas(bmp.image);
		@:privateAccess
		var renderer = new CanvasRenderer(bmp.image.buffer.__srcContext);
		#else
		var renderer = new CairoRenderer(new Cairo(bmp.getSurface()));
		#end

		// setRenderer(renderer, bmp.rect);

		var m = new Matrix();
		var c = new ColorTransform();
		renderer.__allowSmoothing = true;
		renderer.__overrideBlendMode = blend;
		renderer.__worldTransform = m;
		renderer.__worldAlpha = 1;
		renderer.__worldColorTransform = c;

		renderer.__setBlendMode(blend);
		#if (js && html5)
		bmp.__drawCanvas(bitmap, renderer);
		#else
		bmp.__drawCairo(bitmap, renderer);
		#end

		return bitmap;
	}

	public function graphicstoBitmapData(gfx:Graphics, ?target:BitmapData, ?point:FlxPoint) // TODO!: Support for CPU based games (Cairo/Canvas only renderers)
	{
		if (gfx.__bounds == null) return null;

		var cacheRTT = renderer.__context3D.__state.renderToTexture;
		var cacheRTTDepthStencil = renderer.__context3D.__state.renderToTextureDepthStencil;
		var cacheRTTAntiAlias = renderer.__context3D.__state.renderToTextureAntiAlias;
		var cacheRTTSurfaceSelector = renderer.__context3D.__state.renderToTextureSurfaceSelector;

		var bounds = gfx.__owner.getBounds(null);

		var bmp = (target == null) ? new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0) : target;

		renderer.__worldTransform.translate(-bounds.x, -bounds.y);
		if (point != null)
		{
			renderer.__worldTransform.translate(point.x, point.y);
		}

		// GfxRenderer.render(gfx, cast renderer.__softwareRenderer);
		// var bmp = gfx.__bitmap;

		var context = renderer.__context3D;

		renderer.__setRenderTarget(bmp);
		var renderBuffer = bmp.getTexture(context);
		context.setRenderToTexture(renderBuffer);

		Context3DGraphics.render(gfx, renderer);

		renderer.__worldTransform.identity();


		var gl = renderer.__gl;

		@:privateAccess
		gl.readPixels(0, 0, bmp.width, bmp.height, renderBuffer.__format, gl.UNSIGNED_BYTE, bmp.image.data);


		if (cacheRTT != null)
		{
			renderer.__context3D.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		}
		else
		{
			renderer.__context3D.setRenderToBackBuffer();
		}

		return bmp;
	}
}