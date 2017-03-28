package alive_scripts;

import openfl.geom.Point;
import openfl.display.Bitmap;

class RandomSpeed extends AliveScriptBase
{

	private var vx: Float;
	private var vy: Float;

	private static inline var AMPLITUDE = 5;

	public override function new()
	{
		vx = AMPLITUDE*(Math.random()-0.5);
		vy = AMPLITUDE*(Math.random()-0.5);

		NUM = 1;
	}

	public override function nextMove(sprite: Bitmap): Point
	{
		vx += AMPLITUDE*(Math.random()-0.5)/20;
		vy += AMPLITUDE*(Math.random()-0.5)/20;
		return new Point(vx,vy);
	}
}