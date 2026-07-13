package mikolka.funkin.utils;

class StringTools
{
  public static function toTitleCase(value:String):String
  {
    var words:Array<String> = value.split(' ');
    var result:String = '';
    for (i in 0...words.length)
    {
      var word:String = words[i];
      result += word.charAt(0).toUpperCase() + word.substr(1).toLowerCase();
      if (i < words.length - 1)
      {
        result += ' ';
      }
    }
    return result;
  }
}
