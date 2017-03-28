import openfl.display.DisplayObject;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.display.FPS;
import openfl.Assets;

import openfl.events.KeyboardEvent;
import openfl.events.Event;

import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

import layers.PhysicsLayer;
import layers.DeformationLayer;
import layers.AnimationLayer;
import layers.ConsumableLayer;

import crashdumper.CrashDumper;
import crashdumper.SessionData;

//import nme.Lib;

enum GameState {
	Paused;
	Playing;
}

enum RebelAction {
	Cross;
	Consume;
	Color;
	Closed;
}

class Main extends Sprite {
	

	private var messageField:TextField;
	private var currentGameState:GameState;

	var world: WorldScenes;
	public var scene : SceneProcessor;

	public var sceneLeft: Float;
	public var sceneRight: Float;
	public var sceneTop: Float;
	public var sceneBottom: Float;

	var playerSprite: Bitmap;

	var physicMask: LogicMask;
	var physicMaskImage: Bitmap;

	var aliveMask: LogicMask;
	var aliveMaskImage: Bitmap;
	var aliveLayer: AliveLayer;

	var deformLayer: DeformationLayer;

	public var consumableLayer: ConsumableLayer;

	var decorSprite: Bitmap;
	var decorSpriteTmp: Bitmap;

	public var fps : FPS;

	public static var targetCoordinateSpace: DisplayObject;
	
	public function new () {
		
		super ();

		var unique_id:String = SessionData.generateID("fooApp_"); 
    	//generates unique id: "fooApp_YYYY-MM-DD_HH'MM'SS_CRASH"
    
		var crashDumper = new CrashDumper(unique_id); 
    	//starts the crashDumper

    	Sys.println("start crashdumper at "+lime.system.System.applicationStorageDirectory);


		Sys.println("initialize data");
		initData();
		Sys.println("initialize links");

		initLinks();


		//var scene = new SceneProcessor ("assets/tree strokes ds.jpg");
		scene = world.firstScene();

		sceneUpdate();

		PlayerControl.playerSprite = aliveLayer.units[0].im;
		aliveLayer.units[0].id = 1; //reserved id for player
		PlayerControl.aliveUnitId = aliveLayer.units[0].id;
		//PlayerControl.playerSprite.rotation = 135;

		//addChild(PlayerControl.playerSprite);
		
		var messageFormat:TextFormat = new TextFormat("Verdana", 18, 0xbbbbbb, true);
		messageFormat.align = TextFormatAlign.CENTER;
		
		messageField = new TextField();
		addChild(messageField);
		messageField.width = 500;
		messageField.y = 50;
		messageField.defaultTextFormat = messageFormat;
		messageField.selectable = false;
		messageField.text = "";

		stage.addEventListener(KeyboardEvent.KEY_DOWN, KeyboardInputs.keyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, KeyboardInputs.keyUp);
		this.addEventListener(Event.ENTER_FRAME, everyFrame);

		setGameState(Playing);

		fps = new FPS(10, 100, 0xffffff);
		addChild(fps);
	}

	/*private static function create()
  	{
     	//new hxcpp.DebugStdio(true);
     	Lib.current.addChild (new Main());
  	}*/

	private function initData() {

		SceneProcessor.assets = ExtendedAssetManifest.loadManifest(SceneProcessor.SCENE_PROC_MANIFEST);
		if(SceneProcessor.assets == null)
		{
			SceneProcessor.assets = ExtendedAssetManifest.create(SceneProcessor.SCENE_PROC_DIR);
		}
		
		layers.RandomPaperSample.sample = Assets.getBitmapData("assets/paper sample.jpg");
		
		world = new WorldScenes();
		world.parseDefinition();
	}

	private function initLinks() {
		PlayerControl.mainScene = this;

		targetCoordinateSpace = this;

		AnimationLayer.main = this;
	}

	private function removeScene() {

		removeChild (decorSprite);
		
		removeChild(aliveLayer);

		AnimationLayer.clearList();
	}

	public function updateDecor(scene: SceneProcessor) {
		decorSpriteTmp = scene.getRawBitmap();

		decorSpriteTmp.x = (stage.stageWidth - decorSpriteTmp.width)/2;
		decorSpriteTmp.y = (stage.stageHeight - decorSpriteTmp.height)/2;

		sceneLeft = Math.max(-decorSpriteTmp.x, 0); //0 seems to be placed at left position of decor
		sceneRight = Math.min(-decorSpriteTmp.x+stage.stageWidth, decorSpriteTmp.width);
		sceneTop = Math.max(-decorSpriteTmp.y, 0);
		sceneBottom = Math.min(-decorSpriteTmp.y+stage.stageHeight, decorSpriteTmp.height);
		Sys.println("lims "+sceneLeft+" "+sceneRight+" "+sceneTop+" "+sceneBottom);

		//scene.getAliveLayer().offsetUnits(decorSpriteTmp.x, decorSpriteTmp.y);
		scene.getConsumableLayer().offsetUnits(decorSpriteTmp.x, decorSpriteTmp.y);
	}

	private function sceneUpdate() {

		decorSprite = decorSpriteTmp;

		addChild(decorSprite);

		physicMask = scene.getPhysicMask();

		consumableLayer = scene.getConsumableLayer();
		consumableLayer.drawUnits();//draw under alive units
		addChild(consumableLayer);


		aliveLayer = scene.getAliveLayer();
		aliveLayer.drawUnits();

		addChild(aliveLayer);

		aliveLayer.x = (stage.stageWidth - decorSprite.width) / 2;
		aliveLayer.y = (stage.stageHeight - decorSprite.height) / 2;

		deformLayer = scene.getDeformationLayer();
		deformLayer.decorSprite = decorSprite;
		PlayerControl.deformLayer = deformLayer;

		//addChild(physicMaskImage);

		// physicMaskImage.x = (stage.stageWidth - decorSprite.width) / 2;
		// physicMaskImage.y = (stage.stageHeight - decorSprite.height) / 2;

		PhysicsLayer.updateDecorSprite(decorSprite);
		PhysicsLayer.updateStaticMask(physicMask);

		PlayerControl.sceneRebelAction = world.current_scene.action;


		scene.pushAnimations(decorSprite);

		PlayerControl.sceneGravity = world.current_scene.gravity_player;
		aliveLayer.sceneGravity = world.current_scene.gravity_others;

		Jukebox.playFromSelection();

	}
	
	private function setGameState(state:GameState):Void {
		currentGameState = state;
		if (state == Paused) {
			messageField.alpha = 1;
		}else {
			
		}
	}


	private var frameCount: Int = 0;
	private static inline var ALIVE_UPDATE_RATE: Int = 1;

	private function everyFrame(event:Event):Void {
		frameCount++;
		AnimationLayer.frameApplyAll();
		if(frameCount%ALIVE_UPDATE_RATE == 0)
		{
			PhysicsLayer.newFrameForMovingMask();
	 	}
	 	//aliveLayer.unitsAct(this, frameCount%ALIVE_UPDATE_RATE, ALIVE_UPDATE_RATE);
	 	PlayerControl.playerAct(this);
	 	aliveLayer.unitsAct(this, frameCount%ALIVE_UPDATE_RATE, ALIVE_UPDATE_RATE);

		developerLayers();

	}

	public function changeScene(side: PlayerControl.PlayerLeaveSide, outBoundPoint: openfl.geom.Point):Bool {
		var scene = world.nextScene(side, outBoundPoint);
		if(scene != null)
		{
			this.scene = scene;
			Sys.println("scene remove");
			removeScene();
			Sys.println("transfer unit");
			aliveLayer.transferUnitTo(scene.getAliveLayer(), PlayerControl.aliveUnitId);
			Sys.println("scene update");
			sceneUpdate();
			Sys.println("scene updated");
			//this.setChildIndex(PlayerControl.playerSprite, this.numChildren);
			return true;
		}
		return false;
	}

	var displayPhysic: Bool = false;
	var displayMovingPhysic: Bool = false;
	var displayAliveIds: Bool;
	var displayConsumablesIds: Bool;

	var enterAliveScript: Bool = false;
	var closestAliveUnit: AliveLayer.UnitBitmap;
	var inputNumber: Int = 0;

	public function developerLayers() {
		if(!displayPhysic && KeyboardInputs.pKey)
		{
			physicMask = PhysicsLayer.static_pmask;
			physicMaskImage = physicMask.toBitmap();

			physicMaskImage.scaleX = physicMask.downsampling_factor;
			physicMaskImage.scaleY = physicMask.downsampling_factor;

			addChild(physicMaskImage);

			physicMaskImage.x = (stage.stageWidth - physicMaskImage.width)/2;
			physicMaskImage.y = (stage.stageHeight - physicMaskImage.height)/2;

			displayPhysic = true;

			this.setChildIndex(aliveLayer, this.numChildren);
		}
		else if(displayPhysic && !KeyboardInputs.pKey)
		{
			removeChild(physicMaskImage);
			displayPhysic = false;
		}

		if(!displayMovingPhysic && KeyboardInputs.mKey)
		{
			physicMask = PhysicsLayer.moving_pmask;
			physicMaskImage = physicMask.toBitmap();
			addChild(physicMaskImage);

			physicMaskImage.x = (stage.stageWidth - physicMaskImage.width)/2;
			physicMaskImage.y = (stage.stageHeight - physicMaskImage.height)/2;

			displayMovingPhysic = true;

			this.setChildIndex(aliveLayer, this.numChildren);
		}
		else if(displayMovingPhysic && !KeyboardInputs.mKey)
		{
			removeChild(physicMaskImage);
			displayMovingPhysic = false;
		}

		if(!displayAliveIds && KeyboardInputs.kKey)
		{
			aliveLayer.drawInfo();

			displayAliveIds = true;
		}
		else if(displayAliveIds && !KeyboardInputs.kKey)
		{
			aliveLayer.hideInfo();
			displayAliveIds = false;
		}

		if(!displayConsumablesIds && KeyboardInputs.nKey)
		{
			consumableLayer.drawInfo();

			displayConsumablesIds = true;
		}
		else if(displayConsumablesIds && !KeyboardInputs.nKey)
		{
			consumableLayer.hideInfo();
			displayConsumablesIds = false;
		}

		if(KeyboardInputs.enterKey && enterAliveScript)
		{
			enterAliveScript = false;
			if(KeyboardInputs.numberBuffer.length > 0)
			{
				inputNumber = Std.parseInt(KeyboardInputs.numberBuffer);
				KeyboardInputs.numberBuffer = "";
				aliveLayer.assignScriptToUnit(closestAliveUnit.id, inputNumber);
				scene.writeAliveScripts();
			}
			aliveLayer.hideInfo();
		}
		if(KeyboardInputs.enterKey && !enterAliveScript)
		{
			closestAliveUnit = aliveLayer.findClosestUnit(PlayerControl.aliveUnitId);
			if(closestAliveUnit != null)
			{
				enterAliveScript = true;
				KeyboardInputs.numberBuffer = "";
				aliveLayer.drawHiglightedUnit(closestAliveUnit.id);
			}
		}

		if(KeyboardInputs.numberBuffer.length > 0)
		{
			messageField.text = KeyboardInputs.numberBuffer;
			this.setChildIndex(messageField, this.numChildren);
		}

	}
}