package alive_scripts;

import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.display.Bitmap;

import layers.AliveLayer;

class DancingCircle extends AliveScriptBase
{

	var waiting: Bool;

	var rotation: Float;

	var amplitude: Float = 5; //pixels
	var frameStep: Float = 0.01; //inverse of speed?

	public override function new(waitingForPlayer: Bool)
	{
		waiting = waitingForPlayer;

		NUM = 3;
	}

	public override function nextMove(sprite: UnitBitmap): Point
	{
		if(!waiting)
		{
			rotation += 0.1;

			var dx = -amplitude*Math.sin(rotation);
			var dy = amplitude*Math.cos(rotation);

			return new Point(dx, dy);

			//sprite.rotation = rotation;
		}
		else{

			var r1: Rectangle = sprite.im.getBounds(Main.targetCoordinateSpace);
			var r2: Rectangle = PlayerControl.playerSprite.getBounds(Main.targetCoordinateSpace);

			var ri: Rectangle = r1.intersection(r2);

			if(!ri.isEmpty())
			{

				var contacts : Int = 0;
				if(layers.PhysicsLayer.checkContactWithMask(sprite.im, layers.PhysicsLayer.moving_pmask, layers.PhysicsLayer.frameCode, 2, 2, 0, 0))
					contacts++;
				if(layers.PhysicsLayer.checkContactWithMask(sprite.im, layers.PhysicsLayer.moving_pmask, layers.PhysicsLayer.frameCode, 2, 2, 0, 1))
					contacts++;
				if(layers.PhysicsLayer.checkContactWithMask(sprite.im, layers.PhysicsLayer.moving_pmask, layers.PhysicsLayer.frameCode, 2, 2, 1, 0))
					contacts++;
				if(layers.PhysicsLayer.checkContactWithMask(sprite.im, layers.PhysicsLayer.moving_pmask, layers.PhysicsLayer.frameCode, 2, 2, 1, 1))
					contacts++;
				if(contacts >= 2)
				{
					Sys.println("merge units");
				}
			}

		}
		return new Point(0,0);
	}
}