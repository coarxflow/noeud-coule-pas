package alive_scripts;

import openfl.geom.Point;
import openfl.display.Bitmap;

import layers.AliveLayer;

class Still extends AliveScriptBase
{

	public override function new()
	{
		NUM = 0;
	}

	public override function nextMove(sprite: UnitBitmap): Point
	{
		return new Point(0,0);
	}
}