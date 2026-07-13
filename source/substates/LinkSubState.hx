package substates;

import backend.Paths;
import backend.ClientPrefs;
import backend.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;

typedef CreditLink =
{
	var type:String;
	var url:String;
	var displayName:String;
};

class LinkSubState extends MusicBeatSubstate
{
	static inline final COL_BG = 0xFF0a0a0a;
	static inline final COL_PANEL = 0xFF1a1a1a;
	static inline final COL_ACCENT = 0xFF888888;
	static inline final COL_TEXT = 0xFFE0E0E0;
	static inline final COL_DIM = 0xFF707070;
	static inline final COL_YES = 0xFF22c55e;
	static inline final COL_NO = 0xFFef4444;
	static inline final COL_BTN = 0xFF222222;
	static inline final COL_BTN_SEL = 0xFF333333;

	static inline final PANEL_W = 500;
	static inline final LINK_ITEM_H = 46;
	static inline final HEADER_H = 70;
	static inline final FOOTER_H = 60;
	static inline final PADDING = 24;

	static var linkTypeNames:Map<String, String> = [
		"youtube" => "YouTube",
		"twitter" => "Twitter / X",
		"x" => "Twitter / X",
		"tiktok" => "TikTok",
		"discord" => "Discord",
		"github" => "GitHub",
		"kofi" => "Ko-fi",
		"instagram" => "Instagram",
		"website" => "Website",
		"twitch" => "Twitch",
		"newgrounds" => "Newgrounds",
		"bsky" => "Bluesky",
		"spotify" => "Spotify",
		"soundcloud" => "SoundCloud",
		"bandcamp" => "Bandcamp",
		"patreon" => "Patreon",
		"link" => "Link"
	];

	static var linkTypeColors:Map<String, FlxColor> = [
		"youtube" => 0xFFFF0000,
		"twitter" => 0xFF1DA1F2,
		"x" => 0xFF1DA1F2,
		"tiktok" => 0xFFFF0050,
		"discord" => 0xFF5865F2,
		"github" => 0xFFFFFFFF,
		"kofi" => 0xFFFF5E5B,
		"instagram" => 0xFFE1306C,
		"website" => 0xFFAAAAAA,
		"twitch" => 0xFF9146FF,
		"newgrounds" => 0xFFFFA500,
		"bsky" => 0xFF0085FF,
		"spotify" => 0xFF1DB954,
		"soundcloud" => 0xFFFF5500,
		"bandcamp" => 0xFF629AA9,
		"patreon" => 0xFFF96854,
		"link" => 0xFFCCCCCC
	];

	var personName:String;
	var links:Array<CreditLink>;
	var curSelected:Int = 0;

	var coolCam:FlxCamera;
	var overlay:FlxSprite;
	var panel:FlxSprite;
	var accentLine:FlxSprite;
	var headerText:FlxText;
	var separatorTop:FlxSprite;
	var separatorBottom:FlxSprite;
	var hintText:FlxText;
	var selectBar:FlxSprite;

	var linkBgs:Array<FlxSprite> = [];
	var linkDots:Array<FlxSprite> = [];
	var linkTexts:Array<FlxText> = [];
	var linkUrlTexts:Array<FlxText> = [];

	var _ready:Bool = false;
	var _closing:Bool = false;

	var panelX:Float = 0;
	var panelY:Float = 0;
	var panelH:Int = 0;

	public static function requestMultiLink(name:String, rawLinkData:String):Void
	{
		var parsedLinks = parseLinkString(rawLinkData);
		if (parsedLinks.length == 0) return;

		if (parsedLinks.length == 1)
		{
			request(
				Language.getPhrase('link_open_prompt', 'Bu bağlantıyı açmak istiyor musunuz?'),
				parsedLinks[0].url,
				function() { CoolUtil.browserLoad(parsedLinks[0].url); }
			);
			return;
		}

		if (FlxG.state.subState != null)
			FlxG.state.subState.close();
		FlxG.state.openSubState(new LinkSubState(name, parsedLinks));
	}

	public static function requestURL(url:String, ?prompt:String):Void
	{
		if (prompt == null)
			prompt = Language.getPhrase('link_open_prompt', 'Bu bağlantıyı açmak istiyor musunuz?');
		request(prompt, url, function() { FlxG.openURL(url); });
	}

	public static function request(prompt:String, url:String, yesCallback:Void->Void, ?noCallback:Void->Void):Void
	{
		if (FlxG.state.subState != null)
			FlxG.state.subState.close();
		FlxG.state.openSubState(new LinkSubStateSingle(prompt, url, yesCallback, noCallback));
	}

	static function parseLinkString(raw:String):Array<CreditLink>
	{
		var result:Array<CreditLink> = [];
		if (raw == null || raw.length < 4) return result;

		if (!raw.contains("::"))
		{
			result.push({type: "link", url: raw, displayName: "Link"});
			return result;
		}

		var parts = raw.split("||");
		for (part in parts)
		{
			var segments = part.split("::");
			if (segments.length >= 2)
			{
				var linkType = segments[0].toLowerCase().trim();
				var linkUrl = segments[1].trim();
				var displayName = linkTypeNames.get(linkType) ?? linkType;
				result.push({type: linkType, url: linkUrl, displayName: displayName});
			}
		}
		return result;
	}

	function new(name:String, parsedLinks:Array<CreditLink>)
	{
		super();
		this.personName = name;
		this.links = parsedLinks;
	}

	override function create()
	{
		super.create();

		coolCam = new FlxCamera();
		coolCam.bgColor.alpha = 0;
		FlxG.cameras.add(coolCam, false);
		cameras = [coolCam];

		var linkCount = links.length;
		panelH = HEADER_H + (linkCount * LINK_ITEM_H) + FOOTER_H + 16;
		panelX = (FlxG.width - PANEL_W) / 2;
		panelY = (FlxG.height - panelH) / 2;

		overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		overlay.scrollFactor.set();
		overlay.alpha = 0;
		add(overlay);

		panel = new FlxSprite(panelX, panelY).makeGraphic(PANEL_W, panelH, COL_PANEL);
		panel.scrollFactor.set();
		panel.alpha = 0;
		add(panel);

		accentLine = new FlxSprite(panelX, panelY).makeGraphic(PANEL_W, 2, COL_ACCENT);
		accentLine.scrollFactor.set();
		accentLine.alpha = 0;
		add(accentLine);

		headerText = new FlxText(panelX + PADDING, panelY + 20, PANEL_W - PADDING * 2, personName, 22);
		headerText.setFormat(Paths.font("vcr.ttf"), 22, COL_TEXT, CENTER);
		headerText.scrollFactor.set();
		headerText.alpha = 0;
		add(headerText);

		var sepY = panelY + HEADER_H;
		separatorTop = new FlxSprite(panelX + PADDING, sepY).makeGraphic(PANEL_W - PADDING * 2, 1, COL_ACCENT);
		separatorTop.scrollFactor.set();
		separatorTop.alpha = 0;
		add(separatorTop);

		selectBar = new FlxSprite(panelX + 8, 0).makeGraphic(PANEL_W - 16, LINK_ITEM_H - 4, COL_BTN_SEL);
		selectBar.scrollFactor.set();
		selectBar.alpha = 0;
		add(selectBar);

		for (i in 0...linkCount)
		{
			var link = links[i];
			var itemY = sepY + 8 + (i * LINK_ITEM_H);
			var typeColor = linkTypeColors.get(link.type) ?? 0xFFCCCCCC;

			var dot = new FlxSprite(panelX + PADDING + 4, itemY + LINK_ITEM_H / 2 - 4).makeGraphic(8, 8, typeColor);
			dot.scrollFactor.set();
			dot.alpha = 0;
			linkDots.push(dot);
			add(dot);

			var nameText = new FlxText(panelX + PADDING + 20, itemY + 4, PANEL_W - PADDING * 2 - 24, link.displayName, 18);
			nameText.setFormat(Paths.font("vcr.ttf"), 18, COL_TEXT, LEFT);
			nameText.scrollFactor.set();
			nameText.alpha = 0;
			linkTexts.push(nameText);
			add(nameText);

			var shortUrl = link.url;
			if (shortUrl.length > 45)
				shortUrl = shortUrl.substr(0, 42) + "...";

			var urlSmall = new FlxText(panelX + PADDING + 20, itemY + 24, PANEL_W - PADDING * 2 - 24, shortUrl, 11);
			urlSmall.setFormat(Paths.font("vcr.ttf"), 11, COL_DIM, LEFT);
			urlSmall.scrollFactor.set();
			urlSmall.alpha = 0;
			linkUrlTexts.push(urlSmall);
			add(urlSmall);
		}

		var bottomSepY = sepY + 8 + (linkCount * LINK_ITEM_H) + 4;
		separatorBottom = new FlxSprite(panelX + PADDING, bottomSepY).makeGraphic(PANEL_W - PADDING * 2, 1, COL_ACCENT);
		separatorBottom.scrollFactor.set();
		separatorBottom.alpha = 0;
		add(separatorBottom);

		hintText = new FlxText(panelX + PADDING, bottomSepY + 12, PANEL_W - PADDING * 2,
			Language.getPhrase('link_hint', 'YUKARI/ASAGI Seç | ENTER Aç | ESC Kapat'), 13);
		hintText.setFormat(Paths.font("vcr.ttf"), 13, COL_DIM, CENTER);
		hintText.scrollFactor.set();
		hintText.alpha = 0;
		add(hintText);

		playOpenAnim();
	}

	function playOpenAnim():Void
	{
		FlxTween.tween(overlay, {alpha: 0.6}, 0.2);

		panel.scale.set(0.93, 0.93);
		FlxTween.tween(panel, {alpha: 1}, 0.2);
		FlxTween.tween(panel.scale, {x: 1, y: 1}, 0.25, {ease: FlxEase.backOut});

		FlxTween.tween(accentLine, {alpha: 0.7}, 0.2, {startDelay: 0.05});
		FlxTween.tween(headerText, {alpha: 1}, 0.2, {startDelay: 0.08});
		FlxTween.tween(separatorTop, {alpha: 0.2}, 0.2, {startDelay: 0.1});

		for (i in 0...links.length)
		{
			var delay = 0.12 + i * 0.03;
			FlxTween.tween(linkDots[i], {alpha: 0.9}, 0.15, {startDelay: delay});
			FlxTween.tween(linkTexts[i], {alpha: 0.7}, 0.15, {startDelay: delay});
			FlxTween.tween(linkUrlTexts[i], {alpha: 0.4}, 0.15, {startDelay: delay});
		}

		FlxTween.tween(separatorBottom, {alpha: 0.15}, 0.2, {startDelay: 0.15 + links.length * 0.03});
		FlxTween.tween(hintText, {alpha: 0.5}, 0.2, {
			startDelay: 0.18 + links.length * 0.03,
			onComplete: function(_)
			{
				_ready = true;
				updateSelection();
			}
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!_ready || _closing) return;

		if (controls.UI_UP_P)
		{
			curSelected = (curSelected - 1 + links.length) % links.length;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			updateSelection();
		}
		if (controls.UI_DOWN_P)
		{
			curSelected = (curSelected + 1) % links.length;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			updateSelection();
		}

		if (FlxG.mouse.justMoved || FlxG.mouse.justPressed)
		{
			for (i in 0...linkTexts.length)
			{
				var txt = linkTexts[i];
				if (FlxG.mouse.screenX >= panelX + 8 && FlxG.mouse.screenX <= panelX + PANEL_W - 8
					&& FlxG.mouse.screenY >= txt.y - 2 && FlxG.mouse.screenY <= txt.y + LINK_ITEM_H - 2)
				{
					if (curSelected != i)
					{
						curSelected = i;
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
						updateSelection();
					}
					if (FlxG.mouse.justPressed)
						confirmLink();
					break;
				}
			}
		}

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				for (i in 0...linkTexts.length)
				{
					var txt = linkTexts[i];
					if (touch.screenX >= panelX + 8 && touch.screenX <= panelX + PANEL_W - 8
						&& touch.screenY >= txt.y - 2 && touch.screenY <= txt.y + LINK_ITEM_H - 2)
					{
						curSelected = i;
						updateSelection();
						confirmLink();
						break;
					}
				}
			}
		}
		#end

		if (controls.ACCEPT)
			confirmLink();

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			animateClose(null);
		}

		if (FlxG.mouse.justPressed && !isOverPanel())
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			animateClose(null);
		}
	}

	function confirmLink():Void
	{
		if (_closing) return;
		var selectedLink = links[curSelected];
		if (selectedLink == null) return;

		FlxG.sound.play(Paths.sound('confirmMenu'));

		for (i in 0...linkTexts.length)
		{
			if (i == curSelected)
			{
				FlxTween.cancelTweensOf(linkTexts[i]);
				linkTexts[i].alpha = 1;
				FlxTween.tween(linkTexts[i], {alpha: 0.7}, 0.3);
			}
		}

		animateClose(function()
		{
			CoolUtil.browserLoad(selectedLink.url);
		});
	}

	function updateSelection():Void
	{
		for (i in 0...links.length)
		{
			var isSelected = (i == curSelected);
			var typeColor = linkTypeColors.get(links[i].type) ?? COL_TEXT;

			linkTexts[i].color = isSelected ? typeColor : COL_TEXT;
			linkTexts[i].alpha = isSelected ? 1.0 : 0.5;
			linkUrlTexts[i].alpha = isSelected ? 0.6 : 0.25;
			linkDots[i].color = isSelected ? (linkTypeColors.get(links[i].type) ?? 0xFFCCCCCC) : 0xFFCCCCCC;
			linkDots[i].alpha = isSelected ? 1.0 : 0.4;
		}

		var sepY = panelY + HEADER_H;
		var targetY = sepY + 8 + (curSelected * LINK_ITEM_H) + 2;
		selectBar.color = COL_BTN_SEL;
		selectBar.alpha = 0.8;
		FlxTween.cancelTweensOf(selectBar);
		FlxTween.tween(selectBar, {y: targetY}, 0.1, {ease: FlxEase.quartOut});
	}

	function isOverPanel():Bool
	{
		return FlxG.mouse.screenX >= panelX && FlxG.mouse.screenX <= panelX + PANEL_W
			&& FlxG.mouse.screenY >= panelY && FlxG.mouse.screenY <= panelY + panelH;
	}

	function animateClose(?callback:Void->Void):Void
	{
		if (_closing) return;
		_closing = true;
		_ready = false;

		FlxTween.tween(overlay, {alpha: 0}, 0.15);
		FlxTween.tween(panel, {alpha: 0}, 0.12);
		FlxTween.tween(accentLine, {alpha: 0}, 0.1);
		FlxTween.tween(headerText, {alpha: 0}, 0.1);
		FlxTween.tween(separatorTop, {alpha: 0}, 0.1);
		FlxTween.tween(separatorBottom, {alpha: 0}, 0.1);
		FlxTween.tween(hintText, {alpha: 0}, 0.1);
		FlxTween.tween(selectBar, {alpha: 0}, 0.1);

		for (i in 0...links.length)
		{
			FlxTween.tween(linkDots[i], {alpha: 0}, 0.1);
			FlxTween.tween(linkTexts[i], {alpha: 0}, 0.1);
			FlxTween.tween(linkUrlTexts[i], {alpha: 0}, 0.1);
		}

		new FlxTimer().start(0.18, function(_)
		{
			if (callback != null) callback();
			if (coolCam != null && FlxG.cameras.list.contains(coolCam))
				FlxG.cameras.remove(coolCam);
			coolCam = null;
			forceClose();
		});
	}

	function forceClose():Void
	{
		super.close();
	}

	override function close()
	{
		if (!_closing) animateClose(null);
	}

	override function destroy()
	{
		if (coolCam != null)
		{
			if (FlxG.cameras.list.contains(coolCam))
				FlxG.cameras.remove(coolCam);
			coolCam = null;
		}
		linkBgs = [];
		linkDots = [];
		linkTexts = [];
		linkUrlTexts = [];
		super.destroy();
	}
}

class LinkSubStateSingle extends MusicBeatSubstate
{
	static inline final COL_PANEL = 0xFF1a1a1a;
	static inline final COL_ACCENT = 0xFF888888;
	static inline final COL_TEXT = 0xFFE0E0E0;
	static inline final COL_DIM = 0xFF707070;
	static inline final COL_YES = 0xFF22c55e;
	static inline final COL_NO = 0xFFef4444;
	static inline final COL_BTN = 0xFF222222;
	static inline final COL_BTN_SEL = 0xFF333333;

	static inline final PANEL_W = 480;
	static inline final PANEL_H = 240;
	static inline final BTN_W = 140;
	static inline final BTN_H = 42;

	var prompt:String;
	var url:String;
	var yesCallback:Void->Void;
	var noCallback:Void->Void;

	var coolCam:FlxCamera;
	var overlay:FlxSprite;
	var panel:FlxSprite;
	var accentLine:FlxSprite;
	var promptText:FlxText;
	var urlText:FlxText;
	var yesBg:FlxSprite;
	var noBg:FlxSprite;
	var yesLine:FlxSprite;
	var noLine:FlxSprite;
	var yesText:FlxText;
	var noText:FlxText;
	var linkIcon:FlxSprite;

	var curSelected:Int = -1;
	var _ready:Bool = false;
	var _closing:Bool = false;

	public function new(prompt:String, url:String, yesCallback:Void->Void, ?noCallback:Void->Void)
	{
		super();
		this.prompt = prompt;
		this.url = url;
		this.yesCallback = yesCallback;
		this.noCallback = noCallback;
	}

	override function create()
	{
		super.create();

		coolCam = new FlxCamera();
		coolCam.bgColor.alpha = 0;
		FlxG.cameras.add(coolCam, false);
		cameras = [coolCam];

		var px:Float = (FlxG.width - PANEL_W) / 2;
		var py:Float = (FlxG.height - PANEL_H) / 2;

		overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		overlay.scrollFactor.set();
		overlay.alpha = 0;
		add(overlay);

		panel = new FlxSprite(px, py).makeGraphic(PANEL_W, PANEL_H, COL_PANEL);
		panel.scrollFactor.set();
		panel.alpha = 0;
		add(panel);

		accentLine = new FlxSprite(px, py).makeGraphic(PANEL_W, 2, COL_ACCENT);
		accentLine.scrollFactor.set();
		accentLine.alpha = 0;
		add(accentLine);

		promptText = new FlxText(px + 30, py + 30, PANEL_W - 60, prompt);
		promptText.setFormat(Paths.font("vcr.ttf"), 20, COL_TEXT, CENTER);
		promptText.scrollFactor.set();
		promptText.alpha = 0;
		add(promptText);

		linkIcon = new FlxSprite();
		linkIcon.scrollFactor.set();
		linkIcon.alpha = 0;
		try
		{
			linkIcon.loadGraphic(Paths.image("other/link"));
			linkIcon.setGraphicSize(18, 18);
			linkIcon.updateHitbox();
		}
		catch (e:Dynamic)
		{
			linkIcon.makeGraphic(18, 18, COL_ACCENT);
		}

		urlText = new FlxText(0, py + 75, PANEL_W - 60, url);
		urlText.setFormat(Paths.font("vcr.ttf"), 14, COL_ACCENT, CENTER);
		urlText.scrollFactor.set();
		urlText.alpha = 0;
		urlText.screenCenter(X);

		var actualTextWidth:Float = urlText.width;
		if (urlText.textField != null)
			actualTextWidth = urlText.textField.textWidth;
		var textStartX:Float = urlText.x + (urlText.width - actualTextWidth) / 2;
		linkIcon.x = textStartX - 24;
		linkIcon.y = urlText.y + (urlText.height - 18) / 2;
		linkIcon.antialiasing = ClientPrefs.data.antialiasing;

		add(linkIcon);
		add(urlText);

		var sep = new FlxSprite(px + 40, py + 120).makeGraphic(PANEL_W - 80, 1, COL_ACCENT);
		sep.scrollFactor.set();
		sep.alpha = 0;
		add(sep);

		var btnY:Float = py + PANEL_H - BTN_H - 30;
		var gap:Float = 20;
		var totalW:Float = BTN_W * 2 + gap;
		var startX:Float = px + (PANEL_W - totalW) / 2;

		yesBg = new FlxSprite(startX, btnY).makeGraphic(BTN_W, BTN_H, COL_BTN);
		yesBg.scrollFactor.set();
		yesBg.alpha = 0;
		add(yesBg);

		yesLine = new FlxSprite(startX, btnY).makeGraphic(BTN_W, 2, COL_YES);
		yesLine.scrollFactor.set();
		yesLine.alpha = 0;
		add(yesLine);

		yesText = new FlxText(startX, btnY + 10, BTN_W,
			Language.getPhrase('link_yes', 'Evet'));
		yesText.setFormat(Paths.font("vcr.ttf"), 18, COL_TEXT, CENTER);
		yesText.scrollFactor.set();
		yesText.alpha = 0;
		add(yesText);

		var noX:Float = startX + BTN_W + gap;

		noBg = new FlxSprite(noX, btnY).makeGraphic(BTN_W, BTN_H, COL_BTN);
		noBg.scrollFactor.set();
		noBg.alpha = 0;
		add(noBg);

		noLine = new FlxSprite(noX, btnY).makeGraphic(BTN_W, 2, COL_NO);
		noLine.scrollFactor.set();
		noLine.alpha = 0;
		add(noLine);

		noText = new FlxText(noX, btnY + 10, BTN_W,
			Language.getPhrase('link_no', 'Hayır'));
		noText.setFormat(Paths.font("vcr.ttf"), 18, COL_TEXT, CENTER);
		noText.scrollFactor.set();
		noText.alpha = 0;
		add(noText);

		FlxTween.tween(overlay, {alpha: 0.55}, 0.2);
		panel.scale.set(0.93, 0.93);
		FlxTween.tween(panel, {alpha: 1}, 0.2);
		FlxTween.tween(panel.scale, {x: 1, y: 1}, 0.25, {ease: FlxEase.backOut});
		FlxTween.tween(accentLine, {alpha: 0.8}, 0.2, {startDelay: 0.05});
		FlxTween.tween(promptText, {alpha: 1}, 0.2, {startDelay: 0.08});
		FlxTween.tween(urlText, {alpha: 0.9}, 0.2, {startDelay: 0.1});
		FlxTween.tween(linkIcon, {alpha: 0.7}, 0.2, {startDelay: 0.1});
		FlxTween.tween(sep, {alpha: 0.2}, 0.2, {startDelay: 0.12});
		FlxTween.tween(yesBg, {alpha: 1}, 0.2, {startDelay: 0.14});
		FlxTween.tween(yesLine, {alpha: 0.6}, 0.2, {startDelay: 0.14});
		FlxTween.tween(yesText, {alpha: 0.6}, 0.2, {startDelay: 0.14});
		FlxTween.tween(noBg, {alpha: 1}, 0.2, {startDelay: 0.16});
		FlxTween.tween(noLine, {alpha: 0.6}, 0.2, {startDelay: 0.16});
		FlxTween.tween(noText, {alpha: 0.6}, 0.2, {
			startDelay: 0.16,
			onComplete: function(_) { _ready = true; }
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!_ready || _closing) return;

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			curSelected = (curSelected == 0) ? 1 : 0;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			updateHighlight();
		}

		if (FlxG.mouse.justMoved || FlxG.mouse.justPressed)
		{
			var prev = curSelected;
			if (isOver(yesBg)) curSelected = 0;
			else if (isOver(noBg)) curSelected = 1;
			else curSelected = -1;
			if (prev != curSelected) updateHighlight();
		}

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed || touch.pressed)
			{
				var prev = curSelected;
				if (touchOver(yesBg, touch)) curSelected = 0;
				else if (touchOver(noBg, touch)) curSelected = 1;
				if (prev != curSelected) updateHighlight();
			}
		}
		#end

		var doAccept = controls.ACCEPT;
		var doClick = FlxG.mouse.justPressed && curSelected >= 0;

		#if mobile
		if (!doAccept && !doClick)
		{
			for (touch in FlxG.touches.list)
			{
				if (touch.justPressed && curSelected >= 0)
				{
					doClick = true;
					break;
				}
			}
		}
		#end

		if (doAccept || doClick)
		{
			if (curSelected == 0) selectYes();
			else if (curSelected == 1) selectNo();
		}

		if (FlxG.mouse.justPressed && curSelected == -1 && !isOver(panel))
			selectNo();

		if (controls.BACK) selectNo();
	}

	function selectYes():Void
	{
		if (_closing) return;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		animateClose(function() { if (yesCallback != null) yesCallback(); });
	}

	function selectNo():Void
	{
		if (_closing) return;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		animateClose(function() { if (noCallback != null) noCallback(); });
	}

	function updateHighlight():Void
	{
		if (curSelected == 0)
		{
			yesBg.color = COL_BTN_SEL;
			yesText.alpha = 1;
			yesLine.alpha = 1;
			noBg.color = COL_BTN;
			noText.alpha = 0.6;
			noLine.alpha = 0.6;
		}
		else if (curSelected == 1)
		{
			yesBg.color = COL_BTN;
			yesText.alpha = 0.6;
			yesLine.alpha = 0.6;
			noBg.color = COL_BTN_SEL;
			noText.alpha = 1;
			noLine.alpha = 1;
		}
		else
		{
			// curSelected == -1: hiçbiri seçili değil, varsayılan görünüm
			yesBg.color = COL_BTN;
			yesText.alpha = 0.6;
			yesLine.alpha = 0.6;
			noBg.color = COL_BTN;
			noText.alpha = 0.6;
			noLine.alpha = 0.6;
		}
	}

	function isOver(spr:FlxSprite):Bool
	{
		return FlxG.mouse.screenX >= spr.x && FlxG.mouse.screenX <= spr.x + spr.width
			&& FlxG.mouse.screenY >= spr.y && FlxG.mouse.screenY <= spr.y + spr.height;
	}

	#if mobile
	function touchOver(spr:FlxSprite, touch:flixel.input.touch.FlxTouch):Bool
	{
		return touch.screenX >= spr.x && touch.screenX <= spr.x + spr.width
			&& touch.screenY >= spr.y && touch.screenY <= spr.y + spr.height;
	}
	#end

	function animateClose(?callback:Void->Void):Void
	{
		if (_closing) return;
		_closing = true;
		_ready = false;

		FlxTween.tween(overlay, {alpha: 0}, 0.15);
		FlxTween.tween(panel, {alpha: 0}, 0.12);
		FlxTween.tween(accentLine, {alpha: 0}, 0.1);
		FlxTween.tween(promptText, {alpha: 0}, 0.1);
		FlxTween.tween(urlText, {alpha: 0}, 0.1);
		FlxTween.tween(yesBg, {alpha: 0}, 0.1);
		FlxTween.tween(yesLine, {alpha: 0}, 0.1);
		FlxTween.tween(yesText, {alpha: 0}, 0.1);
		FlxTween.tween(noBg, {alpha: 0}, 0.1);
		FlxTween.tween(noLine, {alpha: 0}, 0.1);
		FlxTween.tween(noText, {alpha: 0}, 0.1);
		FlxTween.tween(linkIcon, {alpha: 0}, 0.1);

		new flixel.util.FlxTimer().start(0.18, function(_)
		{
			if (callback != null) callback();
			if (coolCam != null && FlxG.cameras.list.contains(coolCam))
				FlxG.cameras.remove(coolCam);
			coolCam = null;
			forceClose();
		});
	}

	function forceClose():Void
	{
		super.close();
	}

	override function close()
	{
		if (!_closing) animateClose(null);
	}

	override function destroy()
	{
		if (coolCam != null)
		{
			if (FlxG.cameras.list.contains(coolCam))
				FlxG.cameras.remove(coolCam);
			coolCam = null;
		}
		super.destroy();
	}
}