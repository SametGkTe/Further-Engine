package mikolka.funkin.players;

import mikolka.funkin.Scoring.ScoringRank;
import mikolka.funkin.players.PlayerData.PlayerResultsAnimationData;
import mikolka.funkin.players.PlayerData.PlayerCharSelectData;
import mikolka.funkin.players.PlayerData.PlayerFreeplayDJData;

@:nullSafety
class PlayableCharacter
{

  public final _data:Null<PlayerData>;

  public function new(data:PlayerData)
  {
    _data = data;
  }

  public function getName():String
  {
    return _data?.name ?? "Unknown";
  }

  public function getOwnedCharacterIds():Array<String>
  {
    return _data?.ownedChars ?? [];
  }

  public function shouldShowUnownedChars():Bool
  {
    return _data?.showUnownedChars ?? false;
  }

  public function shouldShowCharacter(id:String):Bool
  {
    if (getOwnedCharacterIds().contains(id))
    {
      return true;
    }

    if (shouldShowUnownedChars())
    {
      var result = !PlayerRegistry.instance.isCharacterOwned(id);
      return result;
    }

    return false;
  }

  public function getFreeplayStyleID():String
  {
    return _data?.freeplayStyle ?? Constants.DEFAULT_FREEPLAY_STYLE;
  }

  public function getFreeplayDJData():Null<PlayerFreeplayDJData>
  {
    return _data?.freeplayDJ;
  }

  public function getFreeplayDJText(index:Int):String
  {
    return _data?.freeplayDJ?.getFreeplayDJText(index) ?? 'GET FREAKY ON A FRIDAY';
  }

  public function getCharSelectData():Null<PlayerCharSelectData>
  {
    return _data?.charSelect;
  }

  public function getResultsAnimationDatas(rank:ScoringRank):Array<PlayerResultsAnimationData>
  {
    if (_data == null || _data.results == null)
    {
      return [];
    }

    switch (rank)
    {
      case PERFECT | PERFECT_GOLD:
        return _data.results.perfect;
      case EXCELLENT:
        return _data.results.excellent;
      case GREAT:
        return _data.results.great;
      case GOOD:
        return _data.results.good;
      case SHIT:
        return _data.results.loss;
    }
  }

  public function getResultsMusicPath(rank:ScoringRank):String
  {
    switch (rank)
    {
      case PERFECT_GOLD:
        return _data?.results?.music?.PERFECT_GOLD ?? "resultsPERFECT";
      case PERFECT:
        return _data?.results?.music?.PERFECT ?? "resultsPERFECT";
      case EXCELLENT:
        return _data?.results?.music?.EXCELLENT ?? "resultsEXCELLENT";
      case GREAT:
        return _data?.results?.music?.GREAT ?? "resultsNORMAL";
      case GOOD:
        return _data?.results?.music?.GOOD ?? "resultsNORMAL";
      case SHIT:
        return _data?.results?.music?.SHIT ?? "resultsSHIT";
      default:
        return _data?.results?.music?.GOOD ?? "resultsNORMAL";
    }
  }

  public function isUnlocked():Bool
  {
    return _data?.unlocked ?? true;
  }

  public function destroy():Void {}
}
