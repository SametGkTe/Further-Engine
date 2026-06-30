package mobile.substates;

import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.FlxG;

class MobileControlSelectSubState extends FlxSubState {
    public function new() {
        super();
        var txt = new FlxText(0, 0, 0, "Customizer is currently disabled\ndue to JSON based controls update.", 32);
        txt.screenCenter();
        add(txt);
    }
    
    override function update(elapsed:Float) {
        super.update(elapsed);
        if (FlxG.keys.justPressed.ESCAPE || FlxG.android.justReleased.BACK) {
            close();
        }
    }
}
