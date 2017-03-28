package alive_scripts;

import openfl.geom.Point;
import openfl.display.Bitmap;

class AliveScriptBase
{
	public var NUM: Int = -1;

	public function nextMove(sprite: Bitmap): Point
	{
		return new Point(0,0);
	}
}