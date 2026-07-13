package mikolka.vslice.results;

@:forward
abstract Tallies(RawTallies)
{
  public function new()
  {
    this =
      {
        combo: 0,
        missed: 0,
        shit: 0,
        bad: 0,
        good: 0,
        sick: 0,
        totalNotes: 0,
        totalNotesHit: 0,
        maxCombo: 0,
        score: 0,
        isNewHighscore: false
      }
  }
}

typedef RawTallies =
{
  var combo:Int;

  var missed:Int;

  var shit:Int;
  var bad:Int;
  var good:Int;
  var sick:Int;
  var maxCombo:Int;

  var score:Int;

  var isNewHighscore:Bool;

  var totalNotesHit:Int;

  var totalNotes:Int;
}
typedef SaveScoreData =
{
  var score:Int;
  var accPoints:Float; 

  var sick:Int;
  var good:Int;
  var bad:Int;
  var shit:Int;
  var missed:Int;
  var combo:Int;
  var maxCombo:Int;
  var totalNotesHit:Int;
  var totalNotes:Int;
}