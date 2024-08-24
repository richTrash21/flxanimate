package flxanimate.data;

import flxanimate.effects.*;
import flxanimate.motion.AdjustColor;
import flixel.util.FlxDirection;
import flixel.util.FlxColor;
import openfl.geom.ColorTransform;
import openfl.filters.*;

@:noCompletion
class AnimationData
{

	// public static var internalParam:EReg = ~/_FA{/;

	// public static var bracketReg:EReg = ~/(\{([^{}]|(?R))*\})/s;.

	//TODO: The comment below this comment.
	// GeoKureli told me that Reflect is shit, but I have literally no option but to use this.
	// If I have another thing to use that works the same, should replace this lol
	/**
	 * Checks a value, using `Reflection`.
	 * @param abstracto The abstract in specific.
	 * @param things The fields you want to use.
	 * @param set What value you want to set.
	 * @return The value in specific casted as `Dynamic`.
	 */
	public static function getFieldBool(abstracto:Dynamic, things:Array<String>):Dynamic
	{
		if (abstracto == null)
			return null;
		for (thing in things)
		{
			if (Reflect.hasField(abstracto, thing))
			{
				return Reflect.field(abstracto, thing);
			}
		}
		return null;
	}
	/**
	 * Set a value, using `Reflection`.
	 * @param abstracto The abstract in specific.
	 * @param things The fields you want to use.
	 * @param set What value you want to set.
	 * @return The value in specific casted as `Dynamic`.
	 */
	public static function setFieldBool(abstracto:Dynamic, things:Array<String>, set:Dynamic):Dynamic
	{
		if (abstracto == null)
			return null;
		for (thing in things)
		{
			if (Reflect.hasField(abstracto, thing))
			{
				Reflect.setField(abstracto, thing, set);
				return set;
			}
		}
		return null;
	}
	/**
	 * Parses a Color Effect from a JSON file into a enumeration of `ColorEffect`.
	 * @param effect The json field.
	 */
	public static function fromColorJson(effect:ColorEffects = null):ColorEffect
	{
		// var colorEffect:ColorEffect = None;
		var colorEffect:ColorEffect = null;

		if (effect == null) return colorEffect;

		switch (effect.M)
		{
			case Tint, "Tint":
				colorEffect = Tint(colorFromString(effect.TC), effect.TM);
			case Alpha, "Alpha":
				colorEffect = Alpha(effect.AM);
			case Brightness, "Brightness":
				colorEffect = Brightness(effect.BRT);
			case Advanced, "Advanced":
				colorEffect = Advanced(new ColorTransform(
					effect.RM, effect.GM, effect.BM, effect.AM, 
					effect.RO, effect.GO, effect.BO, effect.AO
				));
			default:
				final message = 'Color Effect mode "${effect.M}" is invalid or not supported!';
				trace(message);
				flixel.FlxG.log.error(message);
		}
		return colorEffect;
	}
	static function colorFromString(color:String)
	{
		return Std.parseInt( "0x" + color.substring(1));
	}

	/**
	 * Parses a filter from a JSON file into a `BitmapFilter`
	 * @param filters The JSON field.
	 */
	public static function fromFilterJson(filters:Filters = null)
	{
		if (filters == null) return null;

		var bitmapFilter:Array<BitmapFilter> = [];

		for (filter in Reflect.fields(filters))
		{
			switch (filter.split("_")[0])
			{
				case "DSF", "DropShadowFilter":
					var drop:DropShadowFilter = Reflect.field(filters, filter);
					bitmapFilter.unshift(new openfl.filters.DropShadowFilter(drop.DST, drop.AL, colorFromString(drop.C), drop.A, drop.BLX, drop.BLY, drop.STR, drop.Q, drop.IN, drop.KK));
				
				case "GF", "GlowFilter": // Friday Night Funkin reference ?!??!?!''1'!'?1'1''?1''
					var glow:GlowFilter = Reflect.field(filters, filter);
					bitmapFilter.unshift(new openfl.filters.GlowFilter(colorFromString(glow.C), glow.A, glow.BLX, glow.BLY, glow.STR, glow.Q, glow.IN, glow.KK));

				case "BF", "BevelFilter": // Friday Night Funkin reference ?!??!?!''1'!'?1'1''?1''
					var bevel:BevelFilter = Reflect.field(filters, filter);
					bitmapFilter.unshift(new flxanimate.filters.BevelFilter(bevel.DST, bevel.AL, colorFromString(bevel.HC), bevel.HA, colorFromString(bevel.SC), bevel.SA, bevel.BLX, bevel.BLY, bevel.STR, bevel.Q, bevel.TP, bevel.KK));

				case "BLF", "BlurFilter":
					var blur:BlurFilter = Reflect.field(filters, filter);
					bitmapFilter.unshift(new openfl.filters.BlurFilter(blur.BLX, blur.BLY, blur.Q));

				case "ACF", "AdjustColorFilter":
					var adjustColor:AdjustColorFilter = Reflect.field(filters, filter);

					var colorAdjust = new AdjustColor();

					colorAdjust.hue = adjustColor.H;
					colorAdjust.brightness = adjustColor.BRT;
					colorAdjust.contrast = adjustColor.CT;
					colorAdjust.saturation = adjustColor.SAT;

					bitmapFilter.unshift(new openfl.filters.ColorMatrixFilter(colorAdjust.calculateFinalFlatArray()));

				case "GGF", "GradientGlowFilter":
					var gradient:GradientFilter = Reflect.field(filters, filter);
					var colors:Array<Int> = [];
					var alphas:Array<Float> = [];
					var ratios:Array<Int> = [];

					for (entry in gradient.GE)
					{
						colors.push(colorFromString(entry.C));
						alphas.push(entry.A);
						ratios.push(Std.int(entry.R * 255));
					}


					bitmapFilter.unshift(new flxanimate.filters.GradientGlowFilter(gradient.DST, gradient.AL, colors, alphas, ratios, gradient.BLX, gradient.BLY, gradient.STR, gradient.Q, gradient.TP, gradient.KK));

				case "GBF", "GradientBevelFilter":
					var gradient:GradientFilter = Reflect.field(filters, filter);
					var colors:Array<Int> = [];
					var alphas:Array<Float> = [];
					var ratios:Array<Int> = [];

					for (entry in gradient.GE)
					{
						colors.push(colorFromString(entry.C));
						alphas.push(entry.A);
						ratios.push(Math.round(entry.R * 255));
					}


					bitmapFilter.unshift(new flxanimate.filters.GradientBevelFilter(gradient.DST, gradient.AL, colors, alphas, ratios, gradient.BLX, gradient.BLY, gradient.STR, gradient.Q, gradient.TP, gradient.KK));
			}
		}

		return bitmapFilter;
	}
	/**
	 * Transforms a `ColorEffect` into a `ColorTransform`.
	 * @param colorEffect The `ColorEffect`.
	 */
	public static function parseColorEffect(colorEffect:ColorEffect = None)
	{
		var CT = null;

		if(colorEffect != None && colorEffect != null)
		{
			CT = switch (colorEffect)
			{
				case Tint(color, opacity): new FlxTint(color, opacity);
				case Alpha(stillAlpha): new FlxAlpha(stillAlpha);
				case Brightness(bright): new FlxBrightness(bright);
				case Advanced(transform): new FlxAdvanced(transform);
				default: new FlxColorEffect();
			}
		}


		return CT;
	}
}
/**
 * The types of Color Effects the symbol can have.
 */
enum ColorEffect
{
	None;
	Brightness(Bright:Float);
	Tint(Color:flixel.util.FlxColor, Opacity:Float);
	Alpha(Alpha:Float);
	Advanced(transform:ColorTransform);
}
/**
 * The looping method for the current symbol.
 */
enum Loop
{
	Loop;
	PlayOnce;
	SingleFrame;
}
/**
 * The type the symbol can be.
 */
enum SymbolT
{
	Graphic;
	MovieClip;
	Button;
}
/**
 * The type of behaviour `FlxLayer` can become.
 */
enum LayerType
{
	Normal;
	Clipper;
	Clipped(layer:String);
	Folder;
}

/**
 * The main structure of a basic Animation file in the texture atlas.
 */
abstract AnimAtlas({}) from {}
{
	/**
	 * The main thing, the animation that makes the different drawings animate together and shit
	 */
	public var AN(get, never):Animation;
	/**
	 * This is where all the symbols that the main animation uses are stored. Can be `null`!
	 */
	public var SD(get, never):SymbolDictionary;
	/**
	 * A metadata, consisting of the framerate the document had been exported.
	 */
	public var MD(get, never):MetaData;

	inline function get_AN():Animation
	{
		return AnimationData.getFieldBool(this, ["AN", "ANIMATION"]);
	}

	inline function get_MD():MetaData
	{
		return AnimationData.getFieldBool(this, ["MD", "metadata"]);
	}
	inline function get_SD()
	{
		return AnimationData.getFieldBool(this, ["SD", "SYMBOL_DICTIONARY"]);
	}
}
/**
 * An `Array` of multiple symbols. All symbols in the Dictionary are supposedly used in the main Animation or in other symbols.
 */
abstract SymbolDictionary({}) from {}
{
	/**
	 * The list of symbols.
	 */
	public var S(get, never):Array<SymbolData>;

	inline function get_S():Array<SymbolData>
	{
		return AnimationData.getFieldBool(this, ["S", "Symbols"]);
	}
}
@:forward
/**
 *
 */
abstract Animation(SymbolData) from {}
{
	/**
	 * The name of the Flash document the texture atlas was exported with.
	 */
	public var N(get, never):String;
	/**
	 * The Stage Instance. This represents the element settings the texture atlas was exported when clicking on-stage
	 * **WARNING:** if you export the texture atlas inside the symbol dictionary, this field won't appear, meaning it can be `null`.
	 */
	public var STI(get, never):StageInstance;

	inline function get_N():String
	{
		return AnimationData.getFieldBool(this, ["N", "name"]);
	}
	inline function get_STI()
	{
		return AnimationData.getFieldBool(this, ["STI", "StageInstance"]);
	}
}
/**
 * The main position how the symbol you exported was set, Acting almost identically as an `Element`, with the exception of not having an Atlas Sprite to call (not that I'm aware of).
 * **WARNING:** This may depend on how you exported your texture atlas, Meaning that this can be `null`
 */
abstract StageInstance({})
{
	/**
	 * The instance of the Element flagged as a `Symbol`.
	 * **WARNING:** This can be `null`!
	 */
	public var SI(get, never):SymbolInstance;

	inline function get_SI():SymbolInstance
	{
		return AnimationData.getFieldBool(this, ["SI", "SYMBOL_Instance"]);
	}
}
/**
 * A small Symbol specifier, consisting of the name of the Symbol and its timeline.
 */
abstract SymbolData({}) from {}
{
	/**
	 * The name of the symbol.
	 */
	public var SN(get, never):String;
	/**
	 * The timeline of the Symbol.
	 */
	public var TL(get, never):Timeline;

	inline function get_SN():String
	{
		return AnimationData.getFieldBool(this, ["SN", "SYMBOL_name"]);
	}
	inline function get_TL():Timeline
	{
		return AnimationData.getFieldBool(this, ["TL", "TIMELINE"]);
	}
}
/**
 * The main timeline of the symbol.
 */
abstract Timeline({}) from {}
{
	/**
	 * An `Array` that goes in a inverted order, from the bottom to the top.
	 */
	public var L(get, set):Array<Layers>;

	inline function get_L():Array<Layers>
	{
		return AnimationData.getFieldBool(this, ["L", "LAYERS"]);
	}
	inline function set_L(value:Array<Layers>)
	{
		return AnimationData.setFieldBool(this, ["L", "LAYERS"], value);
	}
}
/**
 * A layer instance inside the `Timeline`.
 */
abstract Layers({}) from {}
{
	/**
	 * The name of the layer.
	 */
	public var LN(get, never):String;
	/**
	 * Type of layer, It's usually to indicate that the Layer is a mask or is masked.
	 */
	public var LT(get, never):String;
	/**
	 * if the layer is masked, this field will appear to explain which layer is being clipped to, usually the next one.
	 */
	public var Clpb(get, never):String;
	/**
	 * An `Array` of KeyFrames inside the layer.
	 */
	public var FR(get, set):Array<Frame>;

	inline function get_LN():String
	{
		return AnimationData.getFieldBool(this, ["LN", "Layer_name"]);
	}
	inline function get_LT():String
	{
		return AnimationData.getFieldBool(this, ["LT", "Layer_type"]);
	}
	inline function get_Clpb():String
	{
		return AnimationData.getFieldBool(this, ["Clpb", "Clipped_by"]);
	}
	inline function get_FR():Array<Frame>
	{
		return AnimationData.getFieldBool(this, ["FR", "Frames"]);
	}
	inline function set_FR(value:Array<Frame>):Array<Frame>
	{
		return AnimationData.setFieldBool(this, ["FR", "Frames"], value);
	}
}
/**
 * The metadata, consisting of a single variable to indicate the framerate the texture atlas was exported with.
 */
abstract MetaData({}) from {}
{

	/**
	 * The framerate.
	 */
	public var FRT(get, never):Float;

	inline function get_FRT()
	{
		return AnimationData.getFieldBool(this, ["FRT", "framerate"]);
	}
}
/**
 * A KeyFrame with everything essential + labels and ColorEffects/Filters.
 */
abstract Frame({}) from {}
{
	/**
	 * The "name of the frame", basically labels that you can use as thingies for more cool stuff to program lol
	 */
	public var N(get, never):String;
	/**
	 * The frame index, aka the current number frame.
	 */
	public var I(get, never):Int;
	/**
	 * The duration of the frame.
	 */
	public var DU(get, never):Int;
	/**
	 * The elements that the frame has. Drawings/symbols to be specific
	 */
	public var E(get, never):Array<Element>;

	/**
	 * The Color Effect of the symbol, it says color but it affects alpha too lol.
	 */
	public var C(get, set):ColorEffects;

	/**
	 * Filter stuff, this is the reason why you can't add custom shaders, srry
	 */
	public var F(get, never):Filters;

	inline function get_N():String
	{
		return AnimationData.getFieldBool(this, ["N", "name"]);
	}
	inline function get_I():Int
	{
		return AnimationData.getFieldBool(this, ["I", "index"]);
	}
	inline function get_DU():Int
	{
		return AnimationData.getFieldBool(this, ["DU", "duration"]);
	}
	inline function get_E():Array<Element>
	{
		return AnimationData.getFieldBool(this, ["E", "elements"]);
	}
	inline function get_C()
	{
		return AnimationData.getFieldBool(this, ["C", "color"]);
	}
	inline function set_C(value:ColorEffects)
	{
		return AnimationData.setFieldBool(this, ["C", "color"], value);
	}

	inline function get_F()
	{
		return AnimationData.getFieldBool(this, ["F", "filters"]);
	}
}
/**
 * The Element thing inside the frame
 */
@:forward
abstract Element(StageInstance)
{
	/*
	 * the Sprite of the animation, aka the non Symbol.
	 */
	public var ASI(get, never):AtlasSymbolInstance;

	inline function get_ASI():AtlasSymbolInstance
	{
		return AnimationData.getFieldBool(this, ["ASI", "ATLAS_SPRITE_instance"]);
	}
}
/**
 * The Symbol Abstract
 */
abstract SymbolInstance({}) from {}
{
	/**
	 * the name of the symbol.
	 */
	public var SN(get, never):String;

	/**
	 * the name instance of the Symbol.
	 */
	public var IN(get, never):String;
	/**
	 * the type of symbol,
	 * Which can be a:
	 * - Graphic
	 * - MovieClip
	 * - Button
	 */
	public var ST(get, never):SymbolType;

	/**
	 * bitmap Settings, Used in 2018 and 2019
	 */
	public var bitmap(get, never):Bitmap;

	/**
	 * this sets on which frame it's the symbol, Graphic only
	 */
	public var FF(get, never):Int;
	/**
	 * the Loop Type of the symbol, which can be:
	 * - Loop
	 * - Play Once
	 * - Single Frame
	 */
	public var LP(get, never):LoopType;
	/**
	 * the Transformation Point of the symbol, basically the pivot that determines how it scales or not in Flash
	 */
	public var TRP(get, never):TransformationPoint;
	/**
	 * The Matrix of the Symbol, Be aware from Neo! He can be anywhere!!! :fearful:
	 */
	public var M3D(get, never):OneOfTwo<Array<Float>, Matrix3D>;
	/**
	 * The Color Effect of the symbol, it says color but it affects alpha too lol.
	 */
	public var C(get, set):ColorEffects;

	/**
	 * Filter stuff, this is the reason why you can't add custom shaders, srry
	 */
	public var F(get, never):Filters;

	inline function get_SN()
	{
		return AnimationData.getFieldBool(this, ["SN", "SYMBOL_name"]);
	}

	inline function get_IN()
	{
		return AnimationData.getFieldBool(this, ["IN", "Instance_Name"]);
	}

	inline function get_ST()
	{
		return AnimationData.getFieldBool(this, ["ST", "symbolType"]);
	}

	inline function get_bitmap()
	{
		return AnimationData.getFieldBool(this, ["BM", "bitmap"]);
	}
	inline function get_FF()
	{
		return AnimationData.getFieldBool(this, ["FF", "firstFrame"]) ?? 0;
	}

	inline function get_LP()
	{
		return AnimationData.getFieldBool(this, ["LP", "loop"]);
	}

	inline function get_TRP()
	{
		return AnimationData.getFieldBool(this, ["TRP", "transformationPoint"]);
	}

	inline function get_M3D()
	{
		return AnimationData.getFieldBool(this, ["M3D", "Matrix3D"]);
	}

	inline function get_C()
	{
		return AnimationData.getFieldBool(this, ["C", "color"]);
	}
	inline function set_C(value:ColorEffects)
	{
		return AnimationData.setFieldBool(this, ["C", "color"], value);
	}

	inline function get_F()
	{
		return AnimationData.getFieldBool(this, ["F", "filters"]);
	}
}
abstract ColorEffects({}) from {}
{
	/**
	 * What type of Effect is it.
	 */
	public var M(get, never):ColorMode;
	/**
	 * tint Color, basically, How's the color gonna be lol.
	 */
	public var TC(get, never):String;
	/**
	 * tint multiplier, or the alpha of **THE COLOR!** Don't forget that.
	 */
	public var TM(get, never):Float;

	public var AM(get, never):Float;
	public var AO(get, never):Int;

	// Red Multiplier and Offset
	public var RM(get, never):Float;
	public var RO(get, never):Int;
	// Green Multiplier and Offset
	public var GM(get, never):Float;
	public var GO(get, never):Int;
	// Blue Multiplier and Offset
	public var BM(get, never):Float;
	public var BO(get, never):Int;

	public var BRT(get, never):Float;

	inline function get_M()
	{
		return AnimationData.getFieldBool(this, ["M", "mode"]);
	}
	inline function get_TC()
	{
		return AnimationData.getFieldBool(this, ["TC", "tintColor"]);
	}
	inline function get_TM()
	{
		return AnimationData.getFieldBool(this, ["TM", "tintMultiplier"]);
	}
	inline function get_AM()
	{
		return AnimationData.getFieldBool(this, ["AM", "alphaMultiplier"]);
	}
	inline function get_AO()
	{
		return AnimationData.getFieldBool(this, ["AO", "AlphaOffset"]);
	}
	inline function get_RM()
	{
		return AnimationData.getFieldBool(this, ["RM", "RedMultiplier"]);
	}
	inline function get_RO()
	{
		return AnimationData.getFieldBool(this, ["RO", "redOffset"]);
	}
	inline function get_GM()
	{
		return AnimationData.getFieldBool(this, ["GM", "greenMultiplier"]);
	}
	inline function get_GO()
	{
		return AnimationData.getFieldBool(this, ["GO", "greenOffset"]);
	}
	inline function get_BM()
	{
		return AnimationData.getFieldBool(this, ["BM", "blueMultiplier"]);
	}
	inline function get_BO()
	{
		return AnimationData.getFieldBool(this, ["BO", "blueOffset"]);
	}
	inline function get_BRT()
	{
		return AnimationData.getFieldBool(this, ["BRT", "Brightness"]);
	}
}
abstract Filters({})
{
	/**
	 * Adjust Color filter is a workaround to give some color adjustment, including hue-rotation, saturation, brightness and contrast.
	 * After calculating every required adjustment, it gets the matrix and then the filter is applied as a `ColorMatrixFilter`.
	 * @see flxanimate.motion.AdjustColor
	 * @see flxanimate.motion.ColorMatrix
	 * @see flxanimate.motion.DynamicMatrix
	 * @see openfl.filters.ColorMatrixFilter
	 */
	public var ACF(get, never):AdjustColorFilter;

	public var GF(get, never):GlowFilter;

	inline function get_ACF()
	{
		return AnimationData.getFieldBool(this, ["ACF", "AdjustColorFilter"]);
	}
	inline function get_GF()
	{
		return AnimationData.getFieldBool(this, ["GF"]);
	}
}
/**
 * A full matrix calculation thing that seems to behave like a special HSV adjust.
 */
abstract AdjustColorFilter({})
{
	/**
	 * The brightness value. Can be from -100 to 100
	 */
	public var BRT(get, never):Float;
	/**
	 * The value of contrast. Can be from -100 to 100
	 */
	public var CT(get, never):Float;
	/**
	 * The value of saturation. Can be from -100 to 100
	 */
	public var SAT(get, never):Float;
	/**
	 * The hue value. Can be from -180 to 180
	 */
	public var H(get, never):Float;

	inline function get_BRT()
	{
		return AnimationData.getFieldBool(this, ["BRT", "brightness"]);
	}
	inline function get_CT()
	{
		return AnimationData.getFieldBool(this, ["CT", "contrast"]);
	}
	inline function get_SAT()
	{
		return AnimationData.getFieldBool(this, ["SAT", "saturation"]);
	}
	inline function get_H()
	{
		return AnimationData.getFieldBool(this, ["H", "hue"]);
	}
}
/**
 * This blur filter gives instructions of how the blur should be applied onto the symbol/frame.
 */
abstract BlurFilter({})
{
	/**
	 * The amount of blur horizontally.
	 */
	public var BLX(get, never):Float;
	/**
	 * The amount of blur vertically.
	 */
	public var BLY(get, never):Float;
	/**
	 * The number of passes the filter has.
	 * When the quality is set to three, it should approximate to a Gaussian Blur.
	 * Obviously you can go beyond three, but it'll take more time to render.
	 */
	public var Q(get, never):Int;

	inline function get_BLX()
	{
		return AnimationData.getFieldBool(this, ["BLX", "blurX"]);
	}
	inline function get_BLY()
	{
		return AnimationData.getFieldBool(this, ["BLY", "blurY"]);
	}
	inline function get_Q()
	{
		return AnimationData.getFieldBool(this, ["Q", "quality"]);
	}
}

@:forward
abstract GlowFilter(BlurFilter)
{
	public var C(get, never):String;
	public var A(get, never):Float;
	public var STR(get, never):Float;
	public var KK(get, never):Bool;
	public var IN(get, never):Bool;

	inline function get_C()
	{
		return AnimationData.getFieldBool(this, ["C", "color"]);
	}
	inline function get_A()
	{
		return AnimationData.getFieldBool(this, ["A", "alpha"]);
	}
	inline function get_STR()
	{
		return AnimationData.getFieldBool(this, ["STR", "strength"]);
	}
	inline function get_KK()
	{
		return AnimationData.getFieldBool(this, ["KK", "knockout"]);
	}
	inline function get_IN()
	{
		return AnimationData.getFieldBool(this, ["IN", "inner"]);
	}
}

@:forward
abstract DropShadowFilter(GlowFilter)
{
	public var HO(get, never):Bool;
	public var AL(get, never):Float;
	public var DST(get, never):Float;

	inline function get_HO()
	{
		return AnimationData.getFieldBool(this, ["HO", "hideObject"]);
	}
	inline function get_AL()
	{
		return AnimationData.getFieldBool(this, ["AL", "angle"]);
	}
	inline function get_DST()
	{
		return AnimationData.getFieldBool(this, ["DST", "distance"]);
	}
}

@:forward
abstract BevelFilter(BlurFilter)
{
	public var SC(get, never):String;
	public var SA(get, never):Float;
	public var HC(get, never):String;
	public var HA(get, never):Float;
	public var STR(get, never):Float;
	public var KK(get, never):Bool;
	public var AL(get, never):Float;
	public var DST(get, never):Float;
	public var TP(get, never):String;

	inline function get_SC()
	{
		return AnimationData.getFieldBool(this, ["SC", "shadowColor"]);
	}
	inline function get_SA()
	{
		return AnimationData.getFieldBool(this, ["SA", "shadowAlpha"]);
	}
	inline function get_HC()
	{
		return AnimationData.getFieldBool(this, ["HC", "highlightColor"]);
	}
	inline function get_HA()
	{
		return AnimationData.getFieldBool(this, ["HA", "highlightAlpha"]);
	}
	inline function get_STR()
	{
		return AnimationData.getFieldBool(this, ["STR", "strength"]);
	}
	inline function get_KK()
	{
		return AnimationData.getFieldBool(this, ["KK", "knockout"]);
	}
	inline function get_AL()
	{
		return AnimationData.getFieldBool(this, ["AL", "angle"]);
	}
	inline function get_DST()
	{
		return AnimationData.getFieldBool(this, ["DST", "distance"]);
	}
	inline function get_TP()
	{
		return AnimationData.getFieldBool(this, ["TP", "type"]);
	}
}
@:forward
abstract GradientFilter(BlurFilter)
{
	public var STR(get, never):Float;
	public var KK(get, never):Bool;
	public var AL(get, never):Float;
	public var DST(get, never):Float;
	public var TP(get, never):String;
	public var GE(get, never):Array<GradientEntry>;


	inline function get_STR()
	{
		return AnimationData.getFieldBool(this, ["STR", "strength"]);
	}
	inline function get_KK()
	{
		return AnimationData.getFieldBool(this, ["KK", "knockout"]);
	}
	inline function get_AL()
	{
		return AnimationData.getFieldBool(this, ["AL", "angle"]);
	}
	inline function get_DST()
	{
		return AnimationData.getFieldBool(this, ["DST", "distance"]);
	}
	inline function get_TP()
	{
		return AnimationData.getFieldBool(this, ["TP", "type"]);
	}
	inline function get_GE()
	{
		return AnimationData.getFieldBool(this, ["GE", "GradientEntries"]);
	}
}

abstract GradientEntry({})
{
	public var R(get, never):Float;
	public var C(get, never):String;
	public var A(get, never):Float;


	inline function get_R()
	{
		return AnimationData.getFieldBool(this, ["R", "ratio"]);
	}
	inline function get_C()
	{
		return AnimationData.getFieldBool(this, ["C", "color"]);
	}
	inline function get_A()
	{
		return AnimationData.getFieldBool(this, ["A", "alpha"]);
	}

}

enum abstract ColorMode(String) from String to String
{
	var Tint = "T";
	var Advanced = "AD";
	var Alpha = "CA";
	var Brightness = "CBRT";
}
abstract Bitmap({}) from {}
{
	/**
	 * The name of the drawing, basically determines which one of the sprites on spritemap should be used.
	 */
	public var N(get, never):String;

	/**
	 * Only used in earliest versions of texture atlas release. checks the position, nothing else lol
	 */
	public var POS(get, never):TransformationPoint;
	inline function get_N()
	{
		return AnimationData.getFieldBool(this, ["N", "name"]);
	}
	inline function get_POS()
	{
		return AnimationData.getFieldBool(this, ["POS", "Position"]);
	}
}
/**
 * The Sprite/Drawing abstract
 */
@:forward
abstract AtlasSymbolInstance(Bitmap) from {}
{
	/**
	 * The matrix of the sprite itself. Can be either an array or a typedef.
	 */
	public var M3D(get, never):OneOfTwo<Array<Float>, Matrix3D>;

	inline function get_M3D()
	{
		return AnimationData.getFieldBool(this, ["M3D", "Matrix3D"]);
	}
}

typedef Matrix3D =
{
	var m00:Float;
	var m01:Float;
	var m02:Float;
	var m03:Float;
	var m10:Float;
	var m11:Float;
	var m12:Float;
	var m13:Float;
	var m20:Float;
	var m21:Float;
	var m22:Float;
	var m23:Float;
	var m30:Float;
	var m31:Float;
	var m32:Float;
	var m33:Float;
}
/**
 * Position Stuff
 */
typedef TransformationPoint =
{
	var x:Float;
	var y:Float;
}

@:forward
enum abstract LoopType(String) from String to String
{
	var loop = "LP";
	var playonce = "PO";
	var singleframe = "SF";
}

enum abstract SymbolType(String) from String to String
{
	var graphic = "G";
	var movieclip = "MC";
	var button = "B";
}
@:forward
abstract OneOfTwo<T1, T2>(Dynamic) from T1 from T2 to T1 to T2 {}