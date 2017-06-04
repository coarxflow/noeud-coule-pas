import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.Graphics;
import openfl.display.DisplayObject;
import openfl.Assets;
import openfl.geom.Point;
import openfl.geom.Rectangle;

import lime.math.color.ARGB;
import lime.utils.AssetManifest;
import lime.utils.AssetType;

import sys.io.File;
import sys.FileSystem;

typedef ColorFilterSetting = {
	    var df : Int;
	    var tgcol : ARGB;
	    var tolr : Int;
	}

class SceneProcessor {

	////// file management /////
	public static inline var SCENE_PROC_DIR: String = "assets/scene_proc/";
	public static inline var SCENE_PROC_MANIFEST: String = SCENE_PROC_DIR+"manifest";
	public static var assets: ExtendedAssetManifest;

	var reference_path: String;
	var save_dir: String;
	var filename: String;

	static inline var FILE_EDITED_DECOR: String = "edited_decor.png";
	static inline var FILE_PHYSIC_MASK: String = "physic_mask.png";
	static inline var FILE_ALIVE_MASK: String = "alive_mask.png";
	static inline var FILE_ALIVE_LAYER: String = "alive_layer.xml";
	static inline var FILE_ALIVE_SCRIPTS: String = "alive_scripts.xml";
	static inline var FOLDER_ALIVE_LAYER: String = "alive_layer/";
	static inline var FILE_CONSUMABLE_MASK: String = "consumable_mask.png";
	static inline var FILE_CONSUMABLE_LAYER: String = "consumable_layer.xml";
	static inline var FOLDER_CONSUMABLE_LAYER: String = "consumable_layer/";
	static inline var FILE_SCRIPT_MASK: String = "script_mask.png";

	//scene layers and masks attributes
	var raw_bitmap:Bitmap;

	var physic_bitmap:Bitmap;
	var physic_mask:LogicMask;

	var alive_mask:LogicMask;
	public var alive_mask_image:Bitmap;
	var alive_layer:layers.AliveLayer;

	var deform_layer:layers.DeformationLayer;

	var consumables_mask:LogicMask;
	public var consumables_mask_image:Bitmap;
	var consume_layer:layers.ConsumableLayer;
	var consumables_from_decor: Bool = false;

	var script_mask: LogicMask;

	var anims: Array<layers.AnimatedRegion>;

	var tips_layer: layers.TipsLayer; //tips layer is an instance, unlike AnimationLayser which is static, because I want to retain the evolution of the tips shown in the scene across screen chnges


	var inside_domains: Map<String, openfl.geom.Rectangle>;

	public var screen_script: screen_scripts.ScreenScriptBase;

	var processed: Bool;

	var offset_applied: Bool = false;

	public function new(path:String, process: Bool) {

		reference_path = path;

		var dirs = reference_path.split('/');
		filename = dirs[dirs.length-1].split('.')[0];
		save_dir = filename + '/';

		this.processed = process;
	}

	var tosave_rawbitmap: Bool = false;
	var tosave_alive: Bool = false;
	var tosave_consume: Bool = false;
	var tosave_physics: Bool = false;

	public function process(populate_consume_layer: Bool) {

		if(!processed)
		{
			empty_layer_masks();
			return;
		}
		
		Sys.println("process raw bitmap");

		if(alive_mask == null)
		{
			Sys.println("process alive mask");

			alive_mask = filterColor(raw_bitmap.bitmapData, pinkfilter);
			alive_mask.blendIn(filterColor(raw_bitmap.bitmapData, purplefilter));
			alive_mask.blendIn(filterColor(raw_bitmap.bitmapData, purple2filter));
			alive_mask_image = alive_mask.toBitmap();
			identifyConnectedPixels(alive_mask);

			alive_layer.extractRegions(alive_mask, raw_bitmap, filename);

			tosave_alive = true;
			tosave_rawbitmap =true;
		}

		//alive_layer.x = raw_bitmap.x;
		//alive_layer.y = raw_bitmap.y;


		if(consumables_mask == null)
		{
			if(populate_consume_layer)
			{
				consumables_from_decor = true;

				consumables_mask = filterColor(raw_bitmap.bitmapData, yellowfilter);
				identifyConnectedPixels(consumables_mask);
				consumables_mask_image = consumables_mask.toBitmap();
				consume_layer.extractRegions(consumables_mask, raw_bitmap);

				tosave_consume = true;
				tosave_rawbitmap =true;
			}
		}


		//consume_layer.x = raw_bitmap.x;
		//consume_layer.y = raw_bitmap.y;

		if(physic_mask == null)
		{
			physic_mask = filterColor(raw_bitmap.bitmapData, blackfilter);
			physic_mask.blendIn(filterColor(raw_bitmap.bitmapData, gray1filter));
			physic_mask.blendIn(filterColor(raw_bitmap.bitmapData, gray2filter));
			/*physic_mask.blendIn(filterColor(raw_bitmap.bitmapData, gray3filter));
			physic_mask.blendIn(filterColor(raw_bitmap.bitmapData, gray4filter));
			physic_mask.blendIn(filterColor(raw_bitmap.bitmapData, gray5filter));*/
			physic_mask.dilate(LogicMask.DISK_SE);
			physic_mask.erode(LogicMask.DISK_SE);

			tosave_physics = true;
		}


	}

	public function empty_layer_masks() {

		
		alive_mask = new LogicMask(Math.round(raw_bitmap.width), Math.round(raw_bitmap.height), 1);
		alive_mask_image = alive_mask.toBitmap();

		physic_mask = new LogicMask(Math.round(raw_bitmap.width/4), Math.round(raw_bitmap.height/4) , 4);

		//script_mask = new LogicMask(Math.round(raw_bitmap.width/4), Math.round(raw_bitmap.height/4) , 4);
	}

	public function reprocess() {
		Sys.println(raw_bitmap.width+" "+raw_bitmap.height);
		raw_bitmap = new Bitmap (Assets.getBitmapData(reference_path));

		Sys.println(raw_bitmap.width+" "+raw_bitmap.height);

		alive_mask = null;
		alive_layer = null;
		consumables_mask = null;
		consume_layer = null;
		physic_mask = null;

		initLayers();
		process(consumables_from_decor);
	}

	public function initLayers() {
		deform_layer = new layers.DeformationLayer();
		alive_layer = new layers.AliveLayer();
		consume_layer = new layers.ConsumableLayer();
		tips_layer = new layers.TipsLayer();
	}

	public function processAnimations(list: Array<WorldScenes.AnimInfo>) {
		anims = new Array<layers.AnimatedRegion> ();

		for(anim in list)
		{

			switch(anim.script)
			{
				case "rotating-clock":
				anims.push(new layers.RotatingClock(anim.domain, raw_bitmap));
				case "cyclic-region":
				var bmps: Array<BitmapData> = layers.AnimationLayer.extractAnimFromFile("assets/"+anim.source+".jpg", anim.domain, Math.round(anim.domain.width), Math.round(anim.domain.height), anim.nlines, false);
				Sys.println(anim.nlines+" "+bmps);
				anims.push(new layers.CyclicDecorRegion(anim.domain, raw_bitmap, physic_mask, bmps, anim.period));
				case "shaking-region":
				var bmp: BitmapData = layers.AnimationLayer.extractAnimFromFile("assets/"+anim.source+".jpg", anim.domain, Math.round(anim.domain.width), Math.round(anim.domain.height), [1])[0];
				anims.push(new layers.ShakingDecorRegion(anim.domain, raw_bitmap, physic_mask, bmp, anim.period, anim.delay));
				case "insert-region":
				var bmp: BitmapData = layers.AnimationLayer.extractAnimFromFile("assets/"+anim.source+".jpg", anim.domain, Math.round(anim.domain.width), Math.round(anim.domain.height), [1])[0];
				anims.push(new layers.InsertDecorRegion(anim.domain, raw_bitmap, physic_mask, bmp, anim.delay));
				
			}
		}
	}

	public function processTips(list: Array<WorldScenes.AnimInfo>) {
		var bmps: Array<BitmapData>;
		for(anim in list)
		{
			if(anim.nlines == null)
				anim.nlines = [1];

			if (anim.source != null)
			{
				bmps = layers.AnimationLayer.extractAnimFromFile("assets/"+anim.source+".jpg", anim.domain, Math.round(anim.domain.width), Math.round(anim.domain.height), anim.nlines);
				
				for(bmp in bmps)
				{
					var bitmap = new Bitmap(bmp);
					bitmap.x = anim.domain.left;
					bitmap.y = anim.domain.top;
					bitmap.name = anim.script;
					tips_layer.pushTip(bitmap);
				}
			}
			else if (anim.script == "inplace")
			{
				tips_layer.pushInplace(anim.domain, anim.delay);
			}

		}
	}

	public function pushAnimations(decorSprite: DisplayObject) {

		for(anim in anims)
		{
			if(anim.sprite != null) //transform coords that were previously set relative to decor bitmap
			{
				var pt: Point = new Point(anim.sprite.x,anim.sprite.y);
				pt=decorSprite.localToGlobal(pt);

				anim.sprite.x = pt.x;
				anim.sprite.y = pt.y;
			}

			layers.AnimationLayer.pushRegion(anim);
		}
	}

	public function processInvisibleConsumables(list: Array<Point>, persistent: Bool) {
		if(list == null)
			return;

		for(pt in list)
			consume_layer.addInvisible(pt.x, pt.y, persistent);
	}

	public function attachScript(name: String)
	{
		if(name == null)
			return;

		switch(name)
		{
			case "dialog":
			screen_script = new screen_scripts.DialogScreenScript(consume_layer, raw_bitmap);
			case "racetrackinit":
			screen_script = new screen_scripts.RaceTrackInit();
			case "hospitalsick":
			screen_script = new screen_scripts.HospitalReactToConsume(alive_layer);
		} 
	}

	public function pushInsideDomain(name: String, domain: openfl.geom.Rectangle)
	{
		if(inside_domains == null)
			inside_domains = new Map<String, Rectangle>();
		inside_domains.set(name,domain);
	}

	public function checkInsideDomains(x: Float, y: Float): String
	{
		if(inside_domains == null)
			return null;
		var r: Rectangle;
		var pt = new Point(x,y);
		for(name in inside_domains.keys())
		{
			r = inside_domains.get(name);
			if(r.containsPoint(pt))
				return name;
		}
		return null;
	}

	public function offsetAllSprites()
	{
		if(offset_applied)
			return;

		var dx: Int = Math.round(raw_bitmap.x);
		var dy: Int = Math.round(raw_bitmap.y);
		Sys.println(dx+" "+dy);
		for(a in anims)
		{
			a.offset(dx,dy);
		}

		consume_layer.offsetUnits(dx,dy);
		//alive_layer.offsetUnits(dx,dy);
		tips_layer.offsetUnits(dx, dy);

		offset_applied = true;
	}

	/********** INOUT founctions ***********/

	public function save(force_rewrite: Bool = false) {
		
		Sys.println("save at "+save_dir+" "+tosave_rawbitmap);

		assets.checkDir(save_dir);

		if(raw_bitmap != null && tosave_rawbitmap)
		{
			assets.appendImage(save_dir+FILE_EDITED_DECOR, raw_bitmap.bitmapData, force_rewrite);
		}

		if(physic_mask != null && tosave_physics)
		{
			assets.appendImage(save_dir+FILE_PHYSIC_MASK, physic_mask.toBitmap().bitmapData, force_rewrite);
		}

		if(alive_mask != null && tosave_alive)
		{
			assets.appendImage(save_dir+FILE_ALIVE_MASK, alive_mask_image.bitmapData, force_rewrite);								
		}

		if(alive_layer != null && tosave_alive)
		{
			assets.appendText(save_dir+FILE_ALIVE_LAYER, alive_layer.serialize(), force_rewrite);

			assets.checkDir(save_dir+FOLDER_ALIVE_LAYER);
			for (unit in alive_layer.units)
			{
				assets.appendImage(save_dir+FOLDER_ALIVE_LAYER+"unit_"+unit.id+'.png', unit.im.bitmapData, force_rewrite);
			}									
		}

		if(consumables_mask != null && tosave_consume)
		{
			assets.appendImage(save_dir+FILE_CONSUMABLE_MASK, consumables_mask_image.bitmapData, force_rewrite);								
		}

		if(consume_layer != null && tosave_consume)
		{
			assets.appendText(save_dir+FILE_CONSUMABLE_LAYER, consume_layer.serialize(), force_rewrite);

			assets.checkDir(save_dir+FOLDER_CONSUMABLE_LAYER);
			for (unit in consume_layer.units)
			{
				assets.appendImage(save_dir+FOLDER_CONSUMABLE_LAYER+"unit_"+unit.id+'.png', unit.im.bitmapData, force_rewrite);
			}							
		}

		if(tosave_consume || tosave_physics || tosave_alive || tosave_rawbitmap)
			assets.save();
	}

	public function load(look_for_processed: Bool = true) {

		Sys.println("load at "+save_dir);

		var bmp  = assets.getBitmap(save_dir+FILE_EDITED_DECOR);
		if(bmp != null)
		{
			raw_bitmap = new Bitmap(bmp);
		}
		else{
			raw_bitmap = new Bitmap (Assets.getBitmapData(reference_path));
		}

		if(!look_for_processed)
			return;

		bmp = assets.getBitmap(save_dir+FILE_PHYSIC_MASK);
		if(bmp != null)
			physic_mask = LogicMask.fromBitmap(new Bitmap (bmp), layers.PhysicsLayer.MASK_DOWNSAMPLING_FACTOR);


		bmp = assets.getBitmap(save_dir+FILE_ALIVE_MASK);
		if(bmp != null)
		{
			alive_mask_image = new Bitmap (bmp);
			alive_mask = LogicMask.fromBitmap(alive_mask_image, layers.AliveLayer.MASK_DOWNSAMPLING_FACTOR);
		}

		var txt = assets.getText(save_dir+FILE_ALIVE_LAYER);
		if(txt!=null)
		{
			alive_layer.parseAndLoad(txt,save_dir+FOLDER_ALIVE_LAYER,assets);
		}

		bmp = assets.getBitmap(save_dir+FILE_CONSUMABLE_MASK);
		if(bmp != null)
			consumables_mask = LogicMask.fromBitmap(new Bitmap (bmp),layers.ConsumableLayer.MASK_DOWNSAMPLING_FACTOR);

		txt = assets.getText(save_dir+FILE_CONSUMABLE_LAYER);
		if(txt!=null)
		{
			consume_layer.parseAndLoad(txt,save_dir+FOLDER_CONSUMABLE_LAYER,assets);
		}

	}

	public function writeAliveScripts() {
		assets.checkDir(save_dir);
		if(assets.appendText(save_dir+FILE_ALIVE_SCRIPTS, alive_layer.serializeScriptMapping(), true))
			assets.save();
	}

	public function readAliveScripts() {
		var txt = assets.getText(save_dir+FILE_ALIVE_SCRIPTS);
		if(txt!=null)
		{
			alive_layer.parseScriptMapping(txt);
		}
	}

	public function writeScriptLayer() {
		assets.checkDir(save_dir);
		if(assets.appendImage(save_dir+FILE_SCRIPT_MASK, script_mask.toBitmap().bitmapData, true))
			assets.save();
	}

	public function readScriptLayer() {
		var bmp = assets.getBitmap(save_dir+FILE_SCRIPT_MASK);
		if(bmp != null)
			script_mask = LogicMask.fromBitmap(new Bitmap (bmp), layers.ScriptLayer.MASK_DOWNSAMPLING_FACTOR);
		else
			script_mask = new LogicMask(Math.round(raw_bitmap.width/4), Math.round(raw_bitmap.height/4) , 4);
	}

	/***** access created bitmaps *****/

	public function getRawBitmap():Bitmap {
		return raw_bitmap;
	}

	public function getPhysicMask():LogicMask {
		return physic_mask;
	}

	public function getAliveMask():LogicMask {
		return alive_mask;
	}

	public function getAliveLayer():layers.AliveLayer {
		return alive_layer;
	}

	public function getDeformationLayer():layers.DeformationLayer {
		return deform_layer;
	}

	public function getConsumableLayer():layers.ConsumableLayer {
		return consume_layer;
	}

	public function getScriptMask():LogicMask {
		return script_mask;
	}

	public function getTipsLayer():layers.TipsLayer {
		return tips_layer;
	}

	/***** color filter settings and function *****/

	public static var blackfilter : ColorFilterSetting = {
		df : layers.PhysicsLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,0,0,0), //target color to extract for the image
		tolr : Math.round(Math.pow(30,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var gray1filter : ColorFilterSetting = {
		df : layers.PhysicsLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,70,70,70), //target color to extract for the image
		tolr : Math.round(Math.pow(10,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var gray2filter : ColorFilterSetting = {
		df : layers.PhysicsLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,90,90,90), //target color to extract for the image
		tolr : Math.round(Math.pow(10,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var gray3filter : ColorFilterSetting = {
		df : layers.PhysicsLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,110,110,110), //target color to extract for the image
		tolr : Math.round(Math.pow(20,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var gray4filter : ColorFilterSetting = {
		df : layers.PhysicsLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,130,130,130), //target color to extract for the image
		tolr : Math.round(Math.pow(10,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var gray5filter : ColorFilterSetting = {
		df : layers.PhysicsLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,150,150,150), //target color to extract for the image
		tolr : Math.round(Math.pow(10,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var pinkfilter : ColorFilterSetting = {
		df : layers.AliveLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,205,50,125), //target color to extract for the image
		tolr : Math.round(Math.pow(50,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var pinkfilter_relaxed : ColorFilterSetting = {
		df : layers.AliveLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,205,50,125), //target color to extract for the image
		tolr : Math.round(Math.pow(120,2)) //inclusion radius around the target color in the RGB sapce
	};


	public static var purplefilter : ColorFilterSetting = {
		df : layers.AliveLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,121,34,110), //target color to extract for the image
		tolr : Math.round(Math.pow(60,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var purplefilter_relaxed : ColorFilterSetting = {
		df : layers.AliveLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,121,34,110), //target color to extract for the image
		tolr : Math.round(Math.pow(60,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var purple2filter : ColorFilterSetting = {
		df : layers.AliveLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,67,0,198), //target color to extract for the image
		tolr : Math.round(Math.pow(60,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var purple2filter_relaxed : ColorFilterSetting = {
		df : layers.AliveLayer.MASK_DOWNSAMPLING_FACTOR, //downsample factor of the source image
		tgcol : ARGB.create(255,67,0,198), //target color to extract for the image
		tolr : Math.round(Math.pow(120,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var lbluefilter : ColorFilterSetting = {
		df : 1, //downsample factor of the source image
		tgcol : ARGB.create(255,30,100,200), //target color to extract for the image
		tolr : Math.round(Math.pow(80,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var yellowfilter : ColorFilterSetting = {
		df : 1, //downsample factor of the source image
		tgcol : ARGB.create(255,255,179,92), //target color to extract for the image
		tolr : Math.round(Math.pow(80,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var whitefilter : ColorFilterSetting = {
		df : 1, //downsample factor of the source image
		tgcol : ARGB.create(255,255,255,255), //target color to extract for the image
		tolr : Math.round(Math.pow(50,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var max_closeness:Float = Math.pow(255,1);

	public static function filterColor(bitmapData:BitmapData, fs: ColorFilterSetting):LogicMask
	{
		var mask = new LogicMask(Math.round(bitmapData.width/fs.df), Math.round(bitmapData.height/fs.df), fs.df);
		var include:Int;
		var closeness:Float;
		var color:ARGB;
		var coldist: Float;
		for(x in 0...mask.width) {
			for(y in 0...mask.height) {
				include = 0;
				closeness = max_closeness;
				for(i in 0...fs.df) {
					for(j in 0...fs.df) {
						color = new ARGB(bitmapData.getPixel32((x - 1)*fs.df + i, (y - 1)*fs.df + j));
						if (color.a > 0 )
						{
							coldist = Math.pow(color.r-fs.tgcol.r,2)+Math.pow(color.g-fs.tgcol.g,2)+Math.pow(color.b-fs.tgcol.b,2) - fs.tolr;
							if (coldist < 0)
							{
								include++;
								//Sys.println("col = ("+color.r+", "+color.g+", "+color.b+") diff = "+(Math.pow(color.r-fs.tgcol.r,2)+Math.pow(color.g-fs.tgcol.g,2)+Math.pow(color.b-fs.tgcol.b,2))+" tol = "+fs.tolr);
							
							}
							/*else if (coldist < closeness)
								closeness = coldist;*/
						}
					}
				}
				
				if (include > 0)
					mask.setXY(x,y,255);
				/*else if (closeness < max_closeness) //signal values close to the target color, for region extraction
					mask.setXY(x,y,Math.round(255-closeness));*/
				else
					mask.setXY(x,y,0);
			}
		}
		
		return mask;
	}

	public static function filterColorBMP(bitmapData:BitmapData, fs: ColorFilterSetting):BitmapData
	{
		var bmp2 = new BitmapData(bitmapData.width, bitmapData.height);
		var color:ARGB;
		for(x in 0...bmp2.width) {
			for(y in 0...bmp2.height) {
				color = new ARGB(bitmapData.getPixel32(x, y));
				if (color.a > 0 && Math.pow(color.r-fs.tgcol.r,2)+Math.pow(color.g-fs.tgcol.g,2)+Math.pow(color.b-fs.tgcol.b,2) < fs.tolr)
					bmp2.setPixel32(x,y,color);
				else
					bmp2.setPixel32(x,y,0);
			}
		}
		
		//var bitmap2 = new Bitmap(bitmapData2);
		return bmp2;
	}

	public static function extractColorBMP(bitmapData:BitmapData, fs: ColorFilterSetting, region: Rectangle):BitmapData
	{
		var color:ARGB;
		var xb: Int = Math.round(region.x);
		var xw: Int = Math.round(region.width);
		var yb: Int = Math.round(region.y);
		var yh: Int = Math.round(region.height);
		var bmp2 = new BitmapData(xw, yh);
		for(x in 0...xw) {
			for(y in 0...yh) {
				color = new ARGB(bitmapData.getPixel32(xb+x, yb+y));
				if (color.a > 0 && Math.pow(color.r-fs.tgcol.r,2)+Math.pow(color.g-fs.tgcol.g,2)+Math.pow(color.b-fs.tgcol.b,2) < fs.tolr)
					{
					bmp2.setPixel32(x,y,color);
					bitmapData.setPixel32(xb+x,yb+y,0xFFFFFFFF);//layers.RandomPaperSample.getPixel(x,y));
					}
				else
					bmp2.setPixel32(x,y,0);
			}
		}
		
		//var bitmap2 = new Bitmap(bitmapData2);
		return bmp2;
	}

	public static function removeColorBMP(bitmapData:BitmapData, fs: ColorFilterSetting) //:BitmapData
	{
		//var bmp2 = new BitmapData(bitmapData.width, bitmapData.height);
		var color:ARGB;
		for(x in 0...bitmapData.width) {
			for(y in 0...bitmapData.height) {
				color = new ARGB(bitmapData.getPixel32(x, y));
				if (color.a > 0 && Math.pow(color.r-fs.tgcol.r,2)+Math.pow(color.g-fs.tgcol.g,2)+Math.pow(color.b-fs.tgcol.b,2) < fs.tolr)
					bitmapData.setPixel32(x,y,0);
				else
					bitmapData.setPixel32(x,y,color);
			}
		}
		
		//return bmp2;
	}

	public static function MergeFilteredBMP(bitmapData1:BitmapData, bitmapData2:BitmapData):BitmapData
	{
		var color1:ARGB;
		for(x in 0...bitmapData1.width) {
			for(y in 0...bitmapData1.height) {
				color1 = new ARGB(bitmapData1.getPixel32(x, y));
				if (color1.a == 0)
					bitmapData1.setPixel32(x,y,bitmapData2.getPixel32(x, y));
			}
		}
		
		return bitmapData1;
	}

	public static var REJECTED_SMALL_ID : Int = 1;
	public static var REGION_INCLUSION_THRESHOLD : Int = 50;
	public static var INCLUDE_NEIGHBOUR_REGION : Int = 2;
	public static var REGION_BORDERS_EXTEND : Int = 0;


	public static function identifyConnectedPixels(mask: LogicMask)
	{
		var assigned_id: UInt = 2; //id 1 is reserved for player UnitBitmap
		mask.regions = new Array<LogicMask.LogicRegion>();
		var region : LogicMask.LogicRegion;
		for(y in 0...mask.height)
			for(x in 0...mask.width)
			{
				if (mask.getXY(x,y) == 255)
				{
					region = growRegion(mask, new Point(x,y), assigned_id);
					if(region != null)
					{
						assigned_id+=1;
						mask.regions.push(region);
					}
				}
			}
	}

	public static function growRegion(mask: LogicMask, start_point: Point, id: UInt) : LogicMask.LogicRegion
	{
		var conn_pixels : Array<Point> = new Array<Point> ();
		conn_pixels.push(start_point);

		var i: Int = 0;

		var incl_neigh_left: Int;
		var incl_neigh_top: Int;
		var incl_neigh_right: Int;
		var incl_neigh_bottom: Int;


		while (i<conn_pixels.length)
		{

			// include neigbours for the next test

			incl_neigh_left = Math.floor(Math.max(conn_pixels[i].x-INCLUDE_NEIGHBOUR_REGION,0));
			incl_neigh_top = Math.floor(Math.max(conn_pixels[i].y-INCLUDE_NEIGHBOUR_REGION,0));
			incl_neigh_right = Math.floor(Math.min(conn_pixels[i].x+INCLUDE_NEIGHBOUR_REGION,mask.width-1));
			incl_neigh_bottom = Math.floor(Math.min(conn_pixels[i].y+INCLUDE_NEIGHBOUR_REGION,mask.height-1));
			for(x in incl_neigh_left...incl_neigh_right)
			{
				for(y in incl_neigh_top...incl_neigh_bottom)
				{
					if (mask.getXY(x, y) == 255)
					{
						conn_pixels.push(new Point(x,y));
						mask.setXY(x, y, REJECTED_SMALL_ID);//prevent pixel to be included again
					}
				}
			}

			//end condition
			if  (i >= 10000)
				break;
			i =  i + 1;
		}
		

		var reg: LogicMask.LogicRegion = null;
		if(conn_pixels.length > REGION_INCLUSION_THRESHOLD)
		{
			reg = {id : id, left : 9999, right : 0, top : 9999, bottom : 0};
			// browse pixels to assign id
			for (i in 0...conn_pixels.length)
			{
				mask.setXY(Math.floor(conn_pixels[i].x), Math.floor(conn_pixels[i].y), id);
				if(conn_pixels[i].x < reg.left)
					reg.left = Math.floor(conn_pixels[i].x)-REGION_BORDERS_EXTEND;
				if(conn_pixels[i].x > reg.right)
					reg.right = Math.ceil(conn_pixels[i].x)+REGION_BORDERS_EXTEND;
				if(conn_pixels[i].y > reg.bottom)
					reg.bottom = Math.ceil(conn_pixels[i].y)+REGION_BORDERS_EXTEND;
				if(conn_pixels[i].y < reg.top)
					reg.top = Math.floor(conn_pixels[i].y)-REGION_BORDERS_EXTEND;
			}
		}

		return reg;
	}

}