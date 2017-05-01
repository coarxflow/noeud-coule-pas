package reaction_scripts;

import openfl.geom.Point;
import openfl.display.Bitmap;

import layers.AliveLayer;

class DancingGround extends ReactionScriptBase {

	public function new()
	{

	}

	var waiting_group_id: Int = 3;

	var merged : Bool = false;
	

	public override function trigger(sprite: Bitmap, id: Int)
	{

		if(id == PlayerControl.aliveUnitId && !merged)
		{
			var cr = layers.PhysicsLayer.moving_collisions.get(PlayerControl.aliveUnitId);
			if(cr != null)
			{
				var collide_sides: Int = 0;
				var collide_unit_id: Int = 0;
				var pts: Array<Point> = new Array<Point> ();
				Sys.println("collision "+cr);
				pts.push(new Point(cr.chk_rect.x+cr.left_in, cr.chk_rect.y+cr.chk_rect.height/2));
				pts.push(new Point(cr.chk_rect.x+cr.chk_rect.width-cr.right_in, cr.chk_rect.y+cr.chk_rect.height/2));
				pts.push(new Point(cr.chk_rect.x+cr.chk_rect.width/2, cr.chk_rect.y+cr.top_in));
				pts.push(new Point(cr.chk_rect.x+cr.chk_rect.width/2, cr.chk_rect.y+cr.chk_rect.height-cr.bottom_in));
				var ub : UnitBitmap = null;
				for(pt in pts)
				{
					ub = PlayerControl.mainScene.aliveLayer.findUnitAt(pt,PlayerControl.aliveUnitId);
					//PlayerControl.mainScene.displayDevPoint(pt, 0xcc9999);
					if(ub != null)
					{
						if(collide_unit_id == 0)
							collide_unit_id = ub.id;
						if(ub.id == collide_unit_id)
							collide_sides++;
					}
				}

				Sys.println("collision "+cr);
				Sys.println("dancing ground, detected "+collide_sides+" collision sides with id "+collide_unit_id);

				if(collide_unit_id != 0 && cr.right_in > 0)
				{
					PlayerControl.mainScene.aliveLayer.mergeUnits(PlayerControl.aliveUnitId, collide_unit_id);
					PlayerControl.mainScene.aliveLayer.consumeUnit(collide_unit_id);
					merged = true;
				}
			}
		}
	}
}