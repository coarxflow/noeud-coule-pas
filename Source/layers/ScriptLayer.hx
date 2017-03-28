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

import reaction_scripts.ReactionScriptBase;


class ScriptLayer extends Sprite
{

	static var mask : LogicMask;
	
	public function new()
	{

	}

	public static function setMask(mask: LogicMask)
	{
		this.mask = mask;
	}

	public static function getMask()
	{
		return mask;
	}

	public static function reactToSprite(targetCoordinateSpace:DisplayObject, sprite: Bitmap)
	{
		var rm: Rectangle = movingSprite.getBounds(targetCoordinateSpace);

		var pt: Point = new Point(rm.x + rm.width/2, rm.y + rm.height/2);
		pt = decorSprite.globalToLocal(pt);
		var scnum: Int = mask.getXY(Math.round(pt.x/mask.downsampling_factor), Math.round(pt.y/mask.downsampling_factor));

		var script: ReactionScriptBase = getReactionScriptWithNum(scnum);
		script.trigger(sprite);
	}

	public static function getReactionScriptWithNum(scnum: Int) : ReactionScriptBase
	{
		switch(scnum)
		{
			case 1:

		}
	}

	public static var currentPaintScriptNum: UInt = 0;

	static inline var PAINT_RADIUS : Int = 15;
	static inline var PAINT_RADIUS_SQ : Int = 225;
	public static function paint(sprite: Bitmap)
	{
		var rm: Rectangle = sprite.getBounds(Main.targetCoordinateSpace);

		var center: Point = new Point(rm.x+rm.width/2, rm.y+rm.height/2);

		for(x in -PAINT_RADIUS...PAINT_RADIUS)
			for(y in -PAINT_RADIUS...PAINT_RADIUS)
			{
				if(Math.pow(x,2)+Math.pow(y,2)<=PAINT_RADIUS_SQ)
					bmp.setXY(PAINT_RADIUS+center.x, PAINT_RADIUS+center.y, currentPaintScriptNum);
			}
	}

}