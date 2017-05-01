package layers;

import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.geom.Matrix;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import lime.math.color.ARGB;

class RotatingClock extends AnimatedRegion {

	var rotation: Float;
	var initial_position: Point;

	public function new(region: Rectangle, decorSprite: Bitmap) {
		super(region);
		
		var bmp: BitmapData = SceneProcessor.extractColorBMP(decorSprite.bitmapData, SceneProcessor.lbluefilter, region);

		this.sprite = new Bitmap(bmp);
		this.sprite.x = region.left;
		this.sprite.y = region.top;

		initial_position = new Point(this.sprite.x, this.sprite.y);

		this.add_to_scene = true;
	}

	public override function insertStep() {
		rotation = GameClock.actTime/GameClock.ALIVE_TIME*360;
		this.sprite.rotation = rotation;
		//var m : Matrix = new Matrix(1,0,0,1,-this.sprite.width/2,-this.sprite.height/2);
		var m : Matrix = this.sprite.transform.matrix.clone();
		//Sys.println(m);
		//Sys.println(m.deltaTransformPoint(new Point(this.sprite.width/2, this.sprite.height/2)));
		//Sys.println(m.transformPoint(new Point(this.sprite.width/2, this.sprite.height/2)));
		var pt1 = new Point(this.sprite.width/2, this.sprite.height/2);
		var pt2 = m.deltaTransformPoint(pt1);
		pt2 = pt2.subtract(pt1);
		this.sprite.x = initial_position.x - pt2.x;
		this.sprite.y = initial_position.y - pt2.y;
		/*m.translate(-this.sprite.width/2, -this.sprite.height/2);
		m.rotate(rotation);
		m.translate(this.sprite.width/2, this.sprite.height/2);
		this.sprite.transform.matrix = m;*/

	}

	public override function offset(dx: Int, dy: Int) {
		initial_position.x += dx;
		initial_position.y += dy;
	}

}