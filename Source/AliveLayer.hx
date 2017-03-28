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

import layers.PhysicsLayer;
import alive_scripts.AliveScriptBase;
import alive_scripts.Still;
import alive_scripts.RandomSpeed;
import alive_scripts.PlayerAttraction;

typedef UnitBitmap = {
	    var im : Bitmap;
	    var id : Int;
	    @:optional var sc : AliveScriptBase;
	}

class AliveLayer extends Sprite
{
	public var units : Array<UnitBitmap>;
	
	private var boxes: Shape;
	private var labels: Array<TextField>;

	//static var scriptsMap: Map<Int, haxe.macro.Type.ClassType>;

	public function new () {
		super();

		/*if(scriptsMap == null)
		{
			scriptsMap = new Map<Int, haxe.macro.Type.ClassType>();
			scriptsMap.set(0, Still);
		}*/
	}

	public function extractRegions(mask: LogicMask, image: Bitmap, scene_name: String)
	{
		var r: LogicMask.LogicRegion;
		var u: UnitBitmap;
		var rect: Rectangle;
		var bmp: BitmapData;
		units = new Array<UnitBitmap>();
		for(i in 0...mask.regions.length)
		{
			r = mask.regions[i];
			u = {im : new Bitmap(new BitmapData(r.right-r.left, r.bottom-r.top)), id: r.id};
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

			u.sc = new Still();

			//erase in original image
			bmp = layers.RandomPaperSample.getRegion(r.right-r.left, r.bottom-r.top);
			//bmp = new BitmapData(r.right-r.left, r.bottom-r.top);
			//bmp.noise(777, 240, 255);
			image.bitmapData.copyPixels(bmp, new Rectangle(0,0,r.right-r.left, r.bottom-r.top), new Point(r.left,r.top));

			units.push(u);
		}
	}

	public function offsetUnits(dx: Float, dy: Float)
	{
		Sys.println("offset alive units by "+dx+" "+dy);

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

	public static inline var INFO_COLOR: Int = 0xCC2222;

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

	public function drawHiglightedUnit(uid: Int)
	{
		var ub : UnitBitmap = null;
		for (u in units)
			if(u.id == uid)
				ub=u;

		boxes = new Shape();
		labels = new Array<TextField>();

		boxes.graphics.lineStyle(1, INFO_COLOR, 1);
		boxes.graphics.drawRect(ub.im.x, ub.im.y, ub.im.width, ub.im.height);

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

	public var sceneGravity: Bool = false;

	public function unitsAct(targetCoordinateSpace:DisplayObject, chunk_index:Int, chunk_total: Int)
	{
		var b: Int = chunk_index * Math.ceil(units.length/chunk_total);
		var e: Int = Math.round(Math.min((chunk_index+1) * Math.ceil(units.length/chunk_total), units.length));
		for (u in b...e)
		{
			if(units[u].id == PlayerControl.aliveUnitId)
			{
				continue;
			}
			else
			{
				var pt: openfl.geom.Point = units[u].sc.nextMove(units[u].im);
				if (sceneGravity)
					pt.y += PlayerControl.GRAVITY_ACCELERATION;
				moveSprite(units[u].im, Math.round(pt.x), Math.round(pt.y), targetCoordinateSpace);
				PhysicsLayer.registerMovingElement(targetCoordinateSpace, units[u].im);
			}
		}
	}

	public function mergeUnits(id1: Int, id2: Int)
	{
		var unit1: UnitBitmap = null;
		var unit2: UnitBitmap = null;
		for(unit in units)
		{
			if(unit.id == id1)
				unit1 = unit;
			if(unit.id == id2)
				unit2 = unit;
		}

		if(unit1 != null && unit2 != null)
		{
			var r1: Rectangle = unit1.im.getBounds(Main.targetCoordinateSpace);
			var r2: Rectangle = unit2.im.getBounds(Main.targetCoordinateSpace);

			var ri: Rectangle = r1.intersection(r2);

			if(ri.isEmpty())
				return;

			var xb: Int = Math.floor(ri.x);
			var yb: Int = Math.floor(ri.y);
			var xe: Int = Math.ceil(ri.x+ri.width);
			var ye: Int = Math.ceil(ri.y+ri.height);

			var pt: Point = new Point(0,0);

			var col2: ARGB;

			for (x in xb ... xe) {
				for (y in yb ...ye) {
					pt.x=x; pt.y=y;
					pt=unit2.im.globalToLocal(pt);
					col2 = new ARGB(unit2.im.bitmapData.getPixel32(Math.round(pt.x), Math.round(pt.y)));
					if (col2.a > 0)
					{
						pt.x=x; pt.y=y;
						pt=unit1.im.globalToLocal(pt);
						unit1.im.bitmapData.setPixel32(Math.round(pt.x), Math.round(pt.y), col2);
					}
				}
			}
		}
	}

	static inline var MOVEMENT_APPLY_STEP: Float = 2;
	public static function moveSprite(sprite: Bitmap, dx: Float, dy: Float, targetCoordinateSpace:DisplayObject)
	{
		//rotateSprite(sprite, dx, dy);

		var ax: Float = 0;
		var ay: Float = 0;

		var sx: Float = 0;
		var sy: Float = 0;

		var flag: Bool = true;
		//test that no wall were collided smoothly
		while((ax <= Math.abs(dx) || ay <= Math.abs(dy)) && flag)
		{
			if(ax < Math.abs(dx))
			{
				ax += MOVEMENT_APPLY_STEP;
				if (dx>0)
					sx = MOVEMENT_APPLY_STEP;
				else
					sx = -MOVEMENT_APPLY_STEP;
			}
			else
			{
				sx = 0;
			}

			if(ay < Math.abs(dy))
			{
				ay += MOVEMENT_APPLY_STEP;
				if (dy>0)
					sy = MOVEMENT_APPLY_STEP;
				else
					sy = -MOVEMENT_APPLY_STEP;
			}
			else
			{
				sy = 0;
			}
			sprite.x += sx;
			sprite.y += sy;
			var cr:CollisionResult = PhysicsLayer.checkForColision(targetCoordinateSpace, sprite);

			if(cr.left_in != 0)
			{
				sprite.x += cr.left_in;
				flag = false;
			}
			if(cr.right_in != 0)
			{
				sprite.x -= cr.right_in;
				flag = false;
			}
			if(cr.top_in != 0)
			{
				sprite.y += cr.top_in;
				flag = false;
			}
			if(cr.bottom_in != 0)
			{
				sprite.y -= cr.bottom_in;
				flag = false;
			}

			if(sx == 0 && sy== 0)
				flag = false;

		}
	}

	private static function rotateSprite(sprite: Bitmap, dx: Int, dy: Int)
	{
		//Sys.println(sprite.rotation+" "+Math.atan2(dy,dx));
		//sprite.
	}

	public function transferUnitTo(layer: AliveLayer, unit_id:Int)
	{
		var ub : UnitBitmap = null;
		for (u in units)
			if(u.id == unit_id)
				ub=u;

		if(ub != null)
		{
			units.remove(ub);
			removeChild(ub.im);
			layer.units.push(ub);
			layer.addChild(ub.im);
		}
	}

	public function findClosestUnit(to: Int) : AliveLayer.UnitBitmap
	{
		var ub : UnitBitmap = null;
		for (u in units)
			if(u.id == to)
				ub=u;

		var cp: Point = new Point(ub.im.x + ub.im.width/2, ub.im.y + ub.im.height/2);
		var r2min : Float = Math.pow(50,2); //should be at least 50px close
		var r2: Float = 0;
		var ub2 : UnitBitmap = null;
		for (u in units)
			if(u.id != to)
			{
				r2 = Math.pow(u.im.x + u.im.width/2 - cp.x, 2) + Math.pow(u.im.y + u.im.height/2 - cp.y, 2);
				if(r2 < r2min)
				{
					r2min = r2;
					ub2 = u;
				}
			}

		if(ub2 != null)
			Sys.println("found "+ub2.id);
		else
			Sys.println("found no close obj");

		return ub2;
	}

	public function assignScriptToUnit(to: Int, script_index: Int)
	{
		var ub : UnitBitmap = null;
		for (u in units)
			if(u.id == to)
				ub=u;


		if(ub == null)
			return;

		switch(script_index)
		{
			case 1:
			ub.sc = new RandomSpeed();
			case 2:
			ub.sc = new PlayerAttraction(PlayerControl.playerSprite);
			case 0:
			default:
			ub.sc = new Still();
		}
	}

	///// IO

	public function serialize() : String
	{
		var doc: Xml = Xml.createDocument();

		var root = Xml.createElement("AliveLayer");
		doc.addChild(root);

		for(unit in units)
		{
			var id = Xml.createElement("unit");
			id.set("id",""+unit.id);
			id.set("x", ""+unit.im.x);
			id.set("y", ""+unit.im.y);

			root.addChild(id);


		}
		
		return Printer.print(doc, true);
	}

	public function parseAndLoad(txt: String, imdir: String, assets: ExtendedAssetManifest)
	{
		Sys.println(txt);
		var doc: Xml = Parser.parse(txt);


		var root = doc.firstElement();
		var elemit = root.elements();

		units = new Array<UnitBitmap>();

		while(elemit.hasNext())
		{
			var id = elemit.next();
			if(id.nodeName == "unit")
			{
				
				var ub: UnitBitmap = {im : null, id: -1};
				ub.id = Std.parseInt(id.get("id"));
				var bmp = assets.getBitmap(imdir+"unit_"+ub.id+'.png');
				if(bmp != null)
					ub.im = new Bitmap(bmp);
				else
					ub.im = new Bitmap(new openfl.display.BitmapData(1,1));
				ub.im.x = Std.parseFloat(id.get("x"));
				ub.im.y = Std.parseFloat(id.get("y"));

				ub.sc = new Still();

				units.push(ub);
			}
		}
	}

	public function serializeScriptMapping() : String
	{
		var doc: Xml = Xml.createDocument();

		var root = Xml.createElement("ScriptMap");
		doc.addChild(root);

		for(unit in units)
		{
			if(unit.id == PlayerControl.aliveUnitId)
				continue;

			var id = Xml.createElement("unit");
			id.set("id",""+unit.id);
			id.set("scnum",""+unit.sc.NUM);

			root.addChild(id);


		}
		
		return Printer.print(doc, true);
	}

	public function parseScriptMapping(txt: String)
	{
		var doc: Xml = Parser.parse(txt);


		var root = doc.firstElement();
		var elemit = root.elements();

		while(elemit.hasNext())
		{
			var id = elemit.next();
			if(id.nodeName == "unit")
			{
				var uid : Int = Std.parseInt(id.get("id"));
				var num : Int = Std.parseInt(id.get("scnum"));
				assignScriptToUnit(uid, num);
			}
		}
	}
}