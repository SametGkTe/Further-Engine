package backend.modpack.zip;

class ZipExtractorFactory {
	public static function create():IZipExtractor {
		#if sys
		// sys hedeflerin hepsi destekleniyor:
		// Windows, Linux, Mac, Android, iOS
		return new SystemZipExtractor();
		#else
		return new UnsupportedZipExtractor(
			"Bu platformda ZIP çıkarma desteklenmiyor (sys gerekli)."
		);
		#end
	}

	/**
	 * Extractor oluştur.
	 * Birincil desteklenmiyorsa UnsupportedZipExtractor döner.
	 */
	public static function createSafe():IZipExtractor {
		var extractor = create();

		if (!extractor.isSupported()) {
			trace('[ZipExtractorFactory] ${extractor.getBackendName()} desteklenmiyor, unsupported döndürüldü.');
			return new UnsupportedZipExtractor(
				'Platform (${extractor.getBackendName()}) ZIP çıkarmayı desteklemiyor.'
			);
		}

		trace('[ZipExtractorFactory] Backend: ${extractor.getBackendName()}');
		return extractor;
	}
}