import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import layers.PhysicsLayer;
import layers.DeformationLayer;
import layers.InsertDecorRegion;
import layers.ConsumableLayer;
import layers.ScriptLayer;
import layers.AliveLayer;

import lime.math.color.ARGB;

enum PlayerLeaveSide {
	Left; Right; Top; Bottom; Inner;
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

	public static var born: Bool = false;
	public static var free_move: Bool = true;
	public static var canRebel: Bool = true;
	public static var acting: Bool = true;

	public static var rushing: Bool = false;
	public static var rushInfo: TargetRush;

	public static var consume: Bool = false;
	public static var consumeEndTime: Float = 0;
	public static var consumedObject: layers.ConsumableLayer.UnitBitmap2;
	
	public static var paint: Bool = false;
	public static var paintEndTime: Float = 0;
	public static var script_paint: Bool = false;

	public static var sceneRebelAction: Main.RebelAction = Closed;

	public static var enablePhysics: Bool = true;
	public static var sceneGravity: Bool = false;

	/***** settings variables *****/
	public static var REGULAR_SPEED:Int = 10;
	public static var RUSH_SPEED:Int = 800; //in pixels/s
	public static var RUSH_DISTANCE:Float = 70;

	public static var CONSUME_DURATION: Float = 1;
	public static var PAINT_DURATION: Float = 1.6;
	public static var GUIDE_SPEED:Int = 1200;//in pixels/s

	public static var ENTER_DISTANCE:Int = 10;

	public static var GRAVITY_ACCELERATION: Float = 9;

	public static function playerBirth(aliveLayer: AliveLayer)
	{
		playerSprite = aliveLayer.units[0].im;
		aliveLayer.units[0].id = 1; //reserved id for player
		aliveUnitId = aliveLayer.units[0].id;
		born = true;
	}
	
	public static function playerAct(targetCoordinateSpace: DisplayObject)
	{
		if(!born)
			return;

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
			if(rushInfo.progress >= rushInfo.total)
			{
				//place at correct pos
				//dx = (rushInfo.target.x - playerSprite.x - playerSprite.width/2);
				//dy = (rushInfo.target.y - playerSprite.y - playerSprite.height/2);


				rushing = false;
				if(consume)
				{
					if(!consumedObject.persistent)
					{
						eraseAround(rushInfo.target);
						mainScene.consumableLayer.consumeUnit(consumedObject);
					}
					
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
			var color1 : ARGB = new ARGB(PAINT_YELLOW);
			var color2 : ARGB = new ARGB(PAINT_PURPLE);
			var t: Float = (mainScene.frameCount%COLOR_CHANGE_RATE)/COLOR_CHANGE_RATE;
			color1.r = Math.round(color1.r*(1-t) + color2.r*t);
			color1.g = Math.round(color1.g*(1-t) + color2.g*t);
			color1.b = Math.round(color1.b*(1-t) + color2.b*t);
			paintAround(color1);
		}

		if(script_paint && KeyboardInputs.spaceKey)
		{
			ScriptLayer.paint(playerSprite);
			mainScene.displayScriptMaskImage();
		}

		//normal move
		if(!new_pos) {
			if(free_move)
			{
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
			}
			if(sceneGravity && enablePhysics)
			{
				dy += GRAVITY_ACCELERATION;
				new_pos = true;
			}
		}
		
		/*if(new_pos)
		{*/

			if(check_collision && enablePhysics)
				AliveLayer.moveSprite(playerSprite, aliveUnitId, Math.round(dx), Math.round(dy), targetCoordinateSpace);
			else{
				playerSprite.x+=dx;
				playerSprite.y+=dy;
			}

			var entryPoint: Point = new Point(playerSprite.x,playerSprite.y);

			if(mainScene.checkInnerScene(entryPoint))
			{
				Sys.println("enter inside at "+entryPoint+" crt "+playerSprite.x);
				if(entryPoint.x < mainScene.sceneLeft)
					playerSprite.x = entryPoint.x + ENTER_DISTANCE;
				else if(entryPoint.x + playerSprite.width > mainScene.sceneRight)
					playerSprite.x = entryPoint.x - playerSprite.width - ENTER_DISTANCE;
				else
					playerSprite.x = entryPoint.x;
				playerSprite.y = entryPoint.y;
			}
			else if(playerSprite.x < mainScene.sceneLeft)
			{
				if(mainScene.changeScene(PlayerLeaveSide.Left, entryPoint))
				{
					playerSprite.x = entryPoint.x - playerSprite.width - ENTER_DISTANCE;
					playerSprite.y = entryPoint.y;
				}
				else
				{
					playerSprite.x = mainScene.sceneLeft;
				}
			}
			else if (playerSprite.x + playerSprite.width > mainScene.sceneRight)
			{
				if(mainScene.changeScene(PlayerLeaveSide.Right, entryPoint))
				{
					playerSprite.x = entryPoint.x + ENTER_DISTANCE;
					playerSprite.y = entryPoint.y;
				}
				else
				{
					playerSprite.x = mainScene.sceneRight - playerSprite.width;
				}
			}
			else if(playerSprite.y < mainScene.sceneTop)
			{
				if(mainScene.changeScene(PlayerLeaveSide.Top, entryPoint))
				{
					playerSprite.x = entryPoint.x;
					playerSprite.y = entryPoint.y - playerSprite.height - ENTER_DISTANCE;
				}
				else
				{
					playerSprite.y = mainScene.sceneTop;
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
				else
				{
					playerSprite.y = mainScene.sceneBottom - playerSprite.height;
				}
			}

		//}

		PhysicsLayer.registerMovingElement(targetCoordinateSpace, playerSprite);

		//Sys.println("player "+playerSprite.x+" "+playerSprite.y);
	}

	public static function triggerPlayerPositionReactions(targetCoordinateSpace: DisplayObject)
	{
		ScriptLayer.reactToSprite(targetCoordinateSpace, playerSprite, aliveUnitId);

		mainScene.tipsLayer.tryTriggerTips(targetCoordinateSpace, playerSprite, mainScene.decorSprite);
	}

	public static function updateActingStatus() {
		if(rushing || consume || paint)
		{
			acting = true;
			mainScene.tipsLayer.registerAct();
		}
		else
			acting = false;
	}

	public static function triggerRush()
	{

		if(!canRebel)
			return;
		
		
		rushing = false;
		var dx: Float = 0; var dy: Float = 0;
		if (KeyboardInputs.arrowKeyUp) {
			dy -= RUSH_DISTANCE;
			rushing = true;
		}
		if (KeyboardInputs.arrowKeyDown) {
			dy += RUSH_DISTANCE;
			rushing = true;
		}
		if (KeyboardInputs.arrowKeyLeft) {
			dx -= RUSH_DISTANCE;
			rushing = true;
		}
		if (KeyboardInputs.arrowKeyRight) {
			dx += RUSH_DISTANCE;
			rushing = true;
		}
		
		rushInfo = setupRush2(playerSprite, dx, dy, 0, RUSH_SPEED);	

		Sys.println("rush start "+rushInfo);

		if(rushing)
			deformLayer.addPineDef(playerSprite,Math.atan2(rushInfo.dirY,rushInfo.dirX),RUSH_DISTANCE);

		updateActingStatus();

		Jukebox.playRippingSound();
	}

	static inline var CONSUME_SEARCH_DIST: Int = 150;
	public static function triggerConsume()
	{
		if(!canRebel)
			return;

		consumedObject = mainScene.consumableLayer.findClosest(playerSprite.x, playerSprite.y, CONSUME_SEARCH_DIST);

		Sys.println("consume "+consumedObject);

		if(consumedObject == null)
			return;

		var target: Point = new Point(consumedObject.im.x + consumedObject.im.width/2 /*- playerSprite.width/2*/, consumedObject.im.y + consumedObject.im.height/2 /*- playerSprite.height/2*/);

		rushInfo = setupRush(playerSprite, target, CONSUME_DURATION/2);

		rushing = true;

		consumeEndTime = Sys.time() + CONSUME_DURATION;

		consume = true;

		updateActingStatus();

		Jukebox.playCrunchSound();
	}

	public static inline var COLOR_CHANGE_RATE: Float = 255;
	public static function triggerPaint()
	{
		if(!canRebel)
			return;

		paintEndTime = Sys.time() + PAINT_DURATION;
		paint = true;

		updateActingStatus();

		Jukebox.playSpraySound();
	}

	public static function triggerGuide()
	{
		if(!canRebel)
			return;

		consumedObject = mainScene.consumableLayer.findNextId(consumedObject);

		if(consumedObject == null) //retry, in case we can loop back to first obj
			consumedObject = mainScene.consumableLayer.findNextId(consumedObject);

		Sys.println("guide to "+consumedObject);

		if(consumedObject == null)
			return;

		var target: Point = new Point(consumedObject.im.x + consumedObject.im.width/2 /*- playerSprite.width/2*/, consumedObject.im.y + consumedObject.im.height/2 /*- playerSprite.height/2*/);

		//target = mainScene.decorSprite.localToGlobal(target); //invisible points are given in the local space of the decor Bitmap

		rushInfo = setupRush(playerSprite, target, 0, GUIDE_SPEED);

		rushing = true;

		updateActingStatus();

	}

	public static function setupRush(sprite: Bitmap, target: Point, duration: Float = 0, velocity: Float = 0) : TargetRush
	{
		var rushInfo: TargetRush = {start: new Point(sprite.x+sprite.width/2, sprite.y+sprite.height/2), target: target, progress : 0, total : 0, dirX : 0, dirY : 0};
		
		rushInfo.start = mainScene.decorSprite.localToGlobal(rushInfo.start); //bitmap coords from alive layer need transformation

		rushInfo.dirX = (rushInfo.target.x - rushInfo.start.x);
		rushInfo.dirY = (rushInfo.target.y - rushInfo.start.y);
		if(velocity != 0)
		{
			duration = Math.sqrt(Math.pow(rushInfo.dirX,2)+Math.pow(rushInfo.dirY,2))/velocity;
		}
		if(duration != 0)
		{
			rushInfo.dirX /= duration*mainScene.fps.currentFPS;
			rushInfo.dirY /= duration*mainScene.fps.currentFPS;
		}

		rushInfo.total = Math.abs(rushInfo.target.x - rushInfo.start.x) + Math.abs(rushInfo.target.y - rushInfo.start.y);

		return rushInfo;
	}

	public static function setupRush2(sprite: Bitmap, amountX: Float, amountY: Float, duration: Float = 0, velocity: Float = 0) : TargetRush
	{
		var target: Point = new Point(sprite.x+sprite.width/2+amountX, sprite.y+sprite.height/2+amountY);
		target = mainScene.decorSprite.localToGlobal(target); //bitmap coords from alive layer need transformation

		return setupRush(sprite, target, duration, velocity);
	}

	public static function sceneChanged()
	{
		consumedObject = null;
	}

	static inline var PAINT_RADIUS : Int = 30;
	static inline var PAINT_BLANK : Int = 0xFFFFFFFF;
	static inline var PAINT_YELLOW : Int = 0xFFFFFF00;
	static inline var PAINT_PURPLE : Int = 0xFFFF00FF;
	static inline var PAINT_RADIUS_SQ : Int = 900;
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

		var insert_rect = new Rectangle(rm.x+rm.width/2-PAINT_RADIUS, rm.y+rm.height/2-PAINT_RADIUS, 2*PAINT_RADIUS, 2*PAINT_RADIUS);
		
			

		var idr: InsertDecorRegion = new InsertDecorRegion(insert_rect, deformLayer.decorSprite, layers.PhysicsLayer.static_pmask, bmp);
		layers.AnimationLayer.pushRegion(idr);
	}

	static inline var ERASE_RADIUS : Int = 20;
	static inline var ERASE_RADIUS_SQ : Int = 400;
	static function eraseAround(point: Point)
	{
    	var bmp: BitmapData = new BitmapData(2*PAINT_RADIUS, 2*PAINT_RADIUS);
		for(x in -ERASE_RADIUS...ERASE_RADIUS)
			for(y in -ERASE_RADIUS...ERASE_RADIUS)
			{
				if(Math.pow(x,2)+Math.pow(y,2)<=ERASE_RADIUS_SQ)
					bmp.setPixel32(ERASE_RADIUS+x, ERASE_RADIUS+y, layers.RandomPaperSample.getPixel(x,y));
				else
					bmp.setPixel32(ERASE_RADIUS+x, ERASE_RADIUS+y, 0x0);
			}

		var insert_rect = new Rectangle(point.x-ERASE_RADIUS, point.y - ERASE_RADIUS, 2*ERASE_RADIUS, 2*ERASE_RADIUS);	
		
		var idr: InsertDecorRegion = new InsertDecorRegion(insert_rect, deformLayer.decorSprite, layers.PhysicsLayer.static_pmask, bmp);
		layers.AnimationLayer.pushRegion(idr);
	}

}