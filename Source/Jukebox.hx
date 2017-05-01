import openfl.media.Sound;
import openfl.media.SoundChannel;

import openfl.Assets;

class Jukebox {

	public static inline var SOUNDS_DIR: String = "audio/";
	public static inline var SOUNDS_EXT: String = ".ogg";

	static var loaded_sounds : Array<Sound> = new Array<Sound> ();
	static var loaded_sounds_paths : Array<String> = new Array<String> ();

	static var scene_sounds : Array<String>;

	static var crt_sound_channel: SoundChannel;
	static var crt_sound_path: String;

	public static function resetSceneSounds()
	{
		scene_sounds  = new Array<String> ();

		if(crt_sound_channel != null)
		{
			crt_sound_channel.stop();
			Sys.println("stop channel "+crt_sound_channel.toString());
		}
	}

	public static function addSoundForScene(path: String)
	{
		scene_sounds.push(path);

		if(loaded_sounds_paths.indexOf(path) == -1 && crt_sound_path != path)
		{
			var s: Sound = Assets.getMusic(SOUNDS_DIR+path+SOUNDS_EXT);
			loaded_sounds.push(s);
			loaded_sounds_paths.push(path);
		}
	}


	public static function playFromSelection()
	{
		Sys.println("sound selec = "+scene_sounds);

		var rnd_index: Int = Math.floor(Math.random() * scene_sounds.length);

		var p: String = scene_sounds[rnd_index];
		var i: Int = loaded_sounds_paths.indexOf(p);

		crt_sound_path = p;

		Sys.println("choose "+i+" "+p+" "+loaded_sounds[i]);

		if(crt_sound_channel != null)
			crt_sound_channel.stop();
		
		if(i != -1)
			crt_sound_channel = loaded_sounds[i].play(0,8);
		else
			crt_sound_channel = null;

	}

	//sound effects
	public static inline var EFFECTS_DIR: String = "soundeffects/";
	public static inline var EFFECTS_EXT: String = ".ogg";
	static var rushSoundEffect : Sound;
	static var paintSoundEffect : Sound;
	static var crunchSoundEffect : Sound;
	static var crt_sound_channel2 : SoundChannel;
	public static function loadSoundEffects() {
		rushSoundEffect = Assets.getMusic(EFFECTS_DIR+"ripping"+EFFECTS_EXT);
		paintSoundEffect = Assets.getMusic(EFFECTS_DIR+"spray"+EFFECTS_EXT);
		Sys.println("load "+paintSoundEffect);
		crunchSoundEffect = Assets.getMusic(EFFECTS_DIR+"crunch"+EFFECTS_EXT);
	}

	public static function playRippingSound()
	{
		if(rushSoundEffect != null)
		crt_sound_channel2 = rushSoundEffect.play();
	}

	public static function playCrunchSound()
	{
		if(crunchSoundEffect != null)
		crt_sound_channel2 = crunchSoundEffect.play();
	}

	public static function playSpraySound()
	{
		if(paintSoundEffect != null)
		crt_sound_channel2 = paintSoundEffect.play();
	}
}
