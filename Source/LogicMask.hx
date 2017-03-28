import openfl.display.Bitmap;
import openfl.display.BitmapData;

import lime.utils.UInt8Array;

import haxe.io.Bytes;

typedef LogicRegion = {
		var id : Int;
	    var left : Int;
	    var right : Int;
	    var top : Int;
	    var bottom : Int;
	}

class LogicMask {

	public var width: Int;
	public var height: Int;
	public var downsampling_factor: Int;

	public var regions: Array<LogicMask.LogicRegion>;

	private var buffer: UInt8Array;

	public function new(w:Int, h:Int, df:Int)
	{
		width = w;
		height = h;
		buffer = new UInt8Array(w*h);
		downsampling_factor = df;
	}

	public function fill(value: UInt)
	{
		for (i in 0...buffer.length)
		{
			buffer.__set(i, value);
		};
	}

	public function getXY(x:Int, y:Int): UInt
	{
		return buffer.__get(x+y*width);
	}


	public function setXY(x:Int, y:Int, val: UInt)
	{
		buffer.__set(x+y*width, val);
	}

	public function toBitmap(rchannel:Int = 0xFF, gchannel:Int = 0xFF, bchannel:Int = 0xFF):Bitmap
	{
		var image: BitmapData = new BitmapData(width, height,true,0xFF000000);
		var pix: UInt;
		for(x in 0...width)
			for(y in 0...height)
			{
				if(buffer.__get(x+y*width) != 0)
				{
					pix = buffer.__get(x+y*width);
					image.setPixel32(x,y, 0xFF000000 | ((rchannel & pix) << 16) | ((gchannel & pix) << 8) | (bchannel & pix));
				}
			}
		
		return new Bitmap(image);
	}

	public static function fromBitmap(bmp: Bitmap):LogicMask
	{
		var lm: LogicMask = new LogicMask(bmp.bitmapData.width,bmp.bitmapData.height,1);
		for(x in 0...bmp.bitmapData.width)
			for(y in 0...bmp.bitmapData.height)
			{
				lm.buffer.__set(x+y*bmp.bitmapData.width, bmp.bitmapData.getPixel32(x,y));
			}
		
		return lm;
	}

	public function toBytes():Bytes
	{
		var bytes: Bytes = Bytes.alloc(width*height+3*4);
		bytes.setInt32(0,width);
		bytes.setInt32(4,height);
		bytes.setInt32(8,downsampling_factor);

		bytes.blit(12,buffer.toBytes(),0,width*height);
		
		return bytes;
	}

	public function blendIn(other : LogicMask, overwrite: Bool = false)
	{
		if(other.width != this.width || other.height != this.height)
		{
			Sys.println("Logic masks to blend do not have matching dimensions.");
			return;
		}

		var pix: UInt;
		for(x in 0...width)
			for(y in 0...height)
			{
				pix = other.buffer.__get(x+y*width);
				if(pix != 0)
				{
					if(buffer.__get(x+y*width) == 0 || overwrite)
					{
						buffer.__set(x+y*width, pix);
					}
				}
			}
	}

	// public static function fromBytes():LogicMask
	// {
	// 	var bytes: Bytes = Bytes.alloc(width*height+3*4);
	// 	bytes.setInt32(0,width);
	// 	bytes.setInt32(4,height);
	// 	bytes.setInt32(8,downsampling_factor);

	// 	bytes.blit(12,buffer.toBytes(),0,width*height);
		
	// 	return bytes;
	// }

	public static var DISK_SE: Array<Array<UInt>> = [
	[0, 0, 0, 1, 0, 0, 0],
	[0, 1, 1, 1, 1, 1, 0],
	[0, 1, 1, 1, 1, 1, 0],
	[1, 1, 1, 1, 1, 1, 1],
	[0, 1, 1, 1, 1, 1, 0],
	[0, 1, 1, 1, 1, 1, 0],
	[0, 0, 0, 1, 0, 0, 0]];


	public function dilate(se : Array<Array<UInt>>)
	{
		var buffer2: UInt8Array = new UInt8Array(buffer);

		var se_end: Int = Math.floor(se.length/2);
		for(x in 0...width)
			for(y in 0...height)
			{
				if(buffer.__get(x+y*width) != 0)
				{
					for(xs in -se_end...se_end)
						for(ys in -se_end...se_end)
						{
							if(se[se_end+xs][se_end+ys] == 1 && x+xs>=0 && x+xs<width && y+ys>=0 && y+ys<height)
							{
								buffer2.__set(x+xs+(y+ys)*width, 255);
							}
						}
				}
			}
		buffer = buffer2;
	}

	public function erode(se : Array<Array<UInt>>)
	{
		var buffer2: UInt8Array = new UInt8Array(buffer);

		var se_end: Int = Math.floor(se.length/2);
		for(x in 0...width)
			for(y in 0...height)
			{
				if(buffer.__get(x+y*width) == 0)
				{
					for(xs in -se_end...se_end)
						for(ys in -se_end...se_end)
						{
							if(se[se_end+xs][se_end+ys] == 1 && x+xs>=0 && x+xs<width && y+ys>=0 && y+ys<height)
							{
								buffer2.__set(x+xs+(y+ys)*width, 0);
							}
						}
				}
			}

		buffer = buffer2;
	}
}