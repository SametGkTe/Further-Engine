package backend.modpack.zip;

class ZipExtractorFactory {
	public static function create():IZipExtractor {
		#if (windows || linux || mac)
		return new SystemZipExtractor();

		#elseif android
		// Android backend ileride eklenecek
		return new UnsupportedZipExtractor(
			"Android ZIP backend henüz eklenmedi."
		);

		#elseif ios
		// iOS backend ileride eklenecek
		return new UnsupportedZipExtractor(
			"iOS ZIP backend henüz eklenmedi."
		);

		#else
		return new UnsupportedZipExtractor(
			"Bu platform desteklenmiyor."
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