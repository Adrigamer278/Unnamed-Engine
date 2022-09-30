package;

import haxe.DynamicAccess;
import Controls;
import flixel.FlxCamera;
import openfl.Assets;
import flixel.FlxG;
import flixel.util.FlxSignal;
import haxe.Json;
import flixel.util.FlxSave;

typedef DefaultData =
{
	var options:Array<OptionSave>;
	var binds:DynamicAccess<Array<String>>;
}

typedef OptionSave = // the way options are saved on the defaultData json
{
	var name:String; // option name
	var value:Dynamic; // the fucking value
	var saveKey:Null<String>; // OPTIONAL (save key, if not its for )
}

class EngineData
{
	public var keyAmount:Array<Dynamic>=[1,2,3,4,5,6,7,8,9]; // SAY THE AMOUNT OF KEYS TO SAVE!
	public var loaded:Bool=false;

	public static var bindPrefix:String = "unnamed_engine-";
	public static var defaultData:DefaultData;
    public static var bindPath:String = "minz";

	public  static var loadedSaves:Map<String, FlxSave> = [];

	public static function init()
		{
				// LOAD DATA

				load();

				// ENGINE LOADED DO STUFF!
		}

	public static function createSave(key:String, suf:String):Dynamic {
		var save:FlxSave = new FlxSave();
        save.bind(bindPrefix + suf, bindPath);
        loadedSaves.set(key, save);
		return save;
	}

	public static function deleteSave(key:String,suf:String):Void {
		if(loadedSaves.exists(key))
			{
				loadedSaves.get(key).erase();
			}
		else 
			{
				createSave(key,suf);
				loadedSaves.get(key).erase();
			}
	}

	public static function save(key:String):Void {
		if(loadedSaves.exists(key))
			{
				loadedSaves.get(key).flush();
			}
	}

	public static function getData(dataKey:String, ?saveKey:String = "options"):Dynamic
		{
			if(loadedSaves.exists(saveKey))
				return Reflect.getProperty(Reflect.getProperty(loadedSaves.get(saveKey), "data"), dataKey);
	
			return null;
		}

	public static function setData(dataKey:String, value:Dynamic, ?saveKey:String = "options")
		{
			if(loadedSaves.exists(saveKey))
			{
				trace("Setting "+dataKey+" with value: "+value+ " on "+saveKey);
				Reflect.setProperty(Reflect.getProperty(loadedSaves.get(saveKey), "data"), dataKey, value);
				save(dataKey);
			}
		}
	
	public static function getBinds(keyNum:Dynamic) :Array<String>{
		var keys=Std.string(keyNum);
		return getData(keys,"binds");
	}

	public static function getOption(optionName:String):Dynamic {
		return getData(optionName,"options");
	}

	public static function getJudgements() {
		return [];
	}
	
	public static function load():Void {
		// fucking load the data!

		createSave("options","options");
		createSave("highscores","highscores");
		createSave("binds","binds");

		defaultData = Json.parse(Assets.getText(Paths.json("defaultData")));

		for (option in defaultData.options)
			{
				var saveKey:String = option.saveKey != null ? option.saveKey : "options";
				var dataKey:String = option.name != null ? option.name : "what the fuck";
	
				if(Reflect.getProperty(Reflect.getProperty(loadedSaves.get(saveKey), "data"), dataKey) == null)
					{
						trace("Adding missing key: "+ dataKey);
						setData(dataKey, option.value, saveKey);
					}
			}

		trace("Options loaded!");
		trace(loadedSaves.get("options").data);

		for (bindName in defaultData.binds.keys())
			{
				var saveKey:String = "binds";
				var dataKey:String = bindName;
				var data:Array<String>=defaultData.binds.get(bindName);
	
				if(Reflect.getProperty(Reflect.getProperty(loadedSaves.get(saveKey), "data"), dataKey) == null)
					{
						setData(dataKey, data, saveKey);
						trace("ADDED MISSING KEYBINDS FOR "+dataKey+" KEYS");
					}
			}
		trace("Binds loaded!");
		trace(loadedSaves.get("binds").data);
		trace(getBinds("4"));
	}
}
