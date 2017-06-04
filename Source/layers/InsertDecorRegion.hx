package layers;

import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import lime.math.color.ARGB;

class InsertDecorRegion extends AnimatedRegion {
	var targetSprite: Bitmap;
	var targetPhysicLayer: LogicMask;

	var insertData: BitmapData;
	var insertPhysic: LogicMask;

	var draw_time: Float;

	public function new(region: Rectangle, targetSprite: Bitmap, targetPhysicLayer: LogicMask, insertData: BitmapData, delay: Float = 0) {
		super(region);
		this.targetSprite = targetSprite;
		this.targetPhysicLayer = targetPhysicLayer;
		this.insertData = insertData;
		this.draw_time = Sys.time()+delay;

		this.insertPhysic = SceneProcessor.filterColor(this.insertData, SceneProcessor.blackfilter);
	}

	public override function insertStep() {

		if(Sys.time() < draw_time)
			return;

		var xb: Int = Math.floor(region.x);
		var yb: Int = Math.floor(region.y);
		var xe: Int = Math.ceil(region.x+region.width);
		var ye: Int = Math.ceil(region.y+region.height);

		var pt: Point = new Point(0,0); //sampling point
		var col : ARGB;

		/*pt.x = region.x; pt.y = region.y;
		pt=targetSprite.globalToLocal(pt);
		targetSprite.bitmapData.copyPixels(insertData, new Rectangle(0,0,insertData.width,insertData.height), pt);*/
		//insert physics
		for (x in xb ... xe) {
			for (y in yb ...ye) {
				//Sys.print((x-xb)+" "+(y-yb)+" ");
				//Sys.print(insertData.getPixel32(x-xb, y-yb)+" ");
				col = new ARGB(insertData.getPixel32(x-xb, y-yb));
				if(col.a > 0)
				{
					pt.x=x; pt.y=y;
					pt=targetSprite.globalToLocal(pt);
					//Sys.print(pt.x+" "+pt.y+" ");
					targetSprite.bitmapData.setPixel32(Math.round(pt.x), Math.round(pt.y), col);
					//Sys.print(Math.round((x-xb)/insertPhysic.downsampling_factor)+" "+Math.round((y-yb)/insertPhysic.downsampling_factor)+" "+insertPhysic.getXY(Math.round((x-xb)/insertPhysic.downsampling_factor), Math.round((y-yb)/insertPhysic.downsampling_factor))+" ");
					targetPhysicLayer.setXY(Math.round(pt.x/insertPhysic.downsampling_factor), Math.round(pt.y/insertPhysic.downsampling_factor), insertPhysic.getXY(Math.round((x-xb)/insertPhysic.downsampling_factor), Math.round((y-yb)/insertPhysic.downsampling_factor)));
			 	}
			}
		}

		complete = true;

	}
}