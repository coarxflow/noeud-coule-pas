package alive_scripts;

import openfl.geom.Point;
import openfl.display.Bitmap;

import layers.AliveLayer;

class RandomSpeed extends AliveScriptBase
{

	private var vx: Float;
	private var vy: Float;

	private var AMPLITUDE: Float = 2;

	public override function new(amp: Float = 2)
	{
		AMPLITUDE = amp;
		vx = -AMPLITUDE*(Math.random()-0.5);
		vy = AMPLITUDE*(Math.random()-0.5);


		NUM = 1;
	}

	public override function nextMove(sprite: UnitBitmap): Point
	{
		vx += AMPLITUDE*(Math.random()-0.5)/20;
		vy += AMPLITUDE*(Math.random()-0.5)/20;
		Sys.println(Math.random()+" "+vx);
		return new Point(vx,vy);
	}
}