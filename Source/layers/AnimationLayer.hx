package layers;

class AnimationLayer {

	static var applylist : Array<AnimatedRegion> = new Array<AnimatedRegion>();

	public static var main: Main;

	public static function frameApplyAll()
	{
		for(idr in applylist)
			idr.insertStep();

		var idx : Int = applylist.length-1;
		while(idx >= 0)
		{
			if(applylist[idx].complete)
			{
				if(applylist[idx].add_to_scene)
					main.removeChild(applylist[idx].sprite);
				applylist.remove(applylist[idx]);
			}
			idx--;
		}
	}

	public static function clearList()
	{
		var idx : Int = applylist.length-1;
		while(idx >= 0)
		{
			if(applylist[idx].add_to_scene)
				main.removeChild(applylist[idx].sprite);
			applylist.remove(applylist[idx]);
			idx--;
		}
	}

	public static function pushRegion(idr: AnimatedRegion)
	{
		applylist.push(idr);
		if(idr.add_to_scene)
			main.addChild(idr.sprite);
	}
	
}