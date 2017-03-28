package layers;

import openfl.display.BitmapData;

class RandomPaperSample {
	
	public static var sample: BitmapData;

	public static function getPixel(x: Float, y: Float) : Int
	{
		return sample.getPixel(Math.floor(Math.random()*sample.width),Math.floor(Math.random()*sample.height));
	}

	public static function getRegion(w: Int, h: Int) : BitmapData
	{
		var bmp : BitmapData = new BitmapData(w,h);
		for (x in 0...w)
			for (y in 0...h)
			{
				bmp.setPixel(x,y,sample.getPixel(Math.floor(Math.random()*sample.width),Math.floor(Math.random()*sample.height)));
			}
		return bmp;
	}

}