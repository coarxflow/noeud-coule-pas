import openfl.events.KeyboardEvent;

import lime.ui.KeyCode;

class KeyboardInputs {
	public static var arrowKeyUp:Bool = false;
	public static var arrowKeyDown:Bool = false;
	public static var arrowKeyLeft:Bool = false;
	public static var arrowKeyRight:Bool = false;

	public static var spaceKey:Bool = false;

	//developer keys
	public static var developerInput:Bool = true;

	public static var pKey:Bool = false;
	public static var mKey:Bool = false;
	public static var kKey:Bool = false;
	public static var nKey:Bool = false;
	public static var dotKey:Bool = false;
	public static var rshiftKey:Bool = false;
	public static var enterKey:Bool = false;

	public static var numberBuffer:String= "";

	public static function keyDown(event:KeyboardEvent):Void {
		if (event.keyCode == 38) { // Up
			arrowKeyUp = true;
		}else if (event.keyCode == 40) { // Down
			arrowKeyDown = true;
		}else if (event.keyCode == 39) { // Left?
			arrowKeyRight = true;
		}else if (event.keyCode == 37) { // Right?
			arrowKeyLeft = true;
		}
		else if (event.keyCode == 32 && !spaceKey) { // Space
			spaceKey = true;
			switch (PlayerControl.sceneRebelAction) {
				case Cross:
				PlayerControl.triggerRush();
				case Consume:
				PlayerControl.triggerConsume();
				case Color:
				PlayerControl.triggerPaint();
				case Closed:
			}
			
		}
		//Sys.println(event.keyCode );
		if(developerInput)
		{
			if(event.keyCode == 80 && !pKey) //p
			{
				pKey = true;
			}
			if(event.keyCode == 77 && !mKey) //m
			{
				mKey = true;
			}
			if(event.keyCode == 75 && !kKey) //k
			{
				kKey = true;
			}
			if(event.keyCode == 78 && !nKey) //n
			{
				nKey = true;
			}
			if(event.keyCode == 190 && !dotKey) //.
			{
				dotKey = true;
				PlayerControl.mainScene.scene.save();
			}
			if(event.keyCode == 16 && !rshiftKey) //(right) shift, cpas lock = 20
			{
				rshiftKey = true;
				PlayerControl.enablePhysics = !PlayerControl.enablePhysics;
			}
			if(event.keyCode == 13 && !enterKey) //enter
			{
				enterKey = true;
			}

			//number input
			if(event.keyCode == 97 || event.keyCode == 49)
			{
				numberBuffer += "1";
			}
			else if(event.keyCode == 98 || event.keyCode == 50)
			{
				numberBuffer += "2";
			}
			else if(event.keyCode == 99 || event.keyCode == 51)
			{
				numberBuffer += "3";
			}
			else if(event.keyCode == 100 || event.keyCode == 52)
			{
				numberBuffer += "4";
			}
			else if(event.keyCode == 101 || event.keyCode == 53)
			{
				numberBuffer += "5";
			}
			else if(event.keyCode == 102 || event.keyCode == 54)
			{
				numberBuffer += "6";
			}
			else if(event.keyCode == 103 || event.keyCode == 55)
			{
				numberBuffer += "7";
			}
			else if(event.keyCode == 104 || event.keyCode == 56)
			{
				numberBuffer += "8";
			}
			else if(event.keyCode == 105 || event.keyCode == 57)
			{
				numberBuffer += "9";
			}
			else if(event.keyCode == 96 || event.keyCode == 48)
			{
				numberBuffer += "0";
			}
		}

	}
	
	public static function keyUp(event:KeyboardEvent):Void {
		if (event.keyCode == 38) { // Up
			arrowKeyUp = false;
		}else if (event.keyCode == 40) { // Down
			arrowKeyDown = false;
		}else if (event.keyCode == 39) { // Left?
			arrowKeyRight = false;
		}else if (event.keyCode == 37) { // Right?
			arrowKeyLeft = false;
		}
		else if (event.keyCode == 32) { // Space
			spaceKey = false;
		}

		if(event.keyCode == 80) //p
		{
			pKey = false;
		}
		if(event.keyCode == 77) //m
		{
			mKey = false;
		}
		if(event.keyCode == 75) //k
		{
			kKey = false;
		}
		if(event.keyCode == 78) //n
		{
			nKey = false;
		}
		if(event.keyCode == 190) //.
		{
			dotKey = false;
		}
		if(event.keyCode == 16) //shift
		{
			rshiftKey = false;
		}
		if(event.keyCode == 13) //enter
		{
			enterKey = false;
		}
	}
}