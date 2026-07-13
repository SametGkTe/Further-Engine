package mikolka.funkin.freeplay;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;

class FreeplayStyle
{
  public final id:String;

  public final _data:FreeplayStyleData;

  public function new(id:String,data:FreeplayStyleData)
  {
    this.id = id;
    this._data = data;

    if (_data == null)
    {
      throw 'Could not parse freeplay data for id: $id';
    }
  }

  public function getBgAssetGraphic():FlxGraphic
  {
    return FlxG.bitmap.add(Paths.image(getBgAssetKey()));
  }

  public function getBgAssetKey():String
  {
    return _data.bgAsset;
  }

  public function getSelectorAssetKey():String
  {
    return _data.selectorAsset;
  }

  public function getCapsuleAssetKey():String
  {
    return _data.capsuleAsset;
  }

  public function getNumbersAssetKey():String
  {
    return _data.numbersAsset;
  }

  public function getCapsuleDeselCol():FlxColor
  {
    return FlxColor.fromString(_data.capsuleTextColors[0]);
  }

  public function getStartDelay():Float
  {
    return _data.startDelay;
  }

  public function toString():String
  {
    return 'Style($id)';
  }

	  public function getCapsuleSelCol():FlxColor
	  {
		return FlxColor.fromString(_data.capsuleTextColors[1]);
	  }

  public function destroy():Void {}
}
