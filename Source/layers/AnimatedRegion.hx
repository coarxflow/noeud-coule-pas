package layers;

import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;

import lime.math.color.ARGB;

class AnimatedRegion {
	public var region: Rectangle;

	public var complete: Bool = false;

	public var add_to_scene : Bool = false;

	public var sprite: Bitmap;

	public function new(region: Rectangle) {
		this.region = region;
	}

	public function insertStep() {
		
	}

	public function offset(dx: Int, dy: Int) {
		if(sprite != null)
		{
			sprite.x += dx;
			sprite.y += dy;
		}
	}
}