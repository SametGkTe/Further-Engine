package mikolka.funkin.freeplay.album;


class AlbumData 
{
  public function new() {}
  public var version:String = "1.0";

  public var name:String = "";

  public var artists:Array<String> = ["Is this even used?"];

  public var albumArtAsset:String;

  public var albumTitleAsset:String;

  public var albumTitleAnimations:Array<AnimationData> = null;
}
