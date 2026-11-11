/// Lafaz niat zakat. Niat sejatinya ada di dalam hati; lafaz membantu menguatkan.
class ZakatNiat {
  const ZakatNiat({
    required this.label,
    required this.arabic,
    required this.latin,
    required this.meaning,
  });

  /// Nama singkat untuk pilihan (misal "Diri sendiri").
  final String label;
  final String arabic;
  final String latin;
  final String meaning;

  /// Teks lengkap untuk disalin.
  String get copyText => '$arabic\n$latin\nArtinya: $meaning';
}

class ZakatNiatData {
  ZakatNiatData._();

  /// Indeks di [fitrah] yang dipakai sebagai pilihan otomatis.
  static const int fitrahSelf = 0;
  static const int fitrahFamily = 4;

  static const List<ZakatNiat> fitrah = [
    ZakatNiat(
      label: 'Diri sendiri',
      arabic: 'نَوَيْتُ أَنْ أُخْرِجَ زَكَاةَ الْفِطْرِ عَنْ نَفْسِي فَرْضًا لِلَّهِ تَعَالَى',
      latin: "Nawaitu an ukhrija zakaatal fithri 'an nafsii fardhan lillaahi ta'aalaa.",
      meaning:
          "Aku berniat mengeluarkan zakat fitrah untuk diriku sendiri, fardhu karena Allah Ta'ala.",
    ),
    ZakatNiat(
      label: 'Istri',
      arabic: 'نَوَيْتُ أَنْ أُخْرِجَ زَكَاةَ الْفِطْرِ عَنْ زَوْجَتِي فَرْضًا لِلَّهِ تَعَالَى',
      latin: "Nawaitu an ukhrija zakaatal fithri 'an zawjatii fardhan lillaahi ta'aalaa.",
      meaning:
          "Aku berniat mengeluarkan zakat fitrah untuk istriku, fardhu karena Allah Ta'ala.",
    ),
    ZakatNiat(
      label: 'Anak laki-laki',
      arabic: 'نَوَيْتُ أَنْ أُخْرِجَ زَكَاةَ الْفِطْرِ عَنْ وَلَدِي فَرْضًا لِلَّهِ تَعَالَى',
      latin: "Nawaitu an ukhrija zakaatal fithri 'an waladii fardhan lillaahi ta'aalaa.",
      meaning:
          "Aku berniat mengeluarkan zakat fitrah untuk anak laki-lakiku, fardhu karena Allah Ta'ala.",
    ),
    ZakatNiat(
      label: 'Anak perempuan',
      arabic: 'نَوَيْتُ أَنْ أُخْرِجَ زَكَاةَ الْفِطْرِ عَنْ بِنْتِي فَرْضًا لِلَّهِ تَعَالَى',
      latin: "Nawaitu an ukhrija zakaatal fithri 'an bintii fardhan lillaahi ta'aalaa.",
      meaning:
          "Aku berniat mengeluarkan zakat fitrah untuk anak perempuanku, fardhu karena Allah Ta'ala.",
    ),
    ZakatNiat(
      label: 'Seluruh keluarga',
      arabic:
          'نَوَيْتُ أَنْ أُخْرِجَ زَكَاةَ الْفِطْرِ عَنِّي وَعَنْ جَمِيعِ مَا يَلْزَمُنِي نَفَقَاتُهُمْ شَرْعًا فَرْضًا لِلَّهِ تَعَالَى',
      latin:
          "Nawaitu an ukhrija zakaatal fithri 'annii wa 'an jamii'i maa yalzamunii nafaqaatuhum syar'an fardhan lillaahi ta'aalaa.",
      meaning:
          "Aku berniat mengeluarkan zakat fitrah untuk diriku dan untuk semua orang yang nafkahnya menjadi tanggunganku menurut syariat, fardhu karena Allah Ta'ala.",
    ),
  ];

  static const ZakatNiat maal = ZakatNiat(
    label: 'Zakat maal',
    arabic: 'نَوَيْتُ أَنْ أُخْرِجَ زَكَاةَ مَالِي فَرْضًا لِلَّهِ تَعَالَى',
    latin: "Nawaitu an ukhrija zakaata maalii fardhan lillaahi ta'aalaa.",
    meaning: "Aku berniat mengeluarkan zakat hartaku, fardhu karena Allah Ta'ala.",
  );
}