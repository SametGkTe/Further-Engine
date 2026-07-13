package mikolka.funkin.utils;
class ArrayTools
{
  public static function pushUnique<T>(input:Array<T>, element:T):Bool
  {
    if (input.contains(element)) return false;
    input.push(element);
    return true;
  }

  public static function pushMany<T>(input:Array<T>, items:Array<T>):Array<T>
  {
    for(x in items){
      input.push(x);
    }
    return input;
  }

  public inline static function clear<T>(array:Array<T>):Void
  {
    array.resize(0);
  }
	public static function findIndex<T>(array:Array<T>, predicate:T->Bool):Int {
		for (i in 0...array.length)
			if (predicate(array[i]))
				return i;
		return -1;
	}
  public static function clone<T>(array:Array<T>):Array<T>
  {
    return [for (element in array) element];
  }

  public static function isEqualUnordered<T>(a:Array<T>, b:Array<T>):Bool
  {
    if (a.length != b.length) return false;
    for (element in a)
    {
      if (!b.contains(element)) return false;
    }
    for (element in b)
    {
      if (!a.contains(element)) return false;
    }
    return true;
  }

}
