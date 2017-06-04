
import sys.io.File;
import sys.FileSystem;

import haxe.io.Bytes;
import haxe.xml.Parser;

import openfl.geom.Rectangle;
import openfl.geom.Point;


enum SceneInsertion {
	WorldGrid;
	InsideScene;
	OutsideWorld;
	InsertScreen;
}

typedef AnimInfo = {
	var domain:Rectangle;
	var script:String;
	@:optional var source:String;
	@:optional var period:Float;
	@:optional var delay:Float;
	@:optional var nlines: Array<Int>;
} 

typedef SceneInfo = {
	var source:String;
	var insertion:SceneInsertion;
	var parent:String;
	var action:Main.RebelAction;
	@:optional var domain:Rectangle;
	@:optional var anims:Array<AnimInfo>;
	@:optional var tips:Array<AnimInfo>;
	@:optional var process_consumables:Bool;
	@:optional var invisible_consumables:Array<Point>;
	@:optional var invisible_points:Array<Point>;
	@:optional var gravity_player:Bool; @:optional var gravity_others:Bool;
	@:optional var sounds:Array<String>;
	@:optional var script:String;
} 

class WorldScenes {

	public static var instance: WorldScenes;

var grid_width : Int;
var grid_height : Int;

var grid_info : Array<Array<SceneInfo>> = new Array<Array<SceneInfo>>();

var inside_info : Array<SceneInfo> = new Array<SceneInfo>();

var insert_info : Array<WorldScenes.SceneInfo> = new Array<SceneInfo> ();

var scenes_data : Map<String,SceneProcessor> = new Map<String,SceneProcessor>();

public var current_scene: SceneInfo;
var current_row : Int;
var current_col : Int;

var return_scene: SceneInfo;
var player_saved_pos: Point;

public function new()
{
	instance = this;
}

public var game_start : Bool = true;
var first_scenes : Array<SceneInfo> = new Array<SceneInfo>();
var start_index : Int = 2;
public function firstScene() : SceneProcessor
{
	current_scene = first_scenes[start_index];
	var sp: SceneProcessor = loadScene(first_scenes[start_index]);
	PlayerControl.mainScene.updateDecor(sp);
	start_index++;
	if(start_index == first_scenes.length)
	{
		game_start = false;
		PlayerControl.playerBirth(sp.getAliveLayer());
		GameClock.phase = GameClock.GameStatus.MainGame;
	}
	return sp;
}

/*public var game_end : Bool = true;
var end_scene : WorldScenes.SceneInfo;
public function endScene()
{
	current_scene = end_scene;
	var sp: SceneProcessor = loadScene(end_scene);
	PlayerControl.mainScene.updateDecor(sp);
	GameClock.phase = GameClock.GameStatus.GameOver;
	PlayerControl.acting = false;
	PlayerControl.born = false;
}*/

public function nextScene(side:PlayerControl.PlayerLeaveSide, outBoundPoint: Point, if_inner_scene: String = "") : SceneProcessor
{

	var next_scene: SceneInfo = null;
	var next_row: Int = current_row;
	var next_col: Int = current_col;
	if(side == PlayerControl.PlayerLeaveSide.Inner)
	{
		for(si in inside_info)
		{
			if(si.source == if_inner_scene)
			{
				next_scene = si;
			}
		}
	}
	else if(current_scene.insertion == InsideScene)
	{
		for(i in 0...grid_width)
			for(j in 0...grid_height)
			{
				if(current_scene.parent == grid_info[j][i].source)
				{
					next_scene = grid_info[j][i];
					next_row = j;
					next_col = i;
				}
			}

		if(next_scene == null)
			Sys.println("could not find parent scene "+current_scene.parent);
	}
	else if(current_scene.insertion == WorldGrid)
	{
		switch(side)
		{
			case PlayerControl.PlayerLeaveSide.Left:
			next_col--;
			case PlayerControl.PlayerLeaveSide.Right:
			next_col++;
			case PlayerControl.PlayerLeaveSide.Top:
			next_row--;
			case PlayerControl.PlayerLeaveSide.Bottom:
			next_row++;
			case PlayerControl.PlayerLeaveSide.Inner:
		}

		if(next_col >= 0 && next_col < grid_width && next_row >= 0 && next_row < grid_height)
		{
			next_scene = grid_info[next_row][next_col];
		}

	}

	var sp: SceneProcessor = loadScene(next_scene);

	if(sp != null)
		PlayerControl.mainScene.updateDecor(sp);
	else return null;

	if(side == PlayerControl.PlayerLeaveSide.Inner)
	{
		Sys.println("compute enter inside "+PlayerControl.mainScene.sceneLeft+" + "+(outBoundPoint.x - next_scene.domain.left) / next_scene.domain.width+"*"+PlayerControl.mainScene.decorSpriteTmp.width);
		outBoundPoint.x = /*PlayerControl.mainScene.sceneLeft + */(outBoundPoint.x - next_scene.domain.left) / next_scene.domain.width * PlayerControl.mainScene.decorSpriteTmp.width;
		outBoundPoint.y = /*PlayerControl.mainScene.sceneTop + */(outBoundPoint.y - next_scene.domain.top) / next_scene.domain.height * PlayerControl.mainScene.decorSpriteTmp.height;
	}
	else if(current_scene.insertion == InsideScene)
	{
		switch(side)
		{
			case PlayerControl.PlayerLeaveSide.Left:
			outBoundPoint.y = current_scene.domain.top + current_scene.domain.height*outBoundPoint.y/PlayerControl.mainScene.stage.stageWidth;
			outBoundPoint.x = current_scene.domain.left;
			case PlayerControl.PlayerLeaveSide.Right:
			outBoundPoint.y = current_scene.domain.top + current_scene.domain.height*outBoundPoint.y/PlayerControl.mainScene.stage.stageWidth;
			outBoundPoint.x = current_scene.domain.right;
			case PlayerControl.PlayerLeaveSide.Top:
			outBoundPoint.x = current_scene.domain.left + current_scene.domain.width*outBoundPoint.x/PlayerControl.mainScene.stage.stageWidth;
			outBoundPoint.y = current_scene.domain.top;
			case PlayerControl.PlayerLeaveSide.Bottom:
			outBoundPoint.x = current_scene.domain.left + current_scene.domain.width*outBoundPoint.x/PlayerControl.mainScene.stage.stageWidth;
			outBoundPoint.y = current_scene.domain.bottom;
			case PlayerControl.PlayerLeaveSide.Inner:
		}
		
	}
	else
	{
		switch(side)
		{
			case PlayerControl.PlayerLeaveSide.Left:
			outBoundPoint.x = PlayerControl.mainScene.sceneRight;
			case PlayerControl.PlayerLeaveSide.Right:
			outBoundPoint.x = PlayerControl.mainScene.sceneLeft;
			case PlayerControl.PlayerLeaveSide.Top:
			outBoundPoint.y = PlayerControl.mainScene.sceneBottom;
			case PlayerControl.PlayerLeaveSide.Bottom:
			outBoundPoint.y = PlayerControl.mainScene.sceneTop;
			case PlayerControl.PlayerLeaveSide.Inner:
		}
	}


	if(next_scene != null)
	{
		current_row = next_row;
		current_col = next_col;
		current_scene = next_scene;
	}

	return sp;
}

public function openScreen(ref: String) : SceneProcessor
{
	var next_scene: SceneInfo = null;
	for(sc in insert_info)
		if(sc.source == ref)
		{
			next_scene = sc;
			break;
		}

		Sys.println("open screen "+ref);

	var sp: SceneProcessor = loadScene(next_scene);

	if(sp != null)
		PlayerControl.mainScene.updateDecor(sp);

	if(next_scene != null)
	{
		if(current_scene.insertion != InsertScreen)
		{
			return_scene = current_scene;
			player_saved_pos = new Point(PlayerControl.playerSprite.x, PlayerControl.playerSprite.y);
		}
		current_scene = next_scene;
	}

	return sp;
}

public function closeScreen() : SceneProcessor
{
	if(return_scene == null)
	{
		Sys.println("error: no scene to return to");
		return null;
	}

	var sp: SceneProcessor = loadScene(return_scene);

	if(sp != null)
		PlayerControl.mainScene.updateDecor(sp);

	if(return_scene != null)
	{
		current_scene = return_scene;
		PlayerControl.playerSprite.x = player_saved_pos.x;
		PlayerControl.playerSprite.y = player_saved_pos.y;
	}

	return sp;
}

public function loadScene(next_scene:SceneInfo) : SceneProcessor
{
	if(next_scene != null)
	{
		Sys.println("get scene "+next_scene.source);
		var scene = scenes_data.get(next_scene.source);

		Sys.println("reset jukebox");
		Jukebox.resetSceneSounds();
		for(s in next_scene.sounds)
		{
			Jukebox.addSoundForScene(s);
		}

		if(scene != null)
			return scene;

		scene = new SceneProcessor ("assets/"+next_scene.source+".jpg", next_scene.insertion != InsertScreen);
		scene.initLayers();

		scene.load();
		scene.process(next_scene.process_consumables);
		scene.save();

		Sys.println("read alive and layer scripts configs");
		scene.readAliveScripts();
		scene.readScriptLayer();

		Sys.println("process anims and points lists");
		scene.processAnimations(next_scene.anims);
		scene.processTips(next_scene.tips);
		scene.processInvisibleConsumables(next_scene.invisible_consumables, true);
		scene.processInvisibleConsumables(next_scene.invisible_points, true);

		for(si in inside_info) //add subdomain associated to any child scene (inside scene)
		{
			if(si.parent == next_scene.source)
				scene.pushInsideDomain(si.source, si.domain);
		}

		scene.attachScript(next_scene.script);

		scenes_data.set(next_scene.source, scene);

		return scene;
	}
	else
		return null;
}

public function parseDefinition()
{
	var fi = File.read(ExtendedAssetManifest.chkSep("assets/world.xml"), false);
	var b: Bytes = fi.readAll();
	fi.close();
	var txt:String = b.toString();

	var doc: Xml = Parser.parse(txt);

	var root = doc.firstElement();
	var elemit = root.elements();

	var crt_insert : SceneInsertion = OutsideWorld;

	while(elemit.hasNext())
	{
		var id = elemit.next();
		if(id.nodeName == "grid")
		{
			grid_width = Std.parseInt(id.get("cols"));
			grid_height = Std.parseInt(id.get("rows"));
			crt_insert = WorldGrid;

			var elemit2 = id.elements();
			while(elemit2.hasNext())
			{
				var id2 = elemit2.next();
				if(id2.nodeName == "row")
				{
					if(grid_info.length > 0 && grid_info[grid_info.length-1].length != grid_width)
						Sys.println("WorldScenes parse inconsistency : "+grid_info[grid_info.length-1].length+" cols read against "+grid_width+" declared");
					grid_info.push(new Array<SceneInfo> ());
					if(grid_info.length > grid_height)
						Sys.println("WorldScenes parse inconsistency : "+grid_info.length+" rows read against "+grid_height+" declared");

					var elemit3 = id2.elements();
					while(elemit3.hasNext())
					{
						var id3 = elemit3.next();
						if(id3.nodeName == "scene")
						{
							parseScene(id3, crt_insert);
						}
					}
				}
			}

		}
		else if(id.nodeName == "inside")
		{
			crt_insert = InsideScene;

			var elemit2 = id.elements();
			while(elemit2.hasNext())
			{
				var id2 = elemit2.next();
				if(id2.nodeName == "scene")
				{
					parseScene(id2, crt_insert);
					
				}
			}
		}
		else if(id.nodeName == "screens")
		{
			crt_insert = InsertScreen;

			var elemit2 = id.elements();
			while(elemit2.hasNext())
			{
				var id2 = elemit2.next();
				if(id2.nodeName == "scene")
				{
					parseScene(id2, crt_insert);
					
				}
			}
		}
	}

	Sys.println(grid_info);
	Sys.println(inside_info);

}

function parseScene(node: Xml, crt_insert : SceneInsertion)
{
	var ref: String = node.get("ref");
	if(ref != null)
	{
		var sir:SceneInfo = null;

		for(sia in grid_info)
			for(sil in sia)
				if(sil.source == ref)
				{
					sir = sil;
					break;
				}

		if(sir == null)
		{
			for(sil in inside_info)
				if(sil.source == ref)
				{
					sir = sil;
					break;
				}
		}

		if(sir != null)
			pushScene(sir, node, crt_insert);
		return;
	}

	var si: SceneInfo = {source:node.get("src"),insertion:crt_insert,parent:null,action:Closed};
	
	var act: String = node.get("act");
	switch(act)
	{
		case "cross":
		si.action = Cross;
		case "consume":
		si.action = Consume;
		case "color":
		si.action = Color;
		case "guide":
		si.action = Consult;
		case "skip":
		si.action = Continue;
		case "no":
		default:
		si.action = Closed;
	}

	si.anims = new Array<AnimInfo>();
	si.tips = new Array<AnimInfo>();
	var elemit2 = node.elements();
	while(elemit2.hasNext())
	{
		var id2 = elemit2.next();
		
		if(id2.nodeName == "anim" || id2.nodeName == "tip")
		{
			var anim: AnimInfo = {domain: null, script: id2.get("script")};

			var l = Std.parseInt(id2.get("left"));
			var t = Std.parseInt(id2.get("top"));
			var r = Std.parseInt(id2.get("right"));
			var b = Std.parseInt(id2.get("bottom"));
			anim.domain = new Rectangle(l,t,r-l,b-t);

			anim.source = id2.get("src");
			anim.period = Std.parseFloat(id2.get("period"));
			anim.delay = Std.parseFloat(id2.get("delay"));

			var cols_at_line:String = id2.get("line1");
			if(cols_at_line != null)
				anim.nlines = new Array<Int>();
			var i: Int = 1;
			while(cols_at_line != null)
			{
				anim.nlines.push(Std.parseInt(cols_at_line));
				i++;
				cols_at_line = id2.get("line"+i);
			}
			if(id2.nodeName == "anim")
				si.anims.push(anim);
			else if (id2.nodeName == "tip")
				si.tips.push(anim);
		}
		if(id2.nodeName == "point")
		{
			var pt:Point = new Point(0,0);
			pt.x = Std.parseInt(id2.get("x"));
			pt.y = Std.parseInt(id2.get("y"));
			var pttype: String = id2.get("type");
			switch(pttype)
			{
				case "consumable":
				if(si.invisible_consumables == null)
					si.invisible_consumables = new Array<Point> ();
				si.invisible_consumables.push(pt);
				case "guide":
				if(si.invisible_points == null)
					si.invisible_points = new Array<Point> ();
				si.invisible_points.push(pt);
			}
		}
	}

	if(crt_insert == InsideScene)
	{
		si.parent = node.get("parent");
		var l = Std.parseInt(node.get("left"));
		var t = Std.parseInt(node.get("top"));
		var r = Std.parseInt(node.get("right"));
		var b = Std.parseInt(node.get("bottom"));
		si.domain = new Rectangle(l,t,r-l,b-t);
	}

	var proccons: String = node.get("process_consumables");
	if(proccons != null)
	{
		if(proccons == "true")
		{
			si.process_consumables = true;
		}
		else
		{
			si.process_consumables = false;
		}
	}

	si.script = node.get("script");

	var grav: String = node.get("gravity");
	if(grav != null)
	{
		if(grav == "all")
		{
			si.gravity_player = true;
			si.gravity_others = true;
		}

		else if(grav == "player")
		{
			si.gravity_player = true;
		}

		else if(grav == "others")
		{
			si.gravity_others = true;
		}
	}

	var soundname:String = node.get("snd1");
	si.sounds = new Array<String>();
	var i: Int = 1;
	while(soundname != null)
	{
		si.sounds.push(soundname);
		i++;
		soundname = node.get("snd"+i);
	}

	pushScene(si, node, crt_insert);
}

function pushScene(si: SceneInfo, node: Xml, crt_insert : SceneInsertion)
{
	if(crt_insert == InsideScene)
	{
		inside_info.push(si);
	}
	else if(crt_insert == WorldGrid)
	{
		grid_info[grid_info.length-1].push(si);
	}
	else if(crt_insert == InsertScreen)
	{
		var cat: String = node.get("cat");
		if(cat == "start")
			first_scenes.push(si);
		else
			insert_info.push(si);
	}
}

}