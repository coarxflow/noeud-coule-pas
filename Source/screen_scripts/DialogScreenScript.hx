package screen_scripts;

import openfl.display.Bitmap;

import openfl.geom.Point;

class DialogScreenScript extends ScreenScriptBase {

	var consumableLayer: layers.ConsumableLayer;
	var decorSprite: Bitmap;

	var cover1: Bitmap;
	var cover2: Bitmap;
	var cover3: Bitmap;

	public function new(consumable_layer: layers.ConsumableLayer, decor: Bitmap)
	{
		consumableLayer = consumable_layer;
		decorSprite = decor;
	}

	public override function screenAwake()
	{
		PlayerControl.triggerGuide(); //go to first point of dialog

		var pt: Point;

		//hide further parts of the dialog
		cover1 = new Bitmap(layers.RandomPaperSample.getRegion(411,270));
		pt = new Point(424,100);
		pt=decorSprite.localToGlobal(pt);
		cover1.x = pt.x; cover1.y = pt.y;
		PlayerControl.mainScene.addChild(cover1);

		cover2 = new Bitmap(layers.RandomPaperSample.getRegion(360,223));
		pt = new Point(23,286);
		pt=decorSprite.localToGlobal(pt);
		cover2.x = pt.x; cover2.y = pt.y;
		PlayerControl.mainScene.addChild(cover2);

		cover3 = new Bitmap(layers.RandomPaperSample.getRegion(388,248));
		pt = new Point(405,364);
		pt=decorSprite.localToGlobal(pt);
		cover3.x = pt.x; cover3.y = pt.y;
		PlayerControl.mainScene.addChild(cover3);

		currentDialogIndex = 0;
	}

	var currentDialogIndex = 0;
	public override function runStep()
	{
		if(PlayerControl.consumedObject != null)
		{
			if(PlayerControl.consumedObject.id > currentDialogIndex)
			{
				currentDialogIndex = PlayerControl.consumedObject.id;

				switch(currentDialogIndex)
				{
					case 2:
					PlayerControl.mainScene.removeChild(cover1);
					case 3:
					PlayerControl.mainScene.removeChild(cover2);
					case 4:
					PlayerControl.mainScene.removeChild(cover3);
				}
			}

			//reach last point in scene?
			if(consumableLayer.getMaxId() == PlayerControl.consumedObject.id) //max id should be 4
			{
				PlayerControl.sceneRebelAction = Main.RebelAction.Continue; //set up to return to world on next space hit
			}
		}
	}

	public override function screenSleep()
	{
		PlayerControl.mainScene.removeChild(cover1);
		PlayerControl.mainScene.removeChild(cover2);
		PlayerControl.mainScene.removeChild(cover3);
	}

}