package layers;

import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.geom.Matrix;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import lime.math.color.ARGB;

class RotatingClock extends AnimatedRegion {

	var rotation: Float;

	public function new(region: Rectangle, decorSpriteRegion: BitmapData) {
		super(region);

		var bmp: BitmapData = SceneProcessor.filterColorBMP(decorSpriteRegion, SceneProcessor.lbluefilter);

		this.sprite = new Bitmap(bmp);
		this.sprite.x = region.left;
		this.sprite.y = region.top;

		this.add_to_scene = true;
	}

	public override function insertStep() {
		rotation -= 0.05;
		var m : Matrix = new Matrix(1,0,0,1,-this.sprite.width/2,-this.sprite.height/2);
		//var m : Matrix = this.sprite.transform.matrix.clone();
		//m.translate(-this.sprite.width/2, -this.sprite.height/2);
		m.rotate(rotation);
		m.translate(this.sprite.width/2, this.sprite.height/2);
		this.sprite.transform.matrix = m;
	}
}