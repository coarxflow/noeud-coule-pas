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

typedef UnitBitmap2 = {
	    var im : Bitmap;
	    var id : Int;
	    var persistent: Bool;
	}

class ConsumableLayer extends Sprite
{

	public static inline var MASK_DOWNSAMPLING_FACTOR = 1;

	public var units : Array<UnitBitmap2> = new Array<UnitBitmap2>();
	
	private var boxes: Shape;
	private var labels: Array<TextField>;

	private var max_id: Int = 0;

	public function new () {
		super();
	}

	public function extractRegions(mask: LogicMask, image: Bitmap)
	{
		var r: LogicMask.LogicRegion;
		var u: UnitBitmap2=null;
		var rect: Rectangle;
		var bmp: BitmapData;
		//units = new Array<UnitBitmap>();
		for(i in 0...mask.regions.length)
		{
			r = mask.regions[i];
			u = {im : new Bitmap(new BitmapData(r.right-r.left, r.bottom-r.top)), id: max_id+r.id, persistent: false};
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

		if(u != null)
			max_id = u.id;
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

	public function consumeUnit(u: UnitBitmap2)
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

	public function findClosest(x: Float, y: Float, r: Float) : UnitBitmap2
	{
		r = Math.pow(r,2);

		var ci: UnitBitmap2 =  null;
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

	public function findNextId(crt_object: UnitBitmap2) : UnitBitmap2
	{
		var cci: Int =  0;
		if(crt_object != null)
			cci = crt_object.id;
		var cni: Int = 10000000;
		var cn: UnitBitmap2 = null;
		for(unit in units)
		{
			if(unit.id > cci && unit.id < cni)
			{
				cni = unit.id;
				cn = unit;
			}
		}

		return cn;
	}

	public function getMaxId()
	{
		return max_id;
	}

	public function addInvisible(x: Float, y: Float, persist: Bool): layers.ConsumableLayer.UnitBitmap2
	{
		max_id++;
		var unit: UnitBitmap2 = {im: new Bitmap(new BitmapData(2,2,0x0)), id: max_id, persistent: persist};
		unit.im.x = x; unit.im.y = y;
		units.push(unit);
		return unit;
	}

	public function flush()
	{
		units = new Array<UnitBitmap2>();
		max_id = 0;
	}


	///// IO

	public function serialize() : String
	{
		var doc: Xml = Xml.createDocument();

		var root = Xml.createElement("AliveLayer");
		doc.addChild(root);

		for(unit in units)
		{
			if(unit.im != null) //save those with pics, not the invisible ones, which come from xml
			{
				var id = Xml.createElement("unit");
				id.set("id",""+unit.id);
				id.set("x", ""+unit.im.x);
				id.set("y", ""+unit.im.y);
				id.set("persist", ""+unit.persistent);

				root.addChild(id);
			}


		}
		
		return Printer.print(doc, true);
	}

	public function parseAndLoad(txt: String, imdir: String, assets: ExtendedAssetManifest)
	{
		var doc: Xml = Parser.parse(txt);


		var root = doc.firstElement();
		var elemit = root.elements();

		units = new Array<UnitBitmap2>();

		while(elemit.hasNext())
		{
			var id = elemit.next();
			if(id.nodeName == "unit")
			{
				
				var ub: UnitBitmap2 = {im : null, id: -1, persistent: false};
				ub.id = Std.parseInt(id.get("id"));
				var bmp = assets.getBitmap(imdir+"unit_"+ub.id+'.png');
				if(bmp != null)
					ub.im = new Bitmap(bmp);
				else
					ub.im = new Bitmap(new openfl.display.BitmapData(1,1));
				ub.im.x = Std.parseFloat(id.get("x"));
				ub.im.y = Std.parseFloat(id.get("y"));

				var persist = id.get("persist");
				if(persist == "true")
					ub.persistent = true;
				else
					ub.persistent = false;

				units.push(ub);
			}
		}
	}

}