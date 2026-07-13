package mikolka.funkin.utils;

class SpriteTools {
    public static function setVisibility(spr:FlxSprite,state:Bool) {
        spr.visible = state;
        spr.animation.paused = state;
    }
}