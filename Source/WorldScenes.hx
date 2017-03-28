
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
}

typedef AnimInfo = {
	var domain:Rectangle;
	var script:String;
} 

typedef SceneInfo = {
	var source:String;
	var insertion:SceneInsertion;
	var parent:String;
	var action:Main.RebelAction;
	@:optional var domain:Rectangle;
	@:optional var anims:Array<AnimInfo>;
	@:optional var invisible_consumables:Array<Point>;
	@:optional var gravity_player:Bool; @:optional var gravity_others:Bool;
	@:optional var sounds:Array<String>;
} 

class WorldScenes {

var grid_width : Int;
var grid_height : Int;

var grid_info : Array<Array<SceneInfo>> = new Array<Array<SceneInfo>>();

var inside_info : Array<SceneInfo> = new Array<SceneInfo>();

var scenes_data : Map<String,SceneProcessor> = new Map<String,SceneProcessor>();

public var current_scene: SceneInfo;
var current_row : Int;
var current_col : Int;

public function new()
{}

public function firstScene() : SceneProcessor
{
	current_scene = inside_info[0];
	var sp: SceneProcessor = loadScene(inside_info[0]);
	PlayerControl.mainScene.updateDecor(sp);
	return sp;
}

public function nextScene(side:PlayerControl.PlayerLeaveSide, outBoundPoint: Point) : SceneProcessor
{

	var next_scene: SceneInfo = null;
	if(current_scene.insertion == InsideScene)
	{
		for(i in 0...grid_width)
			for(j in 0...grid_height)
			{
				if(current_scene.parent == grid_info[j][i].source)
				{
					next_scene = grid_info[j][i];
					current_row = j;
					current_col = i;
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
			current_col--;
			case PlayerControl.PlayerLeaveSide.Right:
			current_col++;
			case PlayerControl.PlayerLeaveSide.Top:
			current_row--;
			case PlayerControl.PlayerLeaveSide.Bottom:
			current_row++;
		}

		if(current_col >= 0 && current_col < grid_width && current_row >= 0 && current_row < grid_height)
		{
			next_scene = grid_info[current_row][current_col];
		}

	}

	var sp: SceneProcessor = loadScene(next_scene);

	if(sp != null)
		PlayerControl.mainScene.updateDecor(sp);


	if(current_scene.insertion == InsideScene)
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
		}
	}


	if(next_scene != null)
	{
		current_scene = next_scene;
	}

	return sp;
}

public function loadScene(next_scene:SceneInfo) : SceneProcessor
{
	if(next_scene != null)
	{
		var scene = scenes_data.get(next_scene.source);

		if(scene != null)
			return scene;

		scene = new SceneProcessor ("assets/"+next_scene.source+".jpg");

		scene.load();
		scene.process(next_scene.action == Main.RebelAction.Consume);
		//scene.save();
		scene.processAnimations(next_scene.anims);
		scene.initLayers();
		scene.readAliveScripts();

		Jukebox.resetSceneSounds();
		for(s in next_scene.sounds)
		{
			Jukebox.addSoundForScene(s);
		}

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
	}

	Sys.println(grid_info);
	Sys.println(inside_info);

}

function parseScene(node: Xml, crt_insert : SceneInsertion)
{
	var si: SceneInfo = {source:node.get("src"),insertion:crt_insert,parent:null,action:Closed};
	Sys.println(node.get("src"));
	var act: String = node.get("act");
	switch(act)
	{
		case "cross":
		si.action = Cross;
		case "consume":
		si.action = Consume;
		case "color":
		si.action = Color;
		case "no":
		default:
		si.action = Closed;
	}

	si.anims = new Array<AnimInfo>();
	var elemit2 = node.elements();
	while(elemit2.hasNext())
	{
		var id2 = elemit2.next();
		Sys.println(id2.nodeName);
		if(id2.nodeName == "anim")
		{
			var anim: AnimInfo = {domain: null, script: id2.get("script")};
			var l = Std.parseInt(id2.get("left"));
			var t = Std.parseInt(id2.get("top"));
			var r = Std.parseInt(id2.get("right"));
			var b = Std.parseInt(id2.get("bottom"));
			Sys.println(l+" "+t+" "+r+" "+b);
			anim.domain = new Rectangle(l,t,r-l,b-t);
			si.anims.push(anim);
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
		inside_info.push(si);
	}
	else if(crt_insert == WorldGrid)
	{
		grid_info[grid_info.length-1].push(si);
	}

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
}

}