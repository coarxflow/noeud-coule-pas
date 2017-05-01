package screen_scripts;


class RaceTrackInit extends ScreenScriptBase {

	public function new()
	{

	}

	public override function screenAwake()
	{
		if(reaction_scripts.RunningTrack.runner == null)
		{
			if(PlayerControl.mainScene.aliveLayer.units[0].id != 2)
				return;
			reaction_scripts.RunningTrack.runner = PlayerControl.mainScene.aliveLayer.units[0]; //get the only alive sprite, hopefully
			reaction_scripts.RunningTrack.runner.im.alpha = 0;
			Sys.println("runner init "+reaction_scripts.RunningTrack.runner);
		}
	}
	public override function runStep()
	{

	}

	public override function screenSleep()
	{
	}

}