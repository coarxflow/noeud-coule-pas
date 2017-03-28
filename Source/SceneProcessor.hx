import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.Graphics;
import openfl.display.DisplayObject;
import openfl.Assets;
import openfl.geom.Point;

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

	//scene layers and masks attributes
	var raw_bitmap:Bitmap;

	var physic_bitmap:Bitmap;
	var physic_mask:LogicMask;

	var alive_mask:LogicMask;
	var alive_layer:AliveLayer;

	var deform_layer:layers.DeformationLayer;

	var consumables_mask:LogicMask;
	var consume_layer:layers.ConsumableLayer;

	var anims: Array<layers.AnimatedRegion>;

	public function new(path:String) {

		reference_path = path;

		var dirs = reference_path.split('/');
		filename = dirs[dirs.length-1].split('.')[0];
		save_dir = filename + '/';
	}

	public function process(create_consume_layer: Bool) {

		
		if(alive_layer == null)
		{
			alive_mask = filterColor(raw_bitmap.bitmapData, pinkfilter);
			alive_mask.blendIn(filterColor(raw_bitmap.bitmapData, purplefilter));
			identifyConnectedPixels(alive_mask);

			alive_layer = new AliveLayer();
			alive_layer.extractRegions(alive_mask, raw_bitmap, filename);
			alive_layer.x = raw_bitmap.x;
			alive_layer.y = raw_bitmap.y;
		}


		if(physic_mask == null)
		{
			physic_mask = filterColor(raw_bitmap.bitmapData, grayfilter);
			physic_mask.dilate(LogicMask.DISK_SE);
			physic_mask.erode(LogicMask.DISK_SE);
		}

		if(consume_layer == null)
		{
			consume_layer = new layers.ConsumableLayer();
			consume_layer.x = raw_bitmap.x;
			consume_layer.y = raw_bitmap.y;
			Sys.println("cons "+create_consume_layer);
			if(create_consume_layer)
			{
				consumables_mask = filterColor(raw_bitmap.bitmapData, yellowfilter);
				identifyConnectedPixels(consumables_mask);

				consume_layer.extractRegions(consumables_mask, raw_bitmap);
			}
		}


	}

	public function initLayers() {
		deform_layer = new layers.DeformationLayer();
	}

	public function processAnimations(list: Array<WorldScenes.AnimInfo>) {
		anims = new Array<layers.AnimatedRegion> ();

		for(anim in list)
		{
			var bmp: BitmapData = new BitmapData(Math.round(anim.domain.width),Math.round(anim.domain.height));
			bmp.copyPixels(raw_bitmap.bitmapData, anim.domain, new Point(0,0));

			switch(anim.script)
			{
				case "rotating-clock":
				anims.push(new layers.RotatingClock(anim.domain, bmp));
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

	public function processInvisibleConsumables(list: Array<Point>) {
		for(pt in list)
			consume_layer.addInvisible(pt.x, pt.y);
	}

	public function save(force_rewrite: Bool = false) {
		
		Sys.println("save at "+save_dir);

		assets.checkDir(save_dir);

		if(raw_bitmap != null)
		{
			assets.appendImage(save_dir+FILE_EDITED_DECOR, raw_bitmap.bitmapData, force_rewrite);
		}

		if(physic_mask != null)
		{
			assets.appendImage(save_dir+FILE_PHYSIC_MASK, physic_mask.toBitmap().bitmapData, force_rewrite);
		}

		if(alive_mask != null)
		{
			assets.appendImage(save_dir+FILE_ALIVE_MASK, alive_mask.toBitmap().bitmapData, force_rewrite);								
		}

		if(alive_layer != null)
		{
			assets.appendText(save_dir+FILE_ALIVE_LAYER, alive_layer.serialize(), force_rewrite);

			assets.checkDir(save_dir+FOLDER_ALIVE_LAYER);
			for (unit in alive_layer.units)
			{
				assets.appendImage(save_dir+FOLDER_ALIVE_LAYER+"unit_"+unit.id+'.png', unit.im.bitmapData, force_rewrite);
			}									
		}

		assets.save();
	}

	public function load() {

		Sys.println("load at "+save_dir);

		var bmp  = assets.getBitmap(save_dir+FILE_EDITED_DECOR);
		if(bmp != null)
		{
			raw_bitmap = new Bitmap(bmp);
		}
		else{
			raw_bitmap = new Bitmap (Assets.getBitmapData(reference_path));
		}


		bmp = assets.getBitmap(save_dir+FILE_PHYSIC_MASK);
		if(bmp != null)
			physic_mask = LogicMask.fromBitmap(new Bitmap (bmp));


		var txt = assets.getText(save_dir+FILE_ALIVE_LAYER);
		if(txt!=null)
		{
			alive_layer = new AliveLayer();
			alive_layer.parseAndLoad(txt,save_dir+FOLDER_ALIVE_LAYER,assets);
		}

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

	public function getAliveLayer():AliveLayer {
		return alive_layer;
	}

	public function getDeformationLayer():layers.DeformationLayer {
		return deform_layer;
	}

	public function getConsumableLayer():layers.ConsumableLayer {
		return consume_layer;
	}

	/***** color filter settings and function *****/

	public static var blackfilter : ColorFilterSetting = {
		df : 1, //downsample factor of the source image
		tgcol : ARGB.create(255,0,0,0), //target color to extract for the image
		tolr : Math.round(Math.pow(120,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var grayfilter : ColorFilterSetting = {
		df : 4, //downsample factor of the source image
		tgcol : ARGB.create(255,100,100,100), //target color to extract for the image
		tolr : Math.round(Math.pow(80,2)) //inclusion radius around the target color in the RGB sapce
	};

	public static var pinkfilter : ColorFilterSetting = {
		df : 1, //downsample factor of the source image
		tgcol : ARGB.create(255,205,50,125), //target color to extract for the image
		tolr : Math.round(Math.pow(60,2)) //inclusion radius around the target color in the RGB sapce
	};


	public static var purplefilter : ColorFilterSetting = {
		df : 1, //downsample factor of the source image
		tgcol : ARGB.create(255,121,34,110), //target color to extract for the image
		tolr : Math.round(Math.pow(60,2)) //inclusion radius around the target color in the RGB sapce
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

	public static function filterColor(bitmapData:BitmapData, fs: ColorFilterSetting):LogicMask
	{
		//var bitmapData2 = new BitmapData (Math.round(bitmap.bitmapData.width/fs.df), Math.round(bitmap.bitmapData.height/fs.df), true, 0xFFFFFFFF);
		var mask = new LogicMask(Math.round(bitmapData.width/fs.df), Math.round(bitmapData.height/fs.df), fs.df);
		var include:Int;
		var color:ARGB;
		for(x in 0...mask.width) {
			for(y in 0...mask.height) {
				include = 0;
				for(i in 0...fs.df) {
					for(j in 0...fs.df) {
						color = new ARGB(bitmapData.getPixel32((x - 1)*fs.df + i, (y - 1)*fs.df + j));
						if (color.a > 0 && Math.pow(color.r-fs.tgcol.r,2)+Math.pow(color.g-fs.tgcol.g,2)+Math.pow(color.b-fs.tgcol.b,2) < fs.tolr)
							include++;
					}
				}
				// if (include > 0)
				// 	bitmapData2.setPixel(x,y,ARGB.create(255,255,255,255));
				// else
				// 	bitmapData2.setPixel(x,y,ARGB.create(255,0,0,0));
				if (include > 0)
					mask.setXY(x,y,255);
				else
					mask.setXY(x,y,0);
			}
		}
		
		//var bitmap2 = new Bitmap(bitmapData2);
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

	public static var REJECTED_SMALL_ID : Int = 1;
	public static var REGION_INCLUSION_THRESHOLD : Int = 100;
	public static var REGION_BORDERS_EXTEND : Int = 5;


	public static function identifyConnectedPixels(mask: LogicMask)
	{
		var assigned_id: UInt = 2;
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
		var test_pixels : Array<Point> = new Array<Point> ();
		test_pixels.push(start_point);
		var next_test_pixels : Array<Point>;

		var flag: Bool = true;
		var nLoops: Int = 0;

		while (flag)
		{

			nLoops =  nLoops + 1;
			next_test_pixels = new Array<Point> ();

			// browse pixels to test
			for (i in 0...test_pixels.length)
			{
				// has pixel not been processed yet?
				conn_pixels.push(test_pixels[i]); //puttting it there remove many holes
				if (mask.getXY(Math.floor(test_pixels[i].x), Math.floor(test_pixels[i].y)) == 255)
				{
					mask.setXY(Math.floor(test_pixels[i].x), Math.floor(test_pixels[i].y), REJECTED_SMALL_ID);
					//conn_pixels.push(test_pixels[i]);
					// include neigbours for the next test
					if (test_pixels[i].y < mask.height-1)
						next_test_pixels.push(new Point(test_pixels[i].x, test_pixels[i].y+1));
					if (test_pixels[i].x < mask.width-1)
						next_test_pixels.push(new Point(test_pixels[i].x+1, test_pixels[i].y));
					if (test_pixels[i].y > 0)
						next_test_pixels.push(new Point(test_pixels[i].x, test_pixels[i].y-1));
					if (test_pixels[i].x > 0)
						next_test_pixels.push(new Point(test_pixels[i].x-1, test_pixels[i].y));
				}
			}

			//end condition
			if  (nLoops >= 800 || next_test_pixels.length < 1)
				flag = false;

			test_pixels = next_test_pixels;
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