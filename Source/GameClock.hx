enum GameStatus
{
	StartScreen;
	Intro;
	MainGame;
	Menu;
	GameOver;
}

class GameClock {
	public static var phase: GameStatus = StartScreen;

	public static var actTime: Float = 0;
	static var lastActiveFrameTime : Float = 0;

	public static inline var ALIVE_TIME:Float = 260;

	public static function updateActiveTime() : Bool
	{
		var dt = Sys.time()-lastActiveFrameTime;
		if(dt<0.25) //skip bit time jumps, as they should be due to game pausing
			actTime+=dt;
		lastActiveFrameTime = Sys.time();
		if(actTime > ALIVE_TIME)
			return true;
		return false;
	}
}