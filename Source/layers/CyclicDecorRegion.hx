package layers;

import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import lime.math.color.ARGB;

class CyclicDecorRegion extends AnimatedRegion {
	var targetSprite: Bitmap;
	var targetPhysicLayer: LogicMask;

	var insertData: Array<BitmapData>;
	var insertPhysic: Array<LogicMask>;

	var period: Float;
	var next_change: Float;

	var im_index: Int;

	public function new(region: Rectangle, targetSprite: Bitmap, targetPhysicLayer: LogicMask, insertData: Array<BitmapData>, period: Float) {
		super(region);
		this.targetSprite = targetSprite;
		this.targetPhysicLayer = targetPhysicLayer;
		this.insertData = insertData;

		this.insertPhysic = new Array<LogicMask>();
		for(i in 0...insertData.length)
			this.insertPhysic.push(SceneProcessor.filterColor(this.insertData[i], SceneProcessor.blackfilter));

		this.period = period;

		im_index = 0;
		next_change = 0;
	}

	public override function insertStep() {
		
		if(Sys.time() > next_change)
		{
			var xb: Int = Math.floor(region.x);
			var yb: Int = Math.floor(region.y);
			var xe: Int = Math.ceil(region.x+region.width);
			var ye: Int = Math.ceil(region.y+region.height);

			var pt: Point = new Point(0,0); //sampling point
			var col : ARGB;

			for (x in xb ... xe) {
				for (y in yb ...ye) {
					col = new ARGB(insertData[im_index].getPixel32(x-xb, y-yb));
					if(col.a > 0)
					{
						pt.x=x; pt.y=y;
						//pt=targetSprite.globalToLocal(pt);
						targetSprite.bitmapData.setPixel32(Math.round(pt.x), Math.round(pt.y), col);
						targetPhysicLayer.setXY(Math.round(pt.x/insertPhysic[im_index].downsampling_factor), Math.round(pt.y/insertPhysic[im_index].downsampling_factor), insertPhysic[im_index].getXY(Math.round((x-xb)/insertPhysic[im_index].downsampling_factor), Math.round((y-yb)/insertPhysic[im_index].downsampling_factor)));
				 	}
				}
			}

			//loop
			next_change = Sys.time()+period;
			im_index++;
			if(im_index >= insertData.length)
				im_index = 0;
		}

	}
}