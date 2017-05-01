package layers;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Point;

import openfl.Assets;

class AnimationLayer {

	static var applylist : Array<AnimatedRegion> = new Array<AnimatedRegion>();

	public static var main: Main;

	public static function frameApplyAll()
	{
		for(idr in applylist)
			idr.insertStep();

		var idx : Int = applylist.length-1;
		while(idx >= 0)
		{
			if(applylist[idx].complete)
			{
				if(applylist[idx].add_to_scene)
					main.removeChild(applylist[idx].sprite);
				applylist.remove(applylist[idx]);
			}
			idx--;
		}
	}

	public static function clearList()
	{
		var idx : Int = applylist.length-1;
		while(idx >= 0)
		{
			if(applylist[idx].add_to_scene)
				main.removeChild(applylist[idx].sprite);
			applylist.remove(applylist[idx]);
			idx--;
		}
	}

	public static function pushRegion(idr: AnimatedRegion)
	{
		applylist.push(idr);
		if(idr.add_to_scene)
			main.addChild(idr.sprite);
	}

	public static function extractAnimFromFile(path: String, insert_region: Rectangle, reg_w: Int, reg_h: Int, nlines: Array<Int>) : Array<BitmapData>
	{
		var raw_bitmap = Assets.getBitmapData(path);
		var im_stack: Array<BitmapData> = new Array<BitmapData>();
		var bmp: BitmapData;
		for(i in 0...nlines.length)
		{
			if(nlines[i]>0)
			{
				for(j in 0...nlines[i])
				{
					bmp = new BitmapData(reg_w, reg_h);
					bmp.copyPixels(raw_bitmap, new Rectangle(j*reg_w,i*reg_h,reg_w,reg_h), new Point(0,0));
					im_stack.push(bmp);
				}
			}
		}

		return im_stack;
	}
	
}