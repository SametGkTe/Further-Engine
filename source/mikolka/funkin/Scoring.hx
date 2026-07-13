package mikolka.funkin;

import mikolka.vslice.results.Tallies.SaveScoreData;
#if LEGACY_PSYCH
import Highscore;
#else
import backend.Highscore; 
#end
enum abstract ScoringSystem(String)
{
	var LEGACY;

	var WEEK7;

	var PBOT1;
}

class Scoring
{
	public static function calculateRankForSong(formattedSngName:String):Null<ScoringRank>
		{
			if (!Highscore.songScores.exists(formattedSngName) || !Highscore.songRating.exists(formattedSngName))
				return null;
			var sngScore = Highscore.songScores.get(formattedSngName);
			var sngAccuracy = Highscore.songRating.get(formattedSngName);
			var sngFC = Highscore.songFCState.get(formattedSngName);
			return Scoring.calculateRankFromData(sngScore, sngAccuracy, sngFC);
		}

	public static function calculateRankFromData(sngScore:Int, sngAccuracy:Float, sngFC:Bool):Null<ScoringRank>{

		if (sngScore == 0)
			return null;

		var isPerfectGold = sngAccuracy >= 1;
		if (isPerfectGold)
		{
			return ScoringRank.PERFECT_GOLD;
		}


		if (sngFC)
		{
			return ScoringRank.PERFECT;
		}
		else if (sngAccuracy >= 0.90)
		{
			return ScoringRank.EXCELLENT;
		}
		else if (sngAccuracy >= 0.80)
		{
			return ScoringRank.GREAT;
		}
		else if (sngAccuracy >= 0.60)
		{
			return ScoringRank.GOOD;
		}
		else
		{
			return ScoringRank.SHIT;
		}
	}
	public static function calculateRank(scoreData:SaveScoreData):Null<ScoringRank>
	{ 
		var sngScore:Int = scoreData.score;
		var sngAccuracy:Float = Math.min(1,scoreData.accPoints/scoreData.totalNotesHit);
		var sngFC:Bool = scoreData.missed+scoreData.bad+scoreData.shit == 0;
		if(scoreData.totalNotesHit == 0) sngAccuracy = 0;
		return calculateRankFromData(sngScore,sngAccuracy,sngFC);
		
	}
}

enum abstract ScoringRank(String)
{
	var PERFECT_GOLD;
	var PERFECT;
	var EXCELLENT;
	var GREAT;
	var GOOD;
	var SHIT;

	static function getValue(rank:Null<ScoringRank>):Int
	{
		if (rank == null)
			return -1;
		switch (rank)
		{
			case PERFECT_GOLD:
				return 5;
			case PERFECT:
				return 4;
			case EXCELLENT:
				return 3;
			case GREAT:
				return 2;
			case GOOD:
				return 1;
			case SHIT:
				return 0;
			default:
				return -1;
		}
	}

	@:op(A > B) static function compareGT(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
	{
		if (a != null && b == null)
			return true;
		if (a == null || b == null)
			return false;

		var temp1:Int = getValue(a);
		var temp2:Int = getValue(b);

		return temp1 > temp2;
	}

	@:op(A >= B) static function compareGTEQ(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
	{
		if (a != null && b == null)
			return true;
		if (a == null || b == null)
			return false;

		var temp1:Int = getValue(a);
		var temp2:Int = getValue(b);

		return temp1 >= temp2;
	}

	@:op(A < B) static function compareLT(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
	{
		if (a != null && b == null)
			return true;
		if (a == null || b == null)
			return false;

		var temp1:Int = getValue(a);
		var temp2:Int = getValue(b);

		return temp1 < temp2;
	}

	@:op(A <= B) static function compareLTEQ(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
	{
		if (a != null && b == null)
			return true;
		if (a == null || b == null)
			return false;

		var temp1:Int = getValue(a);
		var temp2:Int = getValue(b);

		return temp1 <= temp2;
	}


	public function getMusicDelay():Float
	{
		switch (abstract)
		{
			case PERFECT_GOLD | PERFECT:
				return 95 / 24;
			case EXCELLENT:
				return 0;
			case GREAT:
				return 5 / 24;
			case GOOD:
				return 3 / 24;
			case SHIT:
				return 2 / 24;
			default:
				return 3.5;
		}
	}

	public function getBFDelay():Float
	{
		switch (abstract)
		{
			case PERFECT_GOLD | PERFECT:
				return 95 / 24;
			case EXCELLENT:
				return 97 / 24;
			case GREAT:
				return 95 / 24;
			case GOOD:
				return 95 / 24;
			case SHIT:
				return 95 / 24;
			default:
				return 3.5;
		}
	}

	public function getFlashDelay():Float
	{
		switch (abstract)
		{
			case PERFECT_GOLD | PERFECT:
				return 129 / 24;
			case EXCELLENT:
				return 122 / 24;
			case GREAT:
				return 109 / 24;
			case GOOD:
				return 107 / 24;
			case SHIT:
				return 186 / 24;
			default:
				return 3.5;
		}
	}

	public function getHighscoreDelay():Float
	{
		switch (abstract)
		{
			case PERFECT_GOLD | PERFECT:
				return 140 / 24;
			case EXCELLENT:
				return 140 / 24;
			case GREAT:
				return 129 / 24;
			case GOOD:
				return 127 / 24;
			case SHIT:
				return 207 / 24;
			default:
				return 3.5;
		}
	}

	public function getMusicPath():String
	{
		switch (abstract)
		{
			case PERFECT_GOLD:
				return 'resultsPERFECT';
			case PERFECT:
				return 'resultsPERFECT';
			case EXCELLENT:
				return 'resultsEXCELLENT';
			case GREAT:
				return 'resultsNORMAL';
			case GOOD:
				return 'resultsNORMAL';
			case SHIT:
				return 'resultsSHIT';
			default:
				return 'resultsNORMAL';
		}
	}

	public function hasMusicIntro():Bool
	{
		switch (abstract)
		{
			case EXCELLENT:
				return true;
			case SHIT:
				return true;
			default:
				return false;
		}
	}

	public function getFreeplayRankIconAsset():Null<String>
	{
		switch (abstract)
		{
			case PERFECT_GOLD:
				return 'PERFECTSICK';
			case PERFECT:
				return 'PERFECT';
			case EXCELLENT:
				return 'EXCELLENT';
			case GREAT:
				return 'GREAT';
			case GOOD:
				return 'GOOD';
			case SHIT:
				return 'LOSS';
			default:
				return null;
		}
	}

	public function shouldMusicLoop():Bool
	{
		switch (abstract)
		{
			case PERFECT_GOLD | PERFECT | EXCELLENT | GREAT | GOOD:
				return true;
			case SHIT:
				return false;
			default:
				return false;
		}
	}

	public function getHorTextAsset()
	{
		switch (abstract)
		{
			case PERFECT_GOLD:
				return 'resultScreen/rankText/rankScrollPERFECT';
			case PERFECT:
				return 'resultScreen/rankText/rankScrollPERFECT';
			case EXCELLENT:
				return 'resultScreen/rankText/rankScrollEXCELLENT';
			case GREAT:
				return 'resultScreen/rankText/rankScrollGREAT';
			case GOOD:
				return 'resultScreen/rankText/rankScrollGOOD';
			case SHIT:
				return 'resultScreen/rankText/rankScrollLOSS';
			default:
				return 'resultScreen/rankText/rankScrollGOOD';
		}
	}

	public function getVerTextAsset()
	{
		switch (abstract)
		{
			case PERFECT_GOLD:
				return 'resultScreen/rankText/rankTextPERFECT';
			case PERFECT:
				return 'resultScreen/rankText/rankTextPERFECT';
			case EXCELLENT:
				return 'resultScreen/rankText/rankTextEXCELLENT';
			case GREAT:
				return 'resultScreen/rankText/rankTextGREAT';
			case GOOD:
				return 'resultScreen/rankText/rankTextGOOD';
			case SHIT:
				return 'resultScreen/rankText/rankTextLOSS';
			default:
				return 'resultScreen/rankText/rankTextGOOD';
		}
	}
}
