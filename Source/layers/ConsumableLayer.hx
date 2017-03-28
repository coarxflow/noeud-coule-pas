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

import layers.PhysicsLayer;
import alive_scripts.AliveScriptBase;


typedef UnitBitmap = {
	    var im : Bitmap;
	    var id : Int;
	    var persistent: Bool;
	}

class ConsumableLayer extends Sprite
{
	public var units : Array<UnitBitmap> = new Array<UnitBitmap>();
	
	private var boxes: Shape;
	private var labels: Array<TextField>;

	public function new () {
		super();
	}

	public function extractRegions(mask: LogicMask, image: Bitmap)
	{
		var r: LogicMask.LogicRegion;
		var u: UnitBitmap;
		var rect: Rectangle;
		var bmp: BitmapData;
		//units = new Array<UnitBitmap>();
		for(i in 0...mask.regions.length)
		{
			r = mask.regions[i];
			u = {im : new Bitmap(new BitmapData(r.right-r.left, r.bottom-r.top)), id: r.id, persistent: false};
			rect = new Rectangle(r.left, r.top, r.right-r.left, r.bottom-r.top);
			u.im.bitmapData.copyPixels(image.bitmapData, rect, new Point(0,0));

			for(x in 0...Math.ceil(r.right-r.left))
				for(y in 0...Math.ceil(r.bottom-r.top))
				{
					if(mask.getXY(Math.floor(r.left)+x,Math.floor(r.top)+y)==0)
						u.im.bitmapData.setPixel32(x,y,0);
				}

			u.im.x = r.left;
			u.im.y = r.top;

			//u.sc = new Still();

			//erase in original image
			bmp = layers.RandomPaperSample.getRegion(r.right-r.left, r.bottom-r.top);
			image.bitmapData.copyPixels(bmp, new Rectangle(0,0,r.right-r.left, r.bottom-r.top), new Point(r.left,r.top));

			units.push(u);
		}
	}

	public function offsetUnits(dx: Float, dy: Float)
	{
		for(unit in units)
		{
			unit.im.x+=dx;
			unit.im.y+=dy;
		}
	}

	public function drawUnits()
	{
		for(unit in units)
			addChild(unit.im);
	}

	public function consumeUnit(u: UnitBitmap)
	{
		if(!u.persistent)
		{
			removeChild(u.im);
			units.remove(u);
		}
	}

	public static inline var INFO_COLOR: Int = 0xCCCC22;

	public function drawInfo()
	{
		boxes = new Shape();
		labels = new Array<TextField>();
		
		var messageFormat:TextFormat = new TextFormat("Verdana", 10, INFO_COLOR, true);
		messageFormat.align = TextFormatAlign.CENTER;
		var label: TextField;

		for(i in 0...units.length)
		{
			boxes.graphics.lineStyle(1, INFO_COLOR, 1);
			boxes.graphics.drawRect(units[i].im.x, units[i].im.y, units[i].im.width, units[i].im.height);


		
			label = new TextField();
			addChild(label);
			label.width = 20;
			label.x = units[i].im.x + units[i].im.width - 15;
			label.y = units[i].im.y + units[i].im.height + 1;
			label.defaultTextFormat = messageFormat;
			label.selectable = false;
			label.text = ""+units[i].id;
			labels.push(label);
		}

		addChild(boxes);
	}

	public function hideInfo()
	{
		removeChild(boxes);
		for(label in labels)
		{
			removeChild(label);
		}
	}

	public function findClosest(x: Float, y: Float, r: Float) : UnitBitmap
	{
		r = Math.pow(r,2);

		var ci: UnitBitmap =  null;
		var cr2: Float = 1000000;
		for(unit in units)
		{
			var mx: Float = unit.im.x + unit.im.width/2;
			var my: Float = unit.im.y + unit.im.height/2;
			var rl: Float = Math.pow(x-mx,2) + Math.pow(y-my,2);
			if(rl < r && rl < cr2)
			{
				cr2 = rl;
				ci = unit;
			}
		}

		return ci;
	}

	public function addInvisible(x: Float, y: Float)
	{
		var unit: ConsumableLayer.UnitBitmap = {im: new Bitmap(new BitmapData(2,2,0x0)), id: -9, persistent: true};
		unit.im.x = x; unit.im.y = y;
		units.push(unit);
	}


}