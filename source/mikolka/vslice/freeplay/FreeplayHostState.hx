package mikolka.vslice.freeplay;

import mikolka.vslice.StickerSubState;
import mikolka.vslice.states.MainMenuState;
import mikolka.vslice.freeplay.FreeplayState.FreeplayStateParams;

class FreeplayHostState extends MainMenuState
{
	var fpParams:Null<FreeplayStateParams>;
	var fpStickers:Null<StickerSubState>;

	public function new(?params:FreeplayStateParams, ?stickers:StickerSubState)
	{
		super();
		fpParams = params;
		fpStickers = stickers;
	}

	override function create():Void
	{
		super.create();

		persistentUpdate = false;
		persistentDraw = true;

		openSubState(new FreeplayState(fpParams, fpStickers));
	}
}