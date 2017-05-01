package reaction_scripts;

import openfl.geom.Point;
import openfl.display.Bitmap;

import layers.AliveLayer;

class EnterDialog extends ReactionScriptBase {

	public function new()
	{

	}

	var last_calling_scene = "";

	public override function trigger(sprite: Bitmap, id: Int)
	{
		if(id == PlayerControl.aliveUnitId)
		{
			if(layers.PhysicsLayer.moving_collisions.get(PlayerControl.aliveUnitId) != null)
			{
				Sys.println("enter dialog script triggered");
				/*var ub: UnitBitmap = PlayerControl.mainScene.aliveLayer.findClosestUnit(PlayerControl.aliveUnitId);
				if(ub != null)
				{*/
					if(WorldScenes.instance.current_scene.source != last_calling_scene)
					{
						last_calling_scene = WorldScenes.instance.current_scene.source;
						PlayerControl.mainScene.nextScreen("dialog");
					}
				//}

			}
		}
	}
}