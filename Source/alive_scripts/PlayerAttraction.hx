
package alive_scripts;

import openfl.geom.Point;
import openfl.display.Bitmap;

import layers.AliveLayer;

class PlayerAttraction extends AliveScriptBase
{

	var targetSprite: Bitmap;

	public override function new(spriet:Bitmap)
	{
		targetSprite = spriet;
		NUM = 2;
	}

	static inline var BASE_SPEED = 5;

	public override function nextMove(sprite: UnitBitmap): Point
	{
		var pm: Point = new Point(0,0);

		targetSprite = PlayerControl.playerSprite;

		var tmp : Float = (targetSprite.x + targetSprite.width/2) - (sprite.im.x + sprite.im.width/2);
		if(tmp > 0)
		{
			pm.x = Math.min(tmp, BASE_SPEED);
		}
		else
		{
			pm.x = Math.max(tmp, -BASE_SPEED);
		}

		tmp = (targetSprite.y + targetSprite.height/2) - (sprite.im.y + sprite.im.height/2);
		if(tmp > 0)
		{
			pm.y = Math.min(tmp, BASE_SPEED);
		}
		else
		{
			pm.y = Math.max(tmp, -BASE_SPEED);
		}

		return pm;
	}
}