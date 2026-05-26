package options;

import states.MainMenuState;
import backend.StageData;

typedef OptionEntry = {
	label:String,
	desc:String,
}

class OptionsState extends MusicBeatState
{
	var entries:Array<OptionEntry> = [
		{ label: 'Note Colors',          desc: 'Nota oklarının renklerini özelleştirin ve ayarlayın!'          },
		{ label: 'Controls',             desc: 'Klavye ve oyun kumandası tuşlarını yeniden atayın'       },
		{ label: 'Adjust Delay & Combo', desc: 'Nota ofsetini ve gecikmeyi ayarlayın'    },
		{ label: 'Graphics',             desc: 'Performans ve işleme ayarları'         },
		{ label: 'Visuals',              desc: 'HUD, efektler ve görsel tercihler'        },
		{ label: 'Gameplay',             desc: 'Ok Stili, Görsel efektleri ayarlayın' },
		#if TRANSLATIONS_ALLOWED
		{ label: 'Language',             desc: 'Dilinizi seçin!'             },
		#end
		{ label: 'Mobile Options',       desc: 'Dokunmatik Kontrol Ayarları'     },
	];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var onPlayState:Bool = false;

	static inline var ITEM_SPACING:Float = 92;
	static inline var TOP_MARGIN:Float = 50;
	static inline var BOTTOM_MARGIN:Float = 90;

	var menuSpacing:Float = 92;

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;
	var descText:FlxText;
	var descBg:FlxSprite;
	var exiting:Bool = false;

	function openSelectedSubstate(label:String)
	{
		FlxG.camera.scroll.set(0, 0);

		if (label != 'Adjust Delay & Combo') {
			removeTouchPad();
			persistentUpdate = false;
			controls.isInSubstate = true;
		}

		switch (label) {
			case 'Note Colors':
				openSubState(new options.NotesColorSubState());

			case 'Controls':
				openSubState(new options.ControlsSubState());

			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());

			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());

			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());

			case 'Adjust Delay & Combo':
				removeTouchPad();
				MusicBeatState.switchState(new options.NoteOffsetState());

			case 'Mobile Options':
				openSubState(new mobile.options.MobileOptionsSubState());

			#if TRANSLATIONS_ALLOWED
			case 'Language':
				openSubState(new options.LanguageSubState());
			#end
		}
	}

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Options Menu', null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (entry in entries) {
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_${entry.label}', entry.label), true);
			grpOptions.add(optionText);
		}

		// Alphabet ile > ve < selectorlar
		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);

		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		// Açıklama arka planı
		descBg = new FlxSprite(0, FlxG.height - 36).makeGraphic(FlxG.width, 36, 0xDD0A0414);
		descBg.scrollFactor.set();
		add(descBg);

		// Açıklama yazısı - vcr.ttf fontu
		descText = new FlxText(0, FlxG.height - 28, FlxG.width, '', 14);
		descText.setFormat('assets/fonts/vcr.ttf', 14, 0xFFea71fd, CENTER, FlxTextBorderStyle.NONE);
		descText.scrollFactor.set();
		descText.antialiasing = ClientPrefs.data.antialiasing;
		add(descText);

		if (controls.mobileC) {
			var tipText:FlxText = new FlxText(150, FlxG.height - 60, 0,
				'Press ' + (FlxG.onMobile ? 'C' : 'CTRL or C') + ' for Mobile Controls', 12);
			tipText.setFormat('assets/fonts/vcr.ttf', 12, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			tipText.borderSize = 1.25;
			tipText.scrollFactor.set();
			tipText.antialiasing = ClientPrefs.data.antialiasing;
			add(tipText);
		}

		layoutOptions();
		changeSelection(0, false);

		ClientPrefs.saveSettings();
		addTouchPad('UP_DOWN', 'A_B_C');

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Options Menu', null);
		#end

		controls.isInSubstate = false;
		removeTouchPad();
		addTouchPad('UP_DOWN', 'A_B_C');
		persistentUpdate = true;

		FlxG.camera.scroll.set(0, 0);
		layoutOptions();
		changeSelection(0, false);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (exiting) return;

		if (controls.UI_UP_P) changeSelection(-1);
		if (controls.UI_DOWN_P) changeSelection(1);

		var mobileControlPressed:Bool = false;

		if (touchPad != null && touchPad.buttonC != null && touchPad.buttonC.justPressed) {
			mobileControlPressed = true;
		}

		if (controls.mobileC && (FlxG.keys.justPressed.CONTROL || FlxG.keys.justPressed.C)) {
			mobileControlPressed = true;
		}

		if (mobileControlPressed) {
			FlxG.camera.scroll.set(0, 0);
			controls.isInSubstate = true;
			persistentUpdate = false;
			openSubState(new mobile.substates.MobileControlSelectSubState());
			return;
		}

		if (controls.BACK) {
			exiting = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));

			if (onPlayState) {
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			} else {
				MusicBeatState.switchState(new MainMenuState());
			}
		}
		else if (controls.ACCEPT) {
			openSelectedSubstate(entries[curSelected].label);
		}

		refreshSelectors();
	}

	function layoutOptions()
	{
		if (grpOptions == null || grpOptions.members == null || grpOptions.members.length == 0) return;

		var visibleTop:Float = TOP_MARGIN;
		var visibleBottom:Float = FlxG.height - BOTTOM_MARGIN;
		var visibleHeight:Float = visibleBottom - visibleTop;

		menuSpacing = ITEM_SPACING;
		if (entries.length > 1) {
			var maxSpacing:Float = visibleHeight / (entries.length - 1);
			if (menuSpacing > maxSpacing) menuSpacing = maxSpacing;
		}

		var totalHeight:Float = (entries.length - 1) * menuSpacing;
		var startY:Float = visibleTop + ((visibleHeight - totalHeight) * 0.5);

		for (num => item in grpOptions.members) {
			if (item == null) continue;
			item.x = (FlxG.width - item.width) * 0.5;
			item.y = startY + (num * menuSpacing);
		}

		refreshSelectors();
	}

	function refreshSelectors()
	{
		if (grpOptions == null || grpOptions.members == null) return;
		if (curSelected < 0 || curSelected >= grpOptions.members.length) return;

		var item = grpOptions.members[curSelected];
		if (item == null) return;

		selectorLeft.x = item.x - 63;
		selectorLeft.y = item.y;

		selectorRight.x = item.x + item.width + 15;
		selectorRight.y = item.y;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, entries.length - 1);

		for (num => item in grpOptions.members) {
			if (item == null) continue;
			item.alpha = (num == curSelected) ? 1 : 0.45;
		}

		if (descText != null) {
			descText.text = entries[curSelected].desc.toUpperCase();
		}

		refreshSelectors();

		if (playSound && change != 0) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}