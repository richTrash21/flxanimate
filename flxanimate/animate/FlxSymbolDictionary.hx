package flxanimate.animate;

import flixel.FlxG;

import haxe.extern.EitherType;
import haxe.io.Path;

class FlxSymbolDictionary
{
	var _parent:FlxAnim;

	var _mcFrame:Map<String, Int> = [];

	var _symbols:Map<String, FlxSymbol> = [];

	public var length(default, null):Int;

	public function new(?parent:FlxAnim)
	{
		_parent = parent;
		_symbols = [];
	}


	public function getLibrary(library:String):Map<String, FlxSymbol>
	{
		var path = Utils.directory(Path.addTrailingSlash(library));
		return [
			for (instance => symb in _symbols)
				if (path == instance)
					path => symb
		];
	}

	public inline function existsSymbol(symbol:String)
	{
		return _symbols.exists(symbol);
	}

	public inline function getSymbol(symbol:String)
	{
		return _symbols.get(symbol);
	}

	public function addSymbol(symbol:FlxSymbol, ?overrideSymbol:Bool = false)
	{
		if (_symbols.exists(symbol.name) && !overrideSymbol)
		{
			symbol.name += " Copy";
		}

		_symbols.set(symbol.name, symbol);

		length++;
	}

	public function addLibrary(library:Map<String, FlxSymbol>, ?overrideSymbol:Bool = false)
	{
		for (symbol in library)
		{
			addSymbol(symbol, overrideSymbol);
		}
	}

	public function removeLibrary(library:String)
	{
		var bool:Bool = false;

		var library = getLibrary(library);

		for (symbol in library)
		{
			if (removeSymbol(symbol))
				bool = true;
		}

		return bool;
	}
	public function removeSymbol(symbol:EitherType<FlxSymbol, String>)
	{
		var bool:Bool = _symbols.remove(Std.isOfType(symbol, FlxSymbol) ? cast (symbol, FlxSymbol).name : symbol);

		if (bool)
			length--;

		return bool;
	}
}