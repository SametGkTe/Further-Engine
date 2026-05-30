package mobile.options;

import mobile.backend.MobileScaleMode;
import flixel.input.keyboard.FlxKey;
import options.BaseOptionsMenu;
import options.Option;

#if android
import sys.io.File;
#end

class MobileOptionsSubState extends BaseOptionsMenu
{
	#if android
	var storageTypes:Array<String> = ["EXTERNAL_DATA", "EXTERNAL_OBB", "EXTERNAL_MEDIA", "EXTERNAL"];
	var externalPaths:Array<String> = StorageUtil.checkExternalPaths(true);
	var customPaths:Array<String> = StorageUtil.getCustomStorageDirectories(false);
	final lastStorageType:String = ClientPrefs.data.storageType;
	#end

	final controlModes:Array<String> = ["Button", "Touch"];
	final exControlTypes:Array<String> = ["NONE", "SINGLE", "DOUBLE"];
	final hitboxViewTypes:Array<String> = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];

	var option:Option;
	var hitboxTypes:Array<String>;

	public function new()
	{
		title = 'Mobil Ayarlar';
		rpcTitle = 'Mobile Options Menu';

		#if android
		storageTypes = storageTypes.concat(customPaths);
		storageTypes = storageTypes.concat(externalPaths);
		#end

		hitboxTypes = Mods.mergeAllTextsNamed('mobile/Hitbox/HitboxModes/hitboxModeList.txt');
		if (hitboxTypes == null || hitboxTypes.length < 1)
			hitboxTypes = ["Normal (New)"];

		// Kontrol Türü
		option = new Option('Kontrol Türü',
			'Tuşlu: Ekran tuşlarıyla kontrol edersiniz.\nDokunmatik: Parmağınızla kaydırma ve dokunma ile kontrol edersiniz.',
			'controlMode', STRING, controlModes);
		addOption(option);

		// Mobil buton saydamlığı
		option = new Option('Mobil Buton Saydamlığı',
			'Mobil tuşların saydamlığını ayarlar.',
			'mobilePadAlpha', PERCENT);
		option.scrollSpeed = 1;
		option.minValue = 0.001;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = () ->
		{
			ClientPrefs.data.controlsAlpha = ClientPrefs.data.mobilePadAlpha;

			if (touchPad != null)
				touchPad.alpha = curOption.getValue();

			ClientPrefs.toggleVolumeKeys();
		};
		addOption(option);

		// Eski sistemle uyumluluk için ekstra buton
		option = new Option('Ekstra Kontroller',
			'Ekstra mobil buton sayısını ayarlar.',
			'extraButtons', STRING, exControlTypes);
		option.onChange = () ->
		{
			switch (ClientPrefs.data.extraButtons)
			{
				case "NONE":
					ClientPrefs.data.extraKeys = 0;
				case "SINGLE":
					ClientPrefs.data.extraKeys = 1;
				case "DOUBLE":
					ClientPrefs.data.extraKeys = 2;
				default:
					ClientPrefs.data.extraKeys = 0;
			}
		};
		addOption(option);

		// Yeni sistem için ekstra key count
		option = new Option('Ekstra Tuş Sayısı',
			'Yeni hitbox sisteminde kaç ekstra tuş kullanılacağını ayarlar.',
			'extraKeys', INT);
		option.scrollSpeed = 1;
		option.minValue = 0;
		option.maxValue = 4;
		option.changeValue = 1;
		option.decimals = 0;
		option.onChange = () ->
		{
			switch (Std.int(curOption.getValue()))
			{
				case 0:
					ClientPrefs.data.extraButtons = "NONE";
				case 1:
					ClientPrefs.data.extraButtons = "SINGLE";
				case 2:
					ClientPrefs.data.extraButtons = "DOUBLE";
				default:
			}
		};
		addOption(option);

		// Hitbox konumu
		option = new Option('Hitbox Konumu',
			'Hitbox ekranın neresinde görünecek?',
			'hitboxLocation', STRING, ['Bottom', 'Top', 'Middle']);
		addOption(option);

		// Hitbox stili
		option = new Option('Hitbox Stili',
			'Yeni hitbox stilini seçin.',
			'hitboxMode', STRING, hitboxTypes);
		addOption(option);

		// Hitbox görünümü
		option = new Option('Hitbox Görünümü',
			'Hitbox kontrolünün nasıl gözükeceğini ayarlar.',
			'hitboxType', STRING, hitboxViewTypes);
		addOption(option);

		// Hitbox ipucu
		option = new Option('Hitbox İpucu',
			'Hitbox üst/alt ipucu çizgilerini gösterir.',
			'hitboxHint', BOOL);
		addOption(option);

		// V-Slice / OG kontrol
		option = new Option('Orijinal FNF Kontrolü',
			'Aktif edildiğinde V-Slice tarzı kontrol kullanılır.',
			'ogGameControls', BOOL);
		addOption(option);

		option = new Option('V-Slice Aralığı',
			'V-Slice butonlarının genişleme oranını ayarlar.',
			'vSliceSpacing', PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0;
		option.maxValue = 1;
		option.changeValue = 0.01;
		option.decimals = 2;
		addOption(option);

		// Hitbox alpha
		option = new Option('Hitbox Saydamlığı',
			'Hitbox düğmelerinin saydamlığını ayarlar.',
			'hitboxAlpha', PERCENT);
		option.scrollSpeed = 1;
		option.minValue = 0.001;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		#if mobile
		option = new Option('Ekran Koruyucu',
			'İşaretlenirse telefon bir süre sonra uyku moduna geçebilir.',
			'screensaver', BOOL);
		option.onChange = () -> lime.system.System.allowScreenTimeout = curOption.getValue();
		addOption(option);

		option = new Option('Geniş Ekran Modu',
			'Aktif edildiğinde oyun ekranı doldurmaya çalışır.',
			'wideScreen', BOOL);
		option.onChange = () -> FlxG.scaleMode = new MobileScaleMode();
		addOption(option);
		#end

		// Dinamik renk
		option = new Option('Dinamik Kontrol Rengi',
			'Kontroller nota renklerine göre değişsin.',
			'dynamicColors', BOOL);
		addOption(option);

		#if android
		option = new Option('Depolama Türü',
			'Motorun hangi klasörü kullanacağını seçin.',
			'storageType', STRING, storageTypes);
		addOption(option);
		#end

		super();
	}

	#if android
	override public function destroy()
	{
		super.destroy();

		if (ClientPrefs.data.storageType != lastStorageType)
		{
			File.saveContent(lime.system.System.applicationStorageDirectory + 'storagetype.txt', ClientPrefs.data.storageType);
			ClientPrefs.saveSettings();
			StorageUtil.initExternalStorageDirectory();
		}
	}
	#end
}