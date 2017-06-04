package screen_scripts;


class HospitalReactToConsume extends ScreenScriptBase {

	var aliveLayer: layers.AliveLayer;

	public function new(alive_layer: layers.AliveLayer)
	{
		aliveLayer = alive_layer;
	}

	public override function screenAwake()
	{
		
	}

	var track_start_consume = false;
	var random_wander = false;
	var player_ub: layers.AliveLayer.UnitBitmap;
	var wander_timer: Int;
	static inline var WANDER_FRAMES: Int = 100;
	public override function runStep()
	{
		if(PlayerControl.consume != false && !track_start_consume)
			track_start_consume = true;

		if(track_start_consume && !PlayerControl.consume)
		{
			random_wander = true;
			track_start_consume = false;

			for(u in aliveLayer.units)
			{
				if(u.id == PlayerControl.aliveUnitId)
					player_ub = u;
			}

			player_ub.id = 0; //allow alive layer to move this sprite
			player_ub.sc = new alive_scripts.RandomSpeed(0.5);
			player_ub.im.bitmapData.colorTransform(new openfl.geom.Rectangle(0,0,player_ub.im.bitmapData.width, player_ub.im.bitmapData.height), new openfl.geom.ColorTransform(1,1,1,1,0,100,0,0));
			wander_timer = WANDER_FRAMES;
			Sys.println("start random wander");
		}

		if(random_wander)
		{
			if(wander_timer > 0)
				wander_timer--;
			else{
				player_ub.id = PlayerControl.aliveUnitId;
				player_ub.im.bitmapData.colorTransform(new openfl.geom.Rectangle(0,0,player_ub.im.bitmapData.width, player_ub.im.bitmapData.height), new openfl.geom.ColorTransform(1,1,1,1,0,-100,0,0));
				player_ub.sc = null;
				random_wander = false;
			}
		}
	}

	public override function screenSleep()
	{
	}

}