package;

import flixel.util.FlxColor;
import Controls.KeyboardScheme;
import flixel.FlxG;
import openfl.display.FPS;
import openfl.Lib;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
using StringTools;

class OptionCatagory
{
	private var _options:Array<Dynamic> = [];
	public final function getOptions():Array<Dynamic>
	{
		return _options;
	}

	public final function addOption(opt:Option)
	{
		_options.push(opt);
	}

	
	public final function removeOption(opt:Option)
	{
		_options.remove(opt);
	}

	private var _name:String = "New Catagory";
	
	public final function getName() {
		return _name;
	}

	public function new (catName:String, options:Array<Option>)
	{
		_name = catName;
		_options = options;
	}
}

class Option
{
	public var name:String;
	public var type:String;
	public var value:Dynamic;
	public var desc:String;
	public var saveNAME:String;
	var acceptValues:Dynamic;
	public var setData:Array<Dynamic>;
	public function new(settingData)
	{
		setData=settingData;
		name=settingData[0];
		type=settingData[2];
		var curValue:Dynamic = EngineData.getOption(settingData[5]);
		if (type=="bool")
			{
			 	curValue = CoolUtil.stringToBool(Std.string(curValue));
			}
		else if (type=="number")
			{
				curValue = Std.parseInt(curValue);
			}
		value=curValue;
		acceptValues= curValue;
		desc=settingData[1];
		saveNAME=settingData[5];
		display = updateDisplay();
	}
	var display:String;
	public var withoutCheckboxes:Bool = false;
	public var boldDisplay:Bool = true;
	public function getDisplay():String
	{
		return display;
	}

	public function getDesc(theValue:Dynamic):String
		if (desc.contains('[1]'))
			{
				return desc.replace('[1]',theValue);
			}
		else
			{
				return desc;
			}

	public function getAccept():Bool
	{
		return value;
	}
	
	// Returns whether the label is to be updated.

	public function press(changeData:Bool):Bool
	{
		if(changeData)
			{
				if (type == 'bool')
					{
						value = !value;
					}
				EngineData.setData(saveNAME,value);
				acceptValues = (value != null && value != false) ? true : false;
			}
		display = updateDisplay();
		return true;
	}

	public function updateDisplay():String { 
		return name;
	}

	public function left():Bool { return false; }
	public function right():Bool { return false; }
}