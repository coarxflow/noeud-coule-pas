package alive_scripts;

import openfl.geom.Point;
import openfl.display.Bitmap;

import layers.AliveLayer;

class AliveScriptBase
{
	public var NUM: Int = -1;

	public function nextMove(sprite: UnitBitmap): Point
	{
		return new Point(0,0);
	}
}