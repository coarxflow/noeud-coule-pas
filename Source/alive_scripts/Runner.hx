
package alive_scripts;

import openfl.geom.Point;
import openfl.display.Bitmap;

import layers.AliveLayer;
import layers.ConsumableLayer;

class Runner extends AliveScriptBase
{

	public override function new()
	{
		NUM = 9;
	}

	public static var BASE_SPEED = 1000;
	var nextGuide: layers.ConsumableLayer.UnitBitmap2;
	var rushInfo: PlayerControl.TargetRush;

	public var running: Bool = false;

	public var loop_points : Bool = true;
	public var return_first_point : Bool = false;


	public override function nextMove(sprite: UnitBitmap): Point
	{

		if(nextGuide == null || (rushInfo != null && rushInfo.progress >= rushInfo.total))
		{
			rushInfo = null;

			nextGuide = PlayerControl.mainScene.consumableLayer.findNextId(nextGuide);

			if(nextGuide == null && loop_points) // in case last is reach, loop around
			{
				nextGuide = PlayerControl.mainScene.consumableLayer.findNextId(nextGuide);
				if(!return_first_point)
				{
					var target = new Point(nextGuide.im.x, nextGuide.im.y);
					rushInfo = PlayerControl.setupRush(sprite.im, target,0); //immediate rush to target
					running = true;
					sprite.ignore_physics = true;
				}
			}
			
			if(nextGuide != null && rushInfo == null)
			{
				var target = new Point(nextGuide.im.x, nextGuide.im.y);
				rushInfo = PlayerControl.setupRush(sprite.im, target,0, BASE_SPEED);
				running = true;
				sprite.ignore_physics = true;
			}
		}
		
		//var pm = layers.AliveLayer.moveTowards2(sprite.im, nextGuide.im, BASE_SPEED);
		var pm: Point;
		if(rushInfo != null)
		{
			rushInfo.progress += Math.abs(rushInfo.dirX)+Math.abs(rushInfo.dirY);
			pm = new Point(rushInfo.dirX, rushInfo.dirY);
		}
		else
		{
			running = false;
			pm = new Point(0,0);
		}

		return pm;
	}
}