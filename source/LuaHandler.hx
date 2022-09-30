package;

#if LUA_ENABLED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if desktop
import Discord;
#end

using StringTools;

class LuaFile {
	public var lua:State;
	public var scriptName:String;
	public var closed:Bool=false;

	public function new(script:String) {
		#if LUA_ENABLED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		trace('Lua version: ' + Lua.version());
		trace("LuaJIT version: " + Lua.versionJIT());

		//LuaL.dostring(lua, CLENSE);
		try{
			var result:Dynamic = LuaL.dofile(lua, script);
			var resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				trace('Error on lua script! ' + resultStr);
				#if windows
				lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
				#end
				lua = null;
				return;
			}
		} catch(e:Dynamic) {
			trace(e);
			return;
		}
		scriptName = script;
		trace('Successfully loaded a lua file!:' + script);

		// Lua variables \\
		#end
	}

	public function stop() {
		#if LUA_ENABLED
		if(lua == null) {
			return;
		}

		Lua.close(lua);
		lua = null;
		#end
	}

	public function call(func:String,args:Array<Dynamic>):Dynamic {
		#if LUA_ENABLED
		if(closed) return LuaHandler.Function_Continue;
		try {
			if(lua == null) return LuaHandler.Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);
			if (type != Lua.LUA_TFUNCTION) {
				return LuaHandler.Function_Continue;
			}
			
			for(arg in args) {
				Convert.toLua(lua, arg);
			}

			var result:Null<Int> = Lua.pcall(lua, args.length, 1, 0);
			var error:Dynamic = getErrorMessage();
			if(!resultIsAllowed(lua, result))
			{
				Lua.pop(lua, 1);
				if(error != null) luaTrace("ERROR (" + func + "): " + error, false, false, FlxColor.RED);
			}
			else
			{
				var conv:Dynamic = cast getResult(lua, result);
				Lua.pop(lua, 1);
				if(conv == null) conv = LuaHandler.Function_Continue;
				return conv;
			}
			return LuaHandler.Function_Continue;
		}
		catch (e:Dynamic) {
			trace(e);
		}
		#end
		return LuaHandler.Function_Continue;
	}

	// SHIT

	//me on my way to steal (from an open source) code (hi shadowmario!)
	function getResult(l:State, result:Int):Any {
		var ret:Any = null;

		switch(Lua.type(l, result)) {
			case Lua.LUA_TNIL:
				ret = null;
			case Lua.LUA_TBOOLEAN:
				ret = Lua.toboolean(l, -1);
			case Lua.LUA_TNUMBER:
				ret = Lua.tonumber(l, -1);
			case Lua.LUA_TSTRING:
				ret = Lua.tostring(l, -1);
		}
		
		return ret;
	}

	function resultIsAllowed(leLua:State, leResult:Null<Int>) { //Makes it ignore warnings
		var type:Int = Lua.type(leLua, leResult);
		return type >= Lua.LUA_TNIL && type < Lua.LUA_TTABLE && type != Lua.LUA_TLIGHTUSERDATA;
	}

	public function getBool(variable:String) {
		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if(result == null) {
			return false;
		}
		return (result == 'true');
	}

	public function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE) {
		#if LUA_ENABLED
		if(ignoreCheck || getBool('luaDebugMode')) {
			if(deprecated && !getBool('luaDeprecatedWarnings')) {
				return;
			}
			trace(text);
		}
		#end
	}

	function isErrorAllowed(error:String) {
		switch(error)
		{
			case 'attempt to call a nil value' | 'C++ exception':
				return false;
		}
		return true;
	}

	function getErrorMessage() {
		#if LUA_ENABLED
		var v:String = Lua.tostring(lua, -1);
		if(!isErrorAllowed(v)) v = null;
		return v;
		#end
	}
}

class LuaHandler {

	// grrr i hate this....
	public static var Function_Stop:Dynamic = 1;
	public static var Function_FUCKINGSTOP:Dynamic = 2;
	public static var Function_FUCK:Dynamic=Function_Stop;
	public static var Function_Continue:Dynamic = 0;
	public static var luasLoaded:Array<LuaFile> = [];

	public static function loadLua(script:String) {
		var luaFile:LuaFile = new LuaFile(script);
		if (luaFile.lua==null)
			return null;
		else
			{
				luasLoaded.insert(luasLoaded.length,luaFile);
				return luaFile;
			}
	}

	public static function callAll(callName:String, args:Array<Dynamic>, allowStops = false, scriptExclusions:Array<String> = null) {
		if (args==null) args=[];
		if(scriptExclusions == null) scriptExclusions = [];
		var returnVal:Dynamic = Function_Continue;
		#if LUA_ENABLED
		for (script in luasLoaded) {
			if(scriptExclusions.contains(script.scriptName))
				continue;

			var ret:Dynamic = script.call(callName, args);
			if(ret == LuaHandler.Function_FUCKINGSTOP && allowStops)
				break;
			
			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			var bool:Bool = ret == LuaHandler.Function_Continue;
			if(!bool) {
				returnVal = cast ret;
			}
		}
		#end
		//trace(event, returnVal);
		return returnVal;
	}
}