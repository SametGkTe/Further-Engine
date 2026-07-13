package mobile.backend;

#if ios
import lime.system.System;
import lime.system.Orientation;
#end
import lime.math.Rectangle;

class ScreenUtil
{
  public static function getNotchRect():Rectangle
  {
    final notchRect:Rectangle = new Rectangle();

    #if android
    notchRect.x = 0;
    notchRect.y = 0;
    notchRect.width = 0;
    notchRect.height = 0;

    #elseif ios
    var topInset:Float = -1;
    var leftInset:Float = -1;
    var rightInset:Float = -1;
    var bottomInset:Float = -1;
    var deviceWidth:Float = -1;
    var deviceHeight:Float = -1;
    var displayOrientation:Orientation = System.getDisplay(0).orientation;

    topInset = 0;
    bottomInset = 0;
    leftInset = 0;
    rightInset = 0;
    deviceWidth = 0;
    deviceHeight = 0;

    notchRect.x = 0;
    notchRect.y = 0.0;

    switch (displayOrientation)
    {
      case LANDSCAPE:
        notchRect.width = leftInset + rightInset;
        notchRect.height = bottomInset - topInset;
        notchRect.y = topInset;
      case LANDSCAPE_FLIPPED:
        notchRect.width = leftInset + rightInset;
        notchRect.height = bottomInset - topInset;
        notchRect.y = topInset;
        notchRect.x = deviceWidth - notchRect.width;
      case PORTRAIT:
        notchRect.width = deviceWidth;
        notchRect.height = topInset;
      case PORTRAIT_FLIPPED:
        notchRect.width = deviceWidth;
        notchRect.height = bottomInset;
        notchRect.y = deviceHeight - notchRect.height;
      default:
    }
    #end

    return notchRect;
  }
}