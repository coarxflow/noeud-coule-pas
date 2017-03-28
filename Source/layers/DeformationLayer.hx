package layers;

import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;

typedef WarpPine =
{
	trunk_base: Point,
	trunk_summit: Point,
	angle: Float,
	height: Float,
	base_width: Float,
	summit_width: Float,
	border_thick: Float
}

class DeformationLayer {

	var pines : Array<WarpPine> = new Array<WarpPine>();

	public var decorSprite: Bitmap;

	public function new()
	{

	}

	function inInfluenceDomain(pine: WarpPine, x: Float, y: Float): Bool
	{
		var d: Float = Math.abs((pine.trunk_summit.y-pine.trunk_base.y)*x - (pine.trunk_summit.x-pine.trunk_base.x)*y + pine.trunk_summit.x*pine.trunk_base.y - pine.trunk_summit.y*pine.trunk_base.x) / Math.sqrt(Math.pow(pine.trunk_summit.y-pine.trunk_base.y,2) + Math.pow(pine.trunk_summit.x-pine.trunk_base.x,2));

		var a: Float = Math.atan2(y-pine.trunk_base.y, x-pine.trunk_base.x);

		var proj : Float = ((x-pine.trunk_base.x)*(pine.trunk_summit.x-pine.trunk_base.x) + (y-pine.trunk_base.y)*(pine.trunk_summit.y-pine.trunk_base.y)) / Math.sqrt(Math.pow(pine.trunk_summit.y-pine.trunk_base.y,2) + Math.pow(pine.trunk_summit.x-pine.trunk_base.x,2));

		if(proj >= 0 && proj <= pine.height)
		{
			var max_d : Float = pine.base_width*(1-proj/pine.height) + pine.summit_width*(proj/pine.height);
			if(d < max_d)
			{
				return true;
			}
		}

		return false;
	}
	
	public function deformPoint(x: Float, y: Float, pine: WarpPine) : Point
	{
		var proj : Float = ((x-pine.trunk_base.x)*(pine.trunk_summit.x-pine.trunk_base.x) + (y-pine.trunk_base.y)*(pine.trunk_summit.y-pine.trunk_base.y)) / Math.sqrt(Math.pow(pine.trunk_summit.y-pine.trunk_base.y,2) + Math.pow(pine.trunk_summit.x-pine.trunk_base.x,2));

		var max_d : Float = pine.base_width*(1-proj/pine.height) + pine.summit_width*(proj/pine.height);

		var d: Float = Math.abs((pine.trunk_summit.y-pine.trunk_base.y)*x - (pine.trunk_summit.x-pine.trunk_base.x)*y + pine.trunk_summit.x*pine.trunk_base.y - pine.trunk_summit.y*pine.trunk_base.x) / Math.sqrt(Math.pow(pine.trunk_summit.y-pine.trunk_base.y,2) + Math.pow(pine.trunk_summit.x-pine.trunk_base.x,2));

		var fd: Float = d/max_d;
		var def_d: Float = max_d - (1-fd)*pine.border_thick;
		
		var pt : Point = new Point(x,y);
		pt.x += def_d * Math.sin(pine.angle);
		pt.y += def_d * Math.cos(pine.angle);

		return pt;
	}

	public function addPineDef(movingSprite: Bitmap, angle: Float, dist: Float)
	{
		var rm: Rectangle = movingSprite.getBounds(Main.targetCoordinateSpace);

		var base : Point = new Point(rm.x+rm.width/2,rm.y+rm.height/2);
		var summit: Point = new Point(base.x + dist * Math.cos(angle), base.y + dist * Math.sin(angle));
		var pine : WarpPine = {trunk_base: base, trunk_summit: summit, angle: angle, height: dist,
			base_width: 70, summit_width: 60, border_thick: 20};

		pines.push(pine);


		var idr: InsertDecorRegion = deformRegion(pine, decorSprite.bitmapData, decorSprite);
		AnimationLayer.pushRegion(idr);

	}

	private function deformRegion(pine : WarpPine, image : BitmapData, decorSprite: Bitmap)
	{
		var cos_proj = (pine.trunk_summit.x-pine.trunk_base.x) / Math.sqrt(Math.pow(pine.trunk_summit.y-pine.trunk_base.y,2) + Math.pow(pine.trunk_summit.x-pine.trunk_base.x,2));
		var sin_proj = (pine.trunk_summit.y-pine.trunk_base.y) / Math.sqrt(Math.pow(pine.trunk_summit.y-pine.trunk_base.y,2) + Math.pow(pine.trunk_summit.x-pine.trunk_base.x,2));
		//find enclosing region
		var pt1 = pine.trunk_base.clone();
		pt1.x -= sin_proj*pine.base_width/2;
		pt1.y += cos_proj*pine.base_width/2;
		var pt2 = pine.trunk_base.clone();
		pt2.x += sin_proj*pine.base_width/2;
		pt2.y -= cos_proj*pine.base_width/2;
		var pt3 = pine.trunk_summit.clone();
		pt3.x -= sin_proj*pine.summit_width/2;
		pt3.y += cos_proj*pine.summit_width/2;
		var pt4 = pine.trunk_summit.clone();
		pt4.x += sin_proj*pine.summit_width/2;
		pt4.y -= cos_proj*pine.summit_width/2;

		var enclosing : Rectangle = new Rectangle(0,0,0,0);
		enclosing.x = Math.min(pt1.x, Math.min(pt2.x, Math.min(pt3.x, pt4.x)));
		enclosing.width = Math.max(pt1.x, Math.max(pt2.x, Math.max(pt3.x, pt4.x))) - enclosing.x;
		enclosing.y = Math.min(pt1.y, Math.min(pt2.y, Math.min(pt3.y, pt4.y)));
		enclosing.height = Math.max(pt1.y, Math.max(pt2.y, Math.max(pt3.y, pt4.y))) - enclosing.y;

		Sys.println("enclosing = "+enclosing);

		var xb: Int = Math.floor(enclosing.x);
		var yb: Int = Math.floor(enclosing.y);
		var xe: Int = Math.ceil(enclosing.x+enclosing.width);
		var ye: Int = Math.ceil(enclosing.y+enclosing.height);

		var pt: Point = new Point(0,0); //sampling point

		var newBMP : BitmapData = new BitmapData(Math.ceil(enclosing.width), Math.ceil(enclosing.height));

		var proj : Float ;
		var max_d : Float;
		var def_d : Float;
		var fb: Float;
		var d : Float;
		var side : Float;
		var sweep : Float;
		for (x in xb ... xe) {
			for (y in yb ...ye) {
				proj = ((x-pine.trunk_base.x)*(pine.trunk_summit.x-pine.trunk_base.x) + (y-pine.trunk_base.y)*(pine.trunk_summit.y-pine.trunk_base.y)) / Math.sqrt(Math.pow(pine.trunk_summit.y-pine.trunk_base.y,2) + Math.pow(pine.trunk_summit.x-pine.trunk_base.x,2));
				//Sys.println("proj = "+proj);
				max_d = pine.base_width*(1-proj/pine.height)/2 + pine.summit_width*(proj/pine.height)/2;
				//Sys.println("max_d = "+max_d);
				def_d = Math.abs((pine.trunk_summit.y-pine.trunk_base.y)*x - (pine.trunk_summit.x-pine.trunk_base.x)*y + pine.trunk_summit.x*pine.trunk_base.y - pine.trunk_summit.y*pine.trunk_base.x) / Math.sqrt(Math.pow(pine.trunk_summit.y-pine.trunk_base.y,2) + Math.pow(pine.trunk_summit.x-pine.trunk_base.x,2));
				//Sys.println("def_d = "+def_d);
				fb = (def_d-max_d+pine.border_thick)/pine.border_thick;
				d = max_d*fb;
				//Sys.println("d = "+d);
				if(d >= max_d)
				{
					pt.x = x;
					pt.y = y;
					pt=decorSprite.globalToLocal(pt);
					newBMP.setPixel(x-xb, y-yb, image.getPixel(Math.round(pt.x), Math.round(pt.y)));
				}
				else if(d > 0)
				{
					side = (pine.trunk_summit.x - pine.trunk_base.x) * (y - pine.trunk_base.y) - (pine.trunk_summit.y - pine.trunk_base.y) * (x - pine.trunk_base.x);
					if(side > 0)
						side = 1;
					else
						side = -1;
					sweep = proj / pine.height;
					//sweep = Math.pow(proj / pine.height, 2-Math.pow(fb,0.1)); //introduce warp
					pt.x = pine.trunk_base.x + sweep*(pine.trunk_summit.x - pine.trunk_base.x) - side*d*sin_proj;
					pt.y = pine.trunk_base.y + sweep*(pine.trunk_summit.y - pine.trunk_base.y) + side*d*cos_proj;
					//pt.x = x;
					//pt.y = y;
					pt = decorSprite.globalToLocal(pt);
					newBMP.setPixel(x-xb, y-yb, image.getPixel(Math.round(pt.x), Math.round(pt.y)));
					//newBMP.setPixel(x-xb, y-yb, 0xFF0000);
				}
				else
				{
					newBMP.setPixel(x-xb, y-yb, RandomPaperSample.getPixel(x,y));
				}

			}
		}

		var idr: InsertDecorRegion = new InsertDecorRegion(enclosing, decorSprite, layers.PhysicsLayer.static_pmask, newBMP);

		/*pt.x = enclosing.x; pt.y = enclosing.y;
		pt=decorSprite.globalToLocal(pt);
		image.copyPixels(newBMP, new Rectangle(0,0,newBMP.width,newBMP.height), pt);*/

		return idr;

	}

	public function deformImage(image : BitmapData, decorSprite: Bitmap) : Void
	{
		for(pine in pines)
			deformRegion(pine, image, decorSprite);
	}

}