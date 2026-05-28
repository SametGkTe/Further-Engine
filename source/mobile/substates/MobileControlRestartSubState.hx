package mobile.substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class MobileControlRestartSubState extends MusicBeatSubstate {
    var bg:FlxSprite;
    var msgText:FlxText;
    var yesText:FlxText;
    var noText:FlxText;
    var selected:Int = 0;

    override function create() {
        super.create();

        // Dim
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        bg.alpha = 0;
        bg.scrollFactor.set();
        add(bg);
        FlxTween.tween(bg, {alpha: 0.7}, 0.3);

        // Mesaj
        msgText = new FlxText(0, 0, FlxG.width - 100, '', 24);
        msgText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
        msgText.text = "Kontrol tipi degistirildi.\nOyunun yeniden baslatilmasi gerekiyor.\n\nSimdi yeniden baslatilsin mi?";
        msgText.screenCenter();
        msgText.y -= 40;
        msgText.scrollFactor.set();
        msgText.alpha = 0;
        add(msgText);
        FlxTween.tween(msgText, {alpha: 1}, 0.3, {startDelay: 0.1});

        // Evet
        yesText = new FlxText(0, msgText.y + msgText.height + 30, FlxG.width / 2, 'EVET', 22);
        yesText.setFormat(Paths.font("vcr.ttf"), 22, 0xFF22c55e, CENTER);
        yesText.scrollFactor.set();
        yesText.alpha = 0;
        add(yesText);
        FlxTween.tween(yesText, {alpha: 1}, 0.3, {startDelay: 0.15});

        // Hayır
        noText = new FlxText(FlxG.width / 2, msgText.y + msgText.height + 30, FlxG.width / 2, 'HAYIR', 22);
        noText.setFormat(Paths.font("vcr.ttf"), 22, 0xFFef4444, CENTER);
        noText.scrollFactor.set();
        noText.alpha = 0;
        add(noText);
        FlxTween.tween(noText, {alpha: 1}, 0.3, {startDelay: 0.15});

        updateSelection();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
            selected = selected == 0 ? 1 : 0;
            FlxG.sound.play(Paths.sound('scrollMenu'));
            updateSelection();
        }

        // Mouse
        if (FlxG.mouse.justPressed) {
            if (FlxG.mouse.overlaps(yesText)) {
                selected = 0;
                updateSelection();
                confirm();
                return;
            }
            if (FlxG.mouse.overlaps(noText)) {
                selected = 1;
                updateSelection();
                confirm();
                return;
            }
        }

        if (controls.ACCEPT) {
            confirm();
        }

        if (controls.BACK) {
            close();
        }
    }

    function updateSelection() {
        if (selected == 0) {
            yesText.setFormat(Paths.font("vcr.ttf"), 26, 0xFF22c55e, CENTER);
            noText.setFormat(Paths.font("vcr.ttf"), 20, 0xFF666666, CENTER);
        } else {
            yesText.setFormat(Paths.font("vcr.ttf"), 20, 0xFF666666, CENTER);
            noText.setFormat(Paths.font("vcr.ttf"), 26, 0xFFef4444, CENTER);
        }
    }

    function confirm() {
        FlxG.sound.play(Paths.sound('confirmMenu'));

        if (selected == 0) {
            // Evet - oyunu yeniden başlat
            ClientPrefs.saveSettings();

            #if sys
            // Uygulamayı yeniden başlat
            var args:Array<String> = [];
            #if windows
            Sys.command('start "" "${Sys.programPath()}"');
            Sys.exit(0);
            #else
            // Android ve diğerleri için
            FlxG.resetGame();
            #end
            #else
            FlxG.resetGame();
            #end
        } else {
            // Hayır - geri dön
            close();
        }
    }
}