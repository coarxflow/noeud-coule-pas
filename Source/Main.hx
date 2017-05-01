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

import openfl.geom.Point;

import layers.PhysicsLayer;
import layers.DeformationLayer;
import layers.AnimationLayer;
import layers.ConsumableLayer;
import layers.ScriptLayer;
import layers.AliveLayer;

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
	Consult;
	Closed;
	Continue;
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
	public var aliveLayer: AliveLayer;

	var deformLayer: DeformationLayer;

	public var consumableLayer: ConsumableLayer;

	var scriptMask: LogicMask;
	var scriptMaskImage: Bitmap;

	public var decorSprite: Bitmap;
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

		stage.color = 0xFF000000;
		Sys.println("get first scene");
		scene = world.firstScene();

		sceneUpdate();


		
		var messageFormat:TextFormat = new TextFormat("Verdana", 30, 0x000000, true);
		messageFormat.align = TextFormatAlign.CENTER;
		
		messageField = new TextField();
		addChild(messageField);
		messageField.width = 200;
		messageField.x = 600;
		messageField.y = 50;
		messageField.defaultTextFormat = messageFormat;
		messageField.selectable = false;
		messageField.text = "";

		stage.addEventListener(KeyboardEvent.KEY_DOWN, KeyboardInputs.keyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, KeyboardInputs.keyUp);
		this.addEventListener(Event.ENTER_FRAME, everyFrame);

		setGameState(Playing);

		fps = new FPS(10, 100, 0xffffff);
		//addChild(fps);
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

		Jukebox.loadSoundEffects();
	}

	private function initLinks() {
		PlayerControl.mainScene = this;

		targetCoordinateSpace = this;

		AnimationLayer.main = this;

		ScriptLayer.buildBank();
	}

	private function removeScene() {

		if(scene.screen_script != null)
			scene.screen_script.screenSleep();

		removeChild (decorSprite);
		
		removeChild(aliveLayer);

		removeChild(consumableLayer);

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
		Sys.println("decor updated with pos "+decorSpriteTmp.x+" "+decorSpriteTmp.y+" lims "+sceneLeft+" "+sceneRight+" "+sceneTop+" "+sceneBottom);

	}

	private function sceneUpdate() {

		Sys.println("update scene layers");

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

		scriptMask = scene.getScriptMask();

		PhysicsLayer.updateDecorSprite(decorSprite);
		PhysicsLayer.updateStaticMask(physicMask);

		ScriptLayer.updateDecorSprite(decorSprite);
		ScriptLayer.setMask(scriptMask);
		

		PlayerControl.sceneRebelAction = world.current_scene.action;

		scene.offsetAllSprites();

		scene.pushAnimations(decorSprite);

		PlayerControl.sceneGravity = world.current_scene.gravity_player;
		aliveLayer.sceneGravity = world.current_scene.gravity_others;

		PlayerControl.sceneChanged(); //reset consumed object only

		Jukebox.playFromSelection();

		if(scene.screen_script != null)
			scene.screen_script.screenAwake();
	}
	
	private function setGameState(state:GameState):Void {
		currentGameState = state;
		if (state == Paused) {
			messageField.alpha = 1;
		}else {
			
		}
	}


	public var frameCount: Int = 0;
	private static inline var ALIVE_UPDATE_RATE: Int = 1;
	public var runPaused: Bool;

	private function everyFrame(event:Event):Void {
		
		if(runPaused)
			return;

		frameCount++;
		if(GameClock.phase == GameClock.GameStatus.MainGame)
		{
			if(GameClock.updateActiveTime())
			{
				GameClock.phase = GameClock.GameStatus.GameOver;
				nextScreen("gameend");
			}
		}
		
		AnimationLayer.frameApplyAll();
		if(frameCount%ALIVE_UPDATE_RATE == 0)
		{
			PhysicsLayer.newFrameForMovingMask();
	 	}
	 	if(PlayerControl.acting || KeyboardInputs.spaceKey)
	 		PlayerControl.playerAct(this);
	 	aliveLayer.unitsAct(this, frameCount%ALIVE_UPDATE_RATE, ALIVE_UPDATE_RATE);
	 	if(!PlayerControl.acting && !KeyboardInputs.spaceKey)
	 		PlayerControl.playerAct(this);
	 	PlayerControl.updateActingStatus();

	 	if(scene.screen_script != null)
			scene.screen_script.runStep();

		developerLayers();
	}

	public function changeScene(side: PlayerControl.PlayerLeaveSide, outBoundPoint: openfl.geom.Point, if_inner_scene: String = ""):Bool {
		var scene = world.nextScene(side, outBoundPoint, if_inner_scene);
		Sys.println("try to change scene for "+scene);
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

	public function checkInnerScene(outBoundPoint: openfl.geom.Point): Bool
	{
		var name = scene.checkInsideDomains(outBoundPoint.x,outBoundPoint.y);
		if(name != null)
		{
			return changeScene(PlayerControl.PlayerLeaveSide.Inner, outBoundPoint, name);
		}
		return false;
	}

	public function regenScene()
	{
		Sys.println("regen "+scene);
		scene.reprocess();
		Sys.println("scene remove");
		removeScene();
		Sys.println("transfer unit");
		aliveLayer.transferUnitTo(scene.getAliveLayer(), PlayerControl.aliveUnitId);
		Sys.println("scene update");
		PlayerControl.mainScene.updateDecor(scene);
		sceneUpdate();
		Sys.println("scene updated");
	}

	public function nextScreen(name: String = ""):Bool {

		var scene = null;

		if(world.game_start)
		{
			scene = world.firstScene();
		}
		else if(name.length > 0)
		{
			scene = world.openScreen(name);
		}
		else
		{
			scene = world.closeScreen();
		}

		if(scene != null)
		{
			this.scene = scene;
			removeScene();
			if(PlayerControl.born)
			{
				aliveLayer.transferUnitTo(scene.getAliveLayer(), PlayerControl.aliveUnitId);
				if(world.current_scene.insertion == InsertScreen)
				{
					PlayerControl.free_move = false;
				}
				else
				{
					PlayerControl.free_move = true;
				}
				//PlayerControl.playerSprite.alpha = 0;
			}
			sceneUpdate();
			return true;
		}
		return false;
	}

	var displayPhysic: Bool = false;
	var displayMovingPhysic: Bool = false;
	var displayAliveIds: Bool;
	var displayConsumablesIds: Bool;
	var displayScriptLayer: Bool;

	var enterAliveScript: Bool = false;
	var enterLayerScript: Bool = false;
	var paintLayerScript: Bool = false;
	var closestAliveUnit: UnitBitmap;
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
			physicMaskImage = physicMask.toBitmap(0xFF, 0x00, 0xcc, 0x66000000, 0x0);
			addChild(physicMaskImage);

			physicMaskImage.x = (stage.stageWidth - physicMaskImage.width)/2;
			physicMaskImage.y = (stage.stageHeight - physicMaskImage.height)/2;

			displayMovingPhysic = true;

			//this.setChildIndex(aliveLayer, this.numChildren);
		}
		else if(displayMovingPhysic && !KeyboardInputs.mKey)
		{
			removeChild(physicMaskImage);
			displayMovingPhysic = false;
		}

		if(!displayAliveIds && KeyboardInputs.kKey)
		{
			aliveMaskImage = scene.alive_mask_image;

			addChild(aliveMaskImage);

			aliveMaskImage.x = (stage.stageWidth - aliveMaskImage.width)/2;
			aliveMaskImage.y = (stage.stageHeight - aliveMaskImage.height)/2;
			
			aliveLayer.drawInfo();
			this.setChildIndex(aliveLayer, this.numChildren);

			displayAliveIds = true;
		}
		else if(displayAliveIds && !KeyboardInputs.kKey)
		{
			aliveLayer.hideInfo();
			removeChild(aliveMaskImage);
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

		if(!displayScriptLayer && KeyboardInputs.lKey)
		{
			displayScriptMaskImage();
			displayScriptLayer = true;
		}
		else if(displayScriptLayer && !KeyboardInputs.lKey)
		{
			removeChild(scriptMaskImage);
			displayScriptLayer = false;
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
		if(KeyboardInputs.ctrlKey && !enterAliveScript && !enterLayerScript)
		{
			closestAliveUnit = aliveLayer.findClosestUnit(PlayerControl.aliveUnitId);
			if(closestAliveUnit != null)
			{
				enterAliveScript = true;
				KeyboardInputs.numberBuffer = "";
				aliveLayer.drawHiglightedUnit(closestAliveUnit.id);
				messageField.text = "";
			}
		}

		if(KeyboardInputs.lKey && paintLayerScript)
		{
			paintLayerScript = false;
			PlayerControl.script_paint = false;
			PlayerControl.enablePhysics = true;
			PlayerControl.canRebel = true;
			scene.writeScriptLayer();
			ScriptLayer.enabled = true;
		}
		if(KeyboardInputs.enterKey && enterLayerScript && !paintLayerScript)
		{
			enterLayerScript = false;
			if(KeyboardInputs.numberBuffer.length > 0)
			{
				layers.ScriptLayer.currentPaintScriptNum = Std.parseInt(KeyboardInputs.numberBuffer);
				KeyboardInputs.numberBuffer = "";
				paintLayerScript = true;
				PlayerControl.script_paint = true;
				PlayerControl.enablePhysics = false;
				PlayerControl.canRebel = false; //to not mix script painting with rebel action
				ScriptLayer.enabled = false;
				messageField.text = "";
				displayScriptMaskImage();
			}
		}
		if(KeyboardInputs.altKey && !enterAliveScript && !enterLayerScript)
		{
			enterLayerScript = true;
			KeyboardInputs.numberBuffer = "";
		}


		if(enterAliveScript || enterLayerScript)
		{
			messageField.text = "number : "+KeyboardInputs.numberBuffer;
			this.setChildIndex(messageField, this.numChildren);
		}

		if(devPoints != null)
		{	
			var i : Int = devPoints.length-1;
			while(i >= 0)
			{
				if(devPoints[i].expire < Sys.time())
				{
					removeChild(devPoints[i].shape);
					devPoints.remove(devPoints[i]);
				}
				i--;
			}
		}
	}

	public function displayScriptMaskImage()
	{
			removeChild(scriptMaskImage);

			scriptMaskImage = ScriptLayer.getMaskImage();

			scriptMaskImage.scaleX = scriptMask.downsampling_factor;
			scriptMaskImage.scaleY = scriptMask.downsampling_factor;

			addChild(scriptMaskImage);

			scriptMaskImage.x = (stage.stageWidth - scriptMaskImage.width)/2;
			scriptMaskImage.y = (stage.stageHeight - scriptMaskImage.height)/2;
	}

	var devPoints: Array<DevPoint>;
	static inline var DEVPOINT_RADIUS : Int = 5;
	static inline var DEVPOINT_LIFETIME: Float = 20;
	public function displayDevPoint(pos: Point, color: Int)
	{
		var dp : DevPoint = {position: pos, expire: Sys.time()+DEVPOINT_LIFETIME, shape: new Shape()};
		dp.shape.graphics.beginFill(color);
		dp.shape.graphics.drawCircle(pos.x, pos.y, DEVPOINT_RADIUS);
		dp.shape.graphics.endFill();

		addChild(dp.shape);

		if(devPoints == null)
			devPoints = new Array<DevPoint>();

		devPoints.push(dp);
	}

}

	typedef DevPoint = {
		var position: Point;
		var expire: Float;
		var shape: Shape;
	}