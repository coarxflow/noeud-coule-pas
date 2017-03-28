import openfl.utils.ByteArray;

import lime.utils.AssetManifest;
import lime.utils.AssetType;
import lime.utils.Assets;
import lime.utils.AssetLibrary;

import sys.io.File;
import sys.FileSystem;

import haxe.io.Bytes;

class ExtendedAssetManifest {

	public static function loadManifest(path: String): ExtendedAssetManifest
	{
		if(FileSystem.exists(path))
		{
			var eam : ExtendedAssetManifest = new ExtendedAssetManifest();
			eam.manifest = AssetManifest.fromFile(path);
			eam.library = AssetLibrary.fromManifest(eam.manifest);
			Assets.registerLibrary(path,eam.library); //ineffective
			return eam;
		}
		else
		{
			return null;
		}

	}

	public static function create(base_dir: String): ExtendedAssetManifest
	{
		var eam : ExtendedAssetManifest = new ExtendedAssetManifest();
		eam.manifest = new AssetManifest();
		eam.manifest.name = base_dir;
		eam.library = new AssetLibrary();
		return eam;
	}

	private var manifest: AssetManifest;
	private var library: AssetLibrary; //as loaded from manifest

	public function new() {};

	public function appendAsset(path: String, type: AssetType) : Bool
	{

		if(!library.exists(path, type))
		{

			var entry: Dynamic = {};
			entry.path = path;
			entry.type = type;
			entry.id = path;

			manifest.assets.push(entry);
		}

		//check if file really exists
		return FileSystem.exists(chkSep(manifest.name+path));
	}

	public function appendImage(path: String, bmp: openfl.display.BitmapData, force_rewrite: Bool = true)
	{

		var exists = appendAsset(path, AssetType.IMAGE);

		if(force_rewrite || !exists)
		{
			var b:ByteArray = bmp.encode(bmp.rect, new openfl.display.PNGEncoderOptions ());
			path = chkSep(manifest.name+path);
			var fo = File.write(path, true);
			fo.writeString(b.toString());
			fo.close();
		}
	}

	public function appendText(path: String, txt:String, force_rewrite: Bool = true) : Bool
	{
		var exists = appendAsset(path, AssetType.TEXT);

		if(force_rewrite || !exists)
		{
			path = chkSep(manifest.name+path);
			var fo = File.write(path, false);
			fo.writeString(txt);
			fo.close();
		}

		return exists;
	}

	public function getBitmap(id: String) : openfl.display.BitmapData
	{
		if(library != null && library.exists(id, AssetType.IMAGE))
		{
			return openfl.display.BitmapData.fromFile(chkSep(manifest.name+id));
		}
		return null;
	}

	public function getText(id: String) : String
	{
		if(library != null && library.exists(id, AssetType.TEXT))
		{
			var fi = File.read(chkSep(manifest.name+id), false);
			var b: Bytes = fi.readAll();
			fi.close();
			return b.toString();
		}
		return null;
	}

	public function checkDir(path: String)
	{
		if(!FileSystem.exists(manifest.name+path))
			FileSystem.createDirectory(manifest.name+path);
	}

	public static function chkSep(path: String) : String
	{
		#if windows
		path = StringTools.replace(path,'/', '\\');
		#end
		return path;
	}

	public function save()
	{
		var fo = File.write(manifest.name+'manifest', true);
		fo.writeString(manifest.serialize());
		fo.close();
	}
}