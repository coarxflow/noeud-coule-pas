package reaction_scripts;

import openfl.geom.Point;
import openfl.display.Bitmap;

import layers.AliveLayer;

class RunningTrack extends ReactionScriptBase {

	public function new()
	{

	}

	var guide_runner: Bool = false;
	public static var runner: UnitBitmap = null;

	var target_runner: Bool = false;
	var runner_target_point: layers.ConsumableLayer.UnitBitmap2;

	public override function trigger(sprite: Bitmap, id: Int)
	{

		if(runner == null)
		{
			runner = PlayerControl.mainScene.aliveLayer.units[0]; //get the only alive sprite, hopefully
			//runner.im.alpha = 0;
		}


		if(id == PlayerControl.aliveUnitId)
		{
			if(!guide_runner) //launch a new runner
			{
				runner.im.alpha = 1;
				runner.sc = new alive_scripts.Runner();
				Sys.println("runner script added to id "+runner.id);
				guide_runner = true;
			}
			else if(!target_runner) //look for collision
			{
				var cr = layers.PhysicsLayer.moving_collisions.get(PlayerControl.aliveUnitId);
				if(cr != null)
				{
					var ub = PlayerControl.mainScene.aliveLayer.findUnitAt(layers.PhysicsLayer.closestColliderPoint(cr), PlayerControl.aliveUnitId);
					PlayerControl.mainScene.displayDevPoint(layers.PhysicsLayer.closestColliderPoint(cr), 0xFF00FF00);
					if(ub != null && runner.id == ub.id && !target_runner)
					{
						Sys.println("stop runner");
						runner.sc = new alive_scripts.Still();
						runner.ignore_physics = false;
						PlayerControl.mainScene.consumableLayer.flush();
						runner_target_point = PlayerControl.mainScene.consumableLayer.addInvisible(runner.im.x+runner.im.width/2,runner.im.y+runner.im.height/2,true);
						PlayerControl.sceneRebelAction = Main.RebelAction.Consult;
						target_runner = true;
					}
				}

			}

			if(runner_target_point != null)
			{
				runner_target_point.im.x = runner.im.x+runner.im.width/2;
				runner_target_point.im.y = runner.im.y+runner.im.height/2;
			}
		}
	}
}