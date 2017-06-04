package layers;

import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import lime.math.color.ARGB;

class ShakingDecorRegion extends AnimatedRegion {
	var targetSprite: Bitmap;
	var targetPhysicLayer: LogicMask;

	var insertData: BitmapData;
	var insertPhysic: LogicMask;

	var period: Float;
	var next_change: Float;

	var amplitude: Float;

	var im_index: Int;

	public function new(region: Rectangle, targetSprite: Bitmap, targetPhysicLayer: LogicMask, insertData: BitmapData, period: Float, delay: Float, amplitude: Float = 2) {
		super(region);
		this.targetSprite = targetSprite;
		this.targetPhysicLayer = targetPhysicLayer;
		this.insertData = insertData;

		this.insertPhysic = SceneProcessor.filterColor(this.insertData, SceneProcessor.blackfilter);

		this.period = period;
		this.amplitude = amplitude;

		im_index = 0;
		next_change = Sys.time()+delay;
	}

	public override function insertStep() {
		
		if(Sys.time() > next_change)
		{
			var xb: Int = Math.floor(region.x);
			var yb: Int = Math.floor(region.y);
			var xe: Int = Math.ceil(region.x+region.width);
			var ye: Int = Math.ceil(region.y+region.height);

			//clear last insert
			var dx: Float = 0;
			var dy: Float = 0;
			switch(im_index-1)
			{
				case -1:
				dy = -amplitude;
				case 0:
				dx = amplitude;
				case 1:
				dy = amplitude;
				case 2:
				dx = -amplitude;
			}

			var pt: Point = new Point(0,0); //sampling point
			var col : ARGB;

			for (x in xb ... xe) {
				for (y in yb ...ye) {
					col = new ARGB(insertData.getPixel32(x-xb, y-yb));
					if(col.a > 0)
					{
						pt.x=x+dx; pt.y=y+dy;
						pt=targetSprite.localToGlobal(pt);
						targetSprite.bitmapData.setPixel32(Math.round(pt.x), Math.round(pt.y), layers.RandomPaperSample.getPixel(Math.round(pt.x), Math.round(pt.y)));
						targetPhysicLayer.setXY(Math.round(pt.x/insertPhysic.downsampling_factor), Math.round(pt.y/insertPhysic.downsampling_factor), 0);
				 	}
				}
			}

			//new insert
			dx = 0; dy = 0;
			switch(im_index)
			{
				case 0:
				dx = amplitude;
				case 1:
				dy = amplitude;
				case 2:
				dx = -amplitude;
				case 3:
				dy = -amplitude;
			}

			for (x in xb ... xe) {
				for (y in yb ...ye) {
					col = new ARGB(insertData.getPixel32(x-xb, y-yb));
					if(col.a > 0)
					{
						pt.x=x+dx; pt.y=y+dy;
						pt=targetSprite.localToGlobal(pt);
						targetSprite.bitmapData.setPixel32(Math.round(pt.x), Math.round(pt.y), col);
						targetPhysicLayer.setXY(Math.round(pt.x/insertPhysic.downsampling_factor), Math.round(pt.y/insertPhysic.downsampling_factor), insertPhysic.getXY(Math.round((x-xb)/insertPhysic.downsampling_factor), Math.round((y-yb)/insertPhysic.downsampling_factor)));
				 	}
				}
			}

			//loop
			next_change = Sys.time()+period;
			im_index++;
			if(im_index >= 4)
				im_index = 0;
		}

	}
}