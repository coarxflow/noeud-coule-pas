package layers;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.geom.Rectangle;
import openfl.geom.Point;

import lime.math.color.ARGB;

typedef CollisionResult = {
	@:optional var chk_rect: Rectangle;
	var left_in: Int;
	var right_in: Int;
	var top_in: Int;
	var bottom_in: Int;
}


class PhysicsLayer {

	public static inline var MASK_DOWNSAMPLING_FACTOR = 4;

	public static var NO_COLLISION: Int = 1000;

	public static var static_pmask: LogicMask;
	public static var moving_pmask: LogicMask;
	static var decorSprite: Bitmap;

	public static var frameCode: UInt = Math.round(Math.random()*255);

	public static var static_collisions: Map<Int, CollisionResult> = new Map<Int, CollisionResult> ();
	public static var moving_collisions: Map<Int, CollisionResult> = new Map<Int, CollisionResult> ();

	public static function updateStaticMask(pmask: LogicMask)
	{
		static_pmask = pmask;
	}

	public static function newFrameForMovingMask()
	{
		frameCode++;
		if(frameCode > 255)
		{
			frameCode = 2;
			moving_pmask.fill(0);
		}

		//reset collision dictionnaries
		static_collisions = new Map<Int, CollisionResult> ();
		moving_collisions = new Map<Int, CollisionResult> ();
	}

	public static function registerMovingElement(targetCoordinateSpace:DisplayObject, el: Bitmap)
	{
		var rm: Rectangle = el.getBounds(targetCoordinateSpace);
		var pt: Point = new Point(0,0);


		for (x in 0 ... el.bitmapData.width) {
			for (y in 0 ...el.bitmapData.height) {
				if(el.bitmapData.getPixel32(x,y)&0x000000FF>0) //canal alpha > 0
				{	
					pt.x=x; pt.y=y;
					pt=decorSprite.globalToLocal(el.localToGlobal(pt));
					moving_pmask.setXY(Math.round(pt.x), Math.round(pt.y), frameCode);
				}
			}
		}
	}

	public static function updateDecorSprite(sprite: Bitmap)
	{
		decorSprite = sprite;
		moving_pmask = new LogicMask(Math.floor(decorSprite.width), Math.floor(decorSprite.height), 1);
	}

	public static function checkForColision(targetCoordinateSpace:DisplayObject, movingSprite:Bitmap, aliveId: Int) : CollisionResult
	{
		var cr: CollisionResult = {left_in : 0, right_in : 0, top_in : 0, bottom_in : 0};
		var cr2: CollisionResult = {left_in : 0, right_in : 0, top_in : 0, bottom_in : 0};
		var cr3: CollisionResult = {left_in : 0, right_in : 0, top_in : 0, bottom_in : 0};

		if(checkCollisionWithMask(targetCoordinateSpace, movingSprite, static_pmask, 255, cr))
			static_collisions.set(aliveId, cr);
		if(checkCollisionWithMask(targetCoordinateSpace, movingSprite, moving_pmask, frameCode, cr2))
			moving_collisions.set(aliveId, cr2);
		
		//merge collision results
		cr3.left_in = Math.round(Math.max(cr2.left_in, cr.left_in));
		cr3.right_in = Math.round(Math.max(cr2.right_in, cr.right_in));
		cr3.top_in = Math.round(Math.max(cr2.top_in, cr.top_in));
		cr3.bottom_in = Math.round(Math.max(cr2.bottom_in, cr.bottom_in));

		return cr3;

	}


	static function checkCollisionWithMask(targetCoordinateSpace:DisplayObject, movingSprite:Bitmap, mask:LogicMask, chk_val:UInt, cr: CollisionResult) : Bool
	{

		var rm: Rectangle = movingSprite.getBounds(targetCoordinateSpace);
		var rs: Rectangle = decorSprite.getBounds(targetCoordinateSpace);

		var ri: Rectangle = rs.intersection(rm);

		var val1: UInt = 0;
		var col2: ARGB = ARGB.create(255,0,0,0);

		var collided: Bool = false;

		if(!ri.isEmpty())
		{

			var xb: Int = Math.floor(ri.x);
			var yb: Int = Math.floor(ri.y);
			var xe: Int = Math.ceil(ri.x+ri.width);
			var ye: Int = Math.ceil(ri.y+ri.height);

			var xm: Int;
			var ym: Int;

			var left_from_center: Int = NO_COLLISION;
			var right_from_center: Int = NO_COLLISION;
			var top_from_center: Int = NO_COLLISION;
			var bottom_from_center: Int = NO_COLLISION;

			var pt: Point = new Point(0,0);
			var r2min : Float = 100000;
			var r2 : Float = 0;

			for (x in xb ... xe) {
				for (y in yb ...ye) {
					pt.x=x; pt.y=y;
					pt=decorSprite.globalToLocal(pt);
					val1 = mask.getXY(Math.round(pt.x/mask.downsampling_factor), Math.round(pt.y/mask.downsampling_factor));
					pt.x=x; pt.y=y;
					pt=movingSprite.globalToLocal(pt);
					col2 = new ARGB(movingSprite.bitmapData.getPixel32(Math.round(pt.x), Math.round(pt.y)));
					if (val1 == chk_val && col2.a > 0)
					{
						//offset of collision point from center
						xm = Math.round(x - (rm.x + rm.width/2));
						ym = Math.round(y - (rm.y  + rm.height/2));
						r2 = Math.pow(xm,2) + Math.pow(ym,2);
						if(r2 < r2min)
						{
							r2min = r2;
							//pick closest
							if (xm < 0)
							{
								left_from_center = -xm;
							}
							else
							{
								right_from_center = xm;
							}
							if (ym < 0)
							{
								top_from_center = -ym;
							}
							else
							{
								bottom_from_center = ym;
							}
						}
					}
				}
			}


			//compute distance of closest colliding coords from border
			if(left_from_center != NO_COLLISION)
			{
				cr.left_in = Math.round(ri.width/2 - left_from_center);
				collided = true;
			}
			if(right_from_center != NO_COLLISION)
			{
				cr.right_in = Math.round(ri.width/2 - right_from_center);
				collided = true;
			}
			if(top_from_center != NO_COLLISION)
			{
				cr.top_in = Math.round(ri.height/2 - top_from_center);
				collided = true;
			}
			if(bottom_from_center != NO_COLLISION)
			{
				cr.bottom_in = Math.round(ri.height/2 - bottom_from_center);
				collided = true;
			}


		}

		cr.chk_rect = rm;

		return collided;
	}

//what is it??
	public static function checkContactWithMask(movingSprite :Bitmap, mask:LogicMask, chk_val:UInt, x_splits: Int, y_splits: Int, x_cell: Int, y_cell: Int) : Bool
	{

		var rm: Rectangle = movingSprite.getBounds(Main.targetCoordinateSpace);
		var rs: Rectangle = decorSprite.getBounds(Main.targetCoordinateSpace);

		var ri: Rectangle = rs.intersection(rm);

		var val1: UInt = 0;
		var col2: ARGB = ARGB.create(255,0,0,0);

		var contact : Bool = false;

		if(!ri.isEmpty())
		{

			var xb: Int = Math.floor(ri.x+x_cell*ri.width/x_splits);
			var yb: Int = Math.floor(ri.y+y_cell*ri.height/y_splits);
			var xe: Int = Math.ceil(ri.x+(x_cell+1)*ri.width/x_splits);
			var ye: Int = Math.ceil(ri.y+(y_cell+1)*ri.height/y_splits);

			var xm: Int;
			var ym: Int;

			var left_from_center: Int = NO_COLLISION;
			var right_from_center: Int = NO_COLLISION;
			var top_from_center: Int = NO_COLLISION;
			var bottom_from_center: Int = NO_COLLISION;

			var pt: Point = new Point(0,0);

			for (x in xb ... xe) {
				for (y in yb ...ye) {
					pt.x=x; pt.y=y;
					pt=decorSprite.globalToLocal(pt);
					val1 = mask.getXY(Math.round(pt.x/mask.downsampling_factor), Math.round(pt.y/mask.downsampling_factor));
					pt.x=x; pt.y=y;
					pt=movingSprite.globalToLocal(pt);
					col2 = new ARGB(movingSprite.bitmapData.getPixel32(Math.round(pt.x), Math.round(pt.y)));
					if (val1 == chk_val && col2.a > 0)
					{
						contact = true;
					}
				}
			}




		}

		return contact;
	}

	public static function closestColliderPoint(cr: CollisionResult) : Point
	{

		var pt = new Point(0,0);

		if(cr.left_in > cr.right_in)
			pt.x = cr.chk_rect.x+cr.left_in;
		else
			pt.x = cr.chk_rect.x+cr.chk_rect.width-cr.left_in;

		if(cr.top_in > cr.bottom_in)
			pt.y = cr.chk_rect.y+cr.top_in;
		else
			pt.y = cr.chk_rect.y+cr.chk_rect.height-cr.bottom_in;

		return pt;
	}

}