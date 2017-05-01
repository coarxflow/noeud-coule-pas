package layers;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.DisplayObject;
import openfl.utils.ByteArray;

import openfl.geom.Rectangle;
import openfl.geom.Point;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

import haxe.Serializer;
import haxe.Unserializer;
import haxe.xml.Parser;
import haxe.xml.Printer;

import lime.math.color.ARGB;

import layers.AliveLayer;

import reaction_scripts.ReactionScriptBase;


class ScriptLayer
{

	public static inline var MASK_DOWNSAMPLING_FACTOR = 4;

	static var smask : LogicMask;
	static var decorSprite: Bitmap;

	static var scriptsBank: Map<Int, ReactionScriptBase>;

	public static var enabled: Bool = true;
	
	public static function buildBank()
	{
		scriptsBank = new Map<Int, ReactionScriptBase>();
		scriptsBank.set(1, new reaction_scripts.EnterDialog());
		scriptsBank.set(2, new reaction_scripts.DancingGround());
		scriptsBank.set(9, new reaction_scripts.RunningTrack());
	}

	public static function setMask(mask: LogicMask)
	{
		smask = mask;
	}

	public static function getMask(): LogicMask
	{
		return smask;
	}

	public static function getMaskImage() : openfl.display.Bitmap
	{
		return smask.toBitmap(0x44, 0xFF, 0x33, 0x66000000, 0x0);
	}

	public static function updateDecorSprite(sprite: Bitmap)
	{
		decorSprite = sprite;
	}

	public static function reactToSprite(targetCoordinateSpace:DisplayObject, sprite: Bitmap, id: Int)
	{
		if(!enabled)
			return;

		var rm: Rectangle = sprite.getBounds(targetCoordinateSpace);

		var pt: Point = new Point(rm.x + rm.width/2, rm.y + rm.height/2);
		pt = decorSprite.globalToLocal(pt);
		var scnum: Int = Math.round(smask.getXY(Math.round(pt.x/smask.downsampling_factor), Math.round(pt.y/smask.downsampling_factor))/PAINT_VALUE_MULTIPLIER);

		var script: ReactionScriptBase = getReactionScriptWithNum(scnum);
		if(script != null)
			script.trigger(sprite, id);
	}

	public static function getReactionScriptWithNum(scnum: Int) : ReactionScriptBase
	{
		return scriptsBank.get(scnum);
	}

	public static var currentPaintScriptNum: UInt = 0;

	static inline var PAINT_RADIUS : Int = 30;
	static inline var PAINT_RADIUS_SQ : Int = 900;
	static inline var PAINT_VALUE_MULTIPLIER = 25;
	public static function paint(sprite: Bitmap)
	{
		var rm: Rectangle = sprite.getBounds(Main.targetCoordinateSpace);

		var center: Point = new Point(rm.x+rm.width/2, rm.y+rm.height/2);

		for(x in -PAINT_RADIUS...PAINT_RADIUS)
			for(y in -PAINT_RADIUS...PAINT_RADIUS)
			{
				if(Math.pow(x,2)+Math.pow(y,2)<=PAINT_RADIUS_SQ)
					smask.setXY(Math.round((x+center.x)/smask.downsampling_factor), Math.round((y+center.y)/smask.downsampling_factor), currentPaintScriptNum*PAINT_VALUE_MULTIPLIER);
			}
	}

}