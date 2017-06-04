package layers;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.DisplayObject;

import openfl.geom.Rectangle;
import openfl.geom.Point;

import lime.math.color.ARGB;

class TipsLayer extends Sprite
{
	public static inline var MASK_DOWNSAMPLING_FACTOR = 1;

	public var act_tips : Array<Bitmap> = new Array<Bitmap>();
	public var area_tips : Array<Bitmap> = new Array<Bitmap>();
	public var inplaces_bmp : Array<Bitmap> = new Array<Bitmap>();
	public var inplaces_rect : Array<Rectangle> = new Array<Rectangle>();
	public var inplaces_delay : Array<Float> = new Array<Float>();

	public function new () {
		super();
	}

	public function pushTip(bmp: Bitmap)
	{
		switch(bmp.name)
		{
			case "act-tip":
			act_tips.push(bmp);
			case "area-tip":
			area_tips.push(bmp);
		}
	}

	public function pushInplace(rect: Rectangle, delay:Float)
	{
		var bmp = new Bitmap(layers.RandomPaperSample.getRegion(Math.round(rect.width), Math.round(rect.height)));
		bmp.x = rect.left; bmp.y = rect.top;
		inplaces_bmp.push(bmp);
		rect.left -= INPLACE_AREA_EXTEND_BORDERS;
		rect.top -= INPLACE_AREA_EXTEND_BORDERS;
		rect.right += INPLACE_AREA_EXTEND_BORDERS;
		rect.bottom += INPLACE_AREA_EXTEND_BORDERS;
		inplaces_rect.push(rect);
		inplaces_delay.push(delay);
		addChild(bmp);
	}

	public function offsetUnits(dx: Float, dy: Float)
	{
		for(unit in act_tips)
		{
			unit.x+=dx;
			unit.y+=dy;
		}

		for(unit in area_tips)
		{
			unit.x+=dx;
			unit.y+=dy;
		}

		for(unit in inplaces_bmp)
		{
			unit.x+=dx;
			unit.y+=dy;
		}
	}

	var shown_act_tip_index = -1;
	var lastActTime: Float = Sys.time();
	var animate = false;
	var animate_index: Int = 0;
	public function registerAct()
	{
		lastActTime = Sys.time();
		if(shown_act_tip_index >= 0 && shown_act_tip_index < act_tips.length)
		{
			removeChild(act_tips[shown_act_tip_index]);
			animate = false;
		}

		//Sys.println("act tips status : index = "+(shown_act_tip_index+1)+" of "+act_tips.length);
	}

	public static inline var SHAKE_AMPLITUDE = 4;
	public static inline var INPLACE_AREA_EXTEND_BORDERS = 50;
	public static inline var ACT_TIP_DELAY = 5;
	public function tryTriggerTips(targetCoordinateSpace:DisplayObject, sprite: Bitmap, decorSprite: Bitmap)
	{

		//act tips
		if(Sys.time() > lastActTime + ACT_TIP_DELAY && act_tips.length > 0)
		{
			shown_act_tip_index++;
			if(shown_act_tip_index >= act_tips.length) //loop on the tips, to insist on acting
				shown_act_tip_index = 0;
			addChild(act_tips[shown_act_tip_index]);
			animate = true;
		}

		//transform player position to coords on decor
		var rm: Rectangle = sprite.getBounds(targetCoordinateSpace);
		var pt: Point = new Point(rm.x + rm.width/2, rm.y + rm.height/2);
		pt = decorSprite.globalToLocal(pt);
		

		//inplace tips
		var i: Int = inplaces_rect.length-1;
		while(i >= 0)
		{
			if(inplaces_rect[i].containsPoint(pt) || Sys.time() > lastActTime + inplaces_delay[i])
			{
				removeChild(inplaces_bmp[i]);
				inplaces_rect.remove(inplaces_rect[i]);
				inplaces_bmp.remove(inplaces_bmp[i]);
				inplaces_delay.remove(inplaces_delay[i]);
			}
			i--;
		}


		if(animate)
		{
			var dx: Float = 0;
			var dy: Float = 0;
			switch(animate_index)
			{
				case 0:
				dy = -SHAKE_AMPLITUDE;
				case 1:
				dx = SHAKE_AMPLITUDE;
				case 2:
				dy = SHAKE_AMPLITUDE;
				case 3:
				dx = -SHAKE_AMPLITUDE;
			}

			act_tips[shown_act_tip_index].x += dx;
			act_tips[shown_act_tip_index].y += dy;

			animate_index++;
			if(animate_index >= 4)
				animate_index = 0;
		}
	}
}