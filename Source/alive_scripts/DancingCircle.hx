package alive_scripts;

import openfl.geom.Point;
import openfl.display.Bitmap;

class DancingCircle extends AliveScriptBase
{

	var waiting: Bool;

	var rotation: Float;

	public override function new(waitingForPlayer: Bool)
	{
		waiting = waitingForPlayer;
	}

	public override function nextMove(sprite: Bitmap): Point
	{
		if(!waitingForPlayer)
		{
			rotation += 0.1;
			sprite.rotation = rotation;
		}
		else{

			var r1: Rectangle = sprite.getBounds(Main.targetCoordinateSpace);
			var r2: Rectangle = PlayerControl.playerSprite.getBounds(Main.targetCoordinateSpace);

			var ri: Rectangle = r1.intersection(r2);

			if(!ri.isEmpty())
			{

				var contacts : Int = 0;
				if(checkContactWithMask(sprite, layers.PhysicsLayer.moving_pmask, layers.PhysicsLayer.frameCode, 2, 2, 0, 0))
					contacts++;
				if(checkContactWithMask(sprite, layers.PhysicsLayer.moving_pmask, layers.PhysicsLayer.frameCode, 2, 2, 0, 1))
					contacts++;
				if(checkContactWithMask(sprite, layers.PhysicsLayer.moving_pmask, layers.PhysicsLayer.frameCode, 2, 2, 1, 0))
					contacts++;
				if(checkContactWithMask(sprite, layers.PhysicsLayer.moving_pmask, layers.PhysicsLayer.frameCode, 2, 2, 1, 1))
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