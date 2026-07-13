package mobile.backend;

import flixel.FlxG;

class SwipeUtil {
    public static var swipeDown(get, never):Bool;
    public static var swipeLeft(get, never):Bool;
    public static var swipeRight(get, never):Bool;
    public static var swipeUp(get, never):Bool;
    public static var swipeAny(get, never):Bool;

    public static var locked:Bool = false;

    static function isActive():Bool {
        if (locked) return false;
        return ClientPrefs.data.mobileControlType == 'Touch';
    }

    @:noCompletion
    static function get_swipeDown():Bool {
        if (!isActive()) return false;
        for (swipe in FlxG.swipes)
            return (swipe.degrees > -135 && swipe.degrees < -45 && swipe.distance > 20);
        return false;
    }

    @:noCompletion
    static function get_swipeLeft():Bool {
        if (!isActive()) return false;
        for (swipe in FlxG.swipes)
            return (swipe.degrees > -45 && swipe.degrees < 45 && swipe.distance > 20);
        return false;
    }

    @:noCompletion
    static function get_swipeRight():Bool {
        if (!isActive()) return false;
        for (swipe in FlxG.swipes)
            return ((swipe.degrees > 135 || swipe.degrees < -135) && swipe.distance > 20);
        return false;
    }

    @:noCompletion
    static function get_swipeUp():Bool {
        if (!isActive()) return false;
        for (swipe in FlxG.swipes)
            return (swipe.degrees > 45 && swipe.degrees < 135 && swipe.distance > 20);
        return false;
    }

    @:noCompletion
    static function get_swipeAny():Bool {
        return swipeDown || swipeLeft || swipeRight || swipeUp;
    }
}