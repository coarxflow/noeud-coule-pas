import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import layers.PhysicsLayer;
import layers.DeformationLayer;
import layers.InsertDecorRegion;
import layers.ConsumableLayer;

enum PlayerLeaveSide {
	Left; Right; Top; Bottom;
} 

typedef TargetRush =
{
	var start: Point;
	var target: Point;
	var progress: Float;
	var dirX: Float;
	var dirY: Float;
	var total: Float;
}

class PlayerControl
{
	public static var mainScene: Main;

	public static var playerSprite: Bitmap;
	public static var aliveUnitId: Int;
	public static var deformLayer: DeformationLayer;

	public static var rushing: Bool = false;
	public static var rushInfo: TargetRush;

	public static var consume: Bool = false;
	public static var consumeEndTime: Float = 0;
	public static var consumedObject: layers.ConsumableLayer.UnitBitmap;
	
	public static var paint: Bool = false;
	public static var paintEndTime: Float = 0;

	public static var sceneRebelAction: Main.RebelAction = Closed;

	public static var enablePhysics: Bool = true;
	public static var sceneGravity: Bool = false;

	/***** settings variables *****/
	public static var REGULAR_SPEED:Int = 10;
	public static var RUSH_SPEED:Int = 20;
	public static var RUSH_DISTANCE:Float = 70;

	public static var CONSUME_DURATION: Float = 1;
	public static var PAINT_DURATION: Float = 0.4;

	public static var ENTER_DISTANCE:Int = 50;

	public static var GRAVITY_ACCELERATION: Float = 10;
	
	public static function playerAct(targetCoordinateSpace: DisplayObject)
	{
		var new_pos: Bool = false;
		var check_collision: Bool = true;
		var dx: Float = 0;
		var dy: Float = 0;

		//cross action
		if(rushing)
		{
			dx = rushInfo.dirX;
			dy = rushInfo.dirY;
			new_pos = true;
			check_collision = false;
			rushInfo.progress += Math.abs(rushInfo.dirX)+Math.abs(rushInfo.dirY);
			Sys.println("rush "+rushInfo.progress+"/"+rushInfo.total);
			if(rushInfo.progress >= rushInfo.total)
			{
				rushing = false;
				if(consume)
				{
					if(!consumedObject.persistent)
						paintAround(PAINT_BLANK);
					mainScene.consumableLayer.consumeUnit(consumedObject);
				}
			}
		}
		if (consume)
		{
			new_pos = true;check_collision = false; //lock movement
			consume = Sys.time() < consumeEndTime;
			var sc: Float = 1.5 - Math.abs(Sys.time() - consumeEndTime + CONSUME_DURATION/2)/CONSUME_DURATION;
			playerSprite.scaleX = sc;
			playerSprite.scaleY = sc;
		}
		if (paint)
		{
			paint = Sys.time() <  paintEndTime;
			paintAround(PAINT_GREENISH);
		}

		//normal move
		if(!new_pos) {
			if (KeyboardInputs.arrowKeyUp) {
				dy -= REGULAR_SPEED;
				new_pos = true;
			}
			if (KeyboardInputs.arrowKeyDown) {
				dy += REGULAR_SPEED;
				new_pos = true;
			}
			if (KeyboardInputs.arrowKeyLeft) {
				dx -= REGULAR_SPEED;
				new_pos = true;
			}
			if (KeyboardInputs.arrowKeyRight) {
				dx += REGULAR_SPEED;
				new_pos = true;
			}
			if(sceneGravity && enablePhysics)
			{
				dy += GRAVITY_ACCELERATION;
				new_pos = true;
			}
		}
		
		if(new_pos)
		{
			if(check_collision && enablePhysics)
				AliveLayer.moveSprite(playerSprite, Math.round(dx), Math.round(dy), targetCoordinateSpace);
			else{
				playerSprite.x+=dx;
				playerSprite.y+=dy;
			}

			var entryPoint: Point = new Point(playerSprite.x,playerSprite.y);

			if(playerSprite.x < mainScene.sceneLeft)
			{
				if(mainScene.changeScene(PlayerLeaveSide.Left, entryPoint))
				{
					playerSprite.x = entryPoint.x - playerSprite.width - ENTER_DISTANCE;
					playerSprite.y = entryPoint.y;
				}
			}
			else if (playerSprite.x + playerSprite.width > mainScene.sceneRight)
			{
				if(mainScene.changeScene(PlayerLeaveSide.Right, entryPoint))
				{
					playerSprite.x = entryPoint.x + ENTER_DISTANCE;
					playerSprite.y = entryPoint.y;
				}
			}
			else if(playerSprite.y < mainScene.sceneTop)
			{
				if(mainScene.changeScene(PlayerLeaveSide.Top, entryPoint))
				{
					playerSprite.x = entryPoint.x;
					playerSprite.y = entryPoint.y - playerSprite.height - ENTER_DISTANCE;
				}
			}
			else if (playerSprite.y + playerSprite.height > mainScene.sceneBottom)
			{
				if(mainScene.changeScene(PlayerLeaveSide.Bottom, entryPoint))
				{
					Sys.println("bounds "+entryPoint);
					playerSprite.x = entryPoint.x;
					playerSprite.y = entryPoint.y + ENTER_DISTANCE;
				}
			}

		}


		PhysicsLayer.registerMovingElement(targetCoordinateSpace, playerSprite);

		//Sys.println("player "+playerSprite.x+" "+playerSprite.y);
	}

	public static function triggerRush()
	{
		Sys.println("rush start ");
		rushInfo = {start: new Point(playerSprite.x, playerSprite.y), target: new Point(playerSprite.x, playerSprite.y), progress : 0, total : 0, dirX : 0, dirY : 0};
		rushing = false;
		if (KeyboardInputs.arrowKeyUp) {
			rushInfo.dirY -= RUSH_SPEED;
			rushInfo.target.y -= RUSH_DISTANCE;
			rushing = true;
		}
		if (KeyboardInputs.arrowKeyDown) {
			rushInfo.dirY += RUSH_SPEED;
			rushInfo.target.y += RUSH_DISTANCE;
			rushing = true;
		}
		if (KeyboardInputs.arrowKeyLeft) {
			rushInfo.dirX -= RUSH_SPEED;
			rushInfo.target.x -= RUSH_DISTANCE;
			rushing = true;
		}
		if (KeyboardInputs.arrowKeyRight) {
			rushInfo.dirX += RUSH_SPEED;
			rushInfo.target.x += RUSH_DISTANCE;
			rushing = true;
		}
		rushInfo.total = Math.abs(rushInfo.target.x - rushInfo.start.x) + Math.abs(rushInfo.target.y - rushInfo.start.y);
	

		if(rushing)
			deformLayer.addPineDef(playerSprite,Math.atan2(rushInfo.dirY,rushInfo.dirX),RUSH_DISTANCE);
	}

	public static function triggerConsume()
	{
		consumedObject = mainScene.consumableLayer.findClosest(playerSprite.x, playerSprite.y, 1000);

		Sys.println("consume "+consumedObject);

		if(consumedObject == null)
			return;

		var target: Point = new Point(consumedObject.im.x /*+ consumedObject.im.width/2 - playerSprite.width/2*/, consumedObject.im.y /*+ consumedObject.im.height/2 - playerSprite.height/2*/);

		rushInfo = {start: new Point(playerSprite.x, playerSprite.y), target: target, progress : 0, total : 0, dirX : 0, dirY : 0};
		
		rushInfo.dirX = (rushInfo.target.x - rushInfo.start.x)/CONSUME_DURATION/mainScene.fps.currentFPS*2;
		rushInfo.dirY = (rushInfo.target.y - rushInfo.start.y)/CONSUME_DURATION/mainScene.fps.currentFPS*2;

		rushInfo.total = Math.abs(rushInfo.target.x - rushInfo.start.x) + Math.abs(rushInfo.target.y - rushInfo.start.y);

		rushing = true;

		consumeEndTime = Sys.time() + CONSUME_DURATION;

		consume = true;
	}

	public static function triggerPaint()
	{
		paintEndTime = Sys.time() + PAINT_DURATION;
		paint = true;
	}

	static inline var PAINT_RADIUS : Int = 15;
	static inline var PAINT_BLANK : Int = 0xFFFEEFFE;
	static inline var PAINT_GREENISH : Int = 0xFF118888;
	static inline var PAINT_RADIUS_SQ : Int = 225;
	static function paintAround(paint_color: Int)
	{
    	var rm: Rectangle = playerSprite.getBounds(Main.targetCoordinateSpace);


		var bmp: BitmapData = new BitmapData(2*PAINT_RADIUS, 2*PAINT_RADIUS);
		for(x in -PAINT_RADIUS...PAINT_RADIUS)
			for(y in -PAINT_RADIUS...PAINT_RADIUS)
			{
				if(Math.pow(x,2)+Math.pow(y,2)<=PAINT_RADIUS_SQ)
					bmp.setPixel32(PAINT_RADIUS+x, PAINT_RADIUS+y, paint_color);
				else
					bmp.setPixel32(PAINT_RADIUS+x, PAINT_RADIUS+y, 0x0);
			}

		var idr: InsertDecorRegion = new InsertDecorRegion(new Rectangle(rm.x+rm.width/2-PAINT_RADIUS, rm.y+rm.height/2-PAINT_RADIUS, 2*PAINT_RADIUS, 2*PAINT_RADIUS), deformLayer.decorSprite, layers.PhysicsLayer.static_pmask, bmp);
		layers.AnimationLayer.pushRegion(idr);
	}

}