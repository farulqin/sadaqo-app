import 'package:sadaqo/features/community/domain/entities/moderation.dart';

/// Penyaring konten berbasis kata kunci untuk versi demo.
/// Batasan: tidak memahami konteks dan tidak bisa memastikan sebuah kabar
/// itu hoaks. Hoaks ditangani lewat tombol "Laporkan" dan, nanti, moderasi
/// di server. Daftar kata di bawah bebas ditambah atau dikurangi.
class ContentModerator {
  const ContentModerator._();

  /// Penistaan agama dideteksi jika istilah agama muncul bersama kata hinaan.
  static const List<String> _religionTerms = [
    'islam', 'allah', 'nabi', 'rasul', 'quran', 'alquran', 'muhammad',
    'kristen', 'yesus', 'tuhan', 'hindu', 'buddha', 'budha', 'agama',
    'masjid', 'gereja', 'pura', 'vihara',
  ];
  static const List<String> _insultTerms = [
    'sampah', 'bodoh', 'goblok', 'tolol', 'anjing', 'babi', 'bangsat',
    'laknat', 'sesat', 'teroris', 'dongeng', 'khayalan', 'jelek', 'hina',
  ];

  static const Map<ViolationType, List<String>> _phrases = {
    ViolationType.blasphemy: [
      'allah bodoh', 'nabi palsu', 'quran palsu', 'alquran palsu', 'hina agama',
      'agama sampah', 'tuhan bodoh', 'rasul palsu',
    ],
    ViolationType.hate: [
      'bunuh dia', 'bunuh mereka', 'bunuh semua', 'mati kau', 'mati saja kau',
      'musnahkan', 'bantai', 'dasar cina', 'dasar kafir', 'kafir laknat',
      'cina kafir', 'binatang kau', 'babi kau', 'usir semua',
    ],
    ViolationType.porn: [
      'bokep', 'porno', 'pornografi', 'seks', 'sex', 'telanjang', 'bugil',
      'ngentot', 'vcs', 'open bo', 'video dewasa', 'konten dewasa', 'nude',
      'nsfw', 'xxx', 'colmek', 'masturbasi',
    ],
    ViolationType.scam: [
      'transfer dulu', 'kirim pulsa', 'kirim otp', 'minta otp', 'kode otp',
      'klik link', 'link hadiah', 'hadiah gratis', 'menang undian',
      'judi online', 'slot gacor', 'togel', 'jackpot', 'uang cepat',
      'kirim uang dulu', 'donasi ke rekening', 'rekening pribadi',
      'investasi cepat kaya',
    ],
    ViolationType.hoax: [
      'sebarkan sebelum dihapus', 'viral wajib sebar', 'share ke semua grup',
      'sebarkan ke semua kontak', 'berita ini dirahasiakan',
      'media tidak berani', 'forward ke 10',
    ],
    ViolationType.profanity: [
      'anjing', 'bangsat', 'bajingan', 'brengsek', 'keparat', 'bangke',
      'sialan', 'goblok', 'tolol', 'kontol', 'memek', 'jancok', 'jancuk',
      'asu', 'tai', 'kampret', 'fuck', 'shit', 'bitch', 'asshole',
    ],
  };

  static const List<ViolationType> _order = [
    ViolationType.hate,
    ViolationType.porn,
    ViolationType.scam,
    ViolationType.hoax,
    ViolationType.profanity,
  ];

  /// Mengembalikan jenis pelanggaran pertama yang ditemukan, atau null jika aman.
  static ViolationType? check(String raw) {
    final text = _normalize(raw);
    if (text.isEmpty) return null;
    final words = text.split(' ');

    bool has(String keyword) {
      if (keyword.contains(' ')) return ' $text '.contains(' $keyword ');
      if (words.contains(keyword)) return true;
      // kata panjang juga dicocokkan di dalam kata (mis. "bangsatnya")
      return keyword.length >= 6 && text.contains(keyword);
    }

    final religious = _religionTerms.any(words.contains);
    final insulting = _insultTerms.any(words.contains);
    if ((religious && insulting) || _phrases[ViolationType.blasphemy]!.any(has)) {
      return ViolationType.blasphemy;
    }

    for (final type in _order) {
      if (_phrases[type]!.any(has)) return type;
    }
    return null;
  }

  /// Huruf kecil, angka "gaul" jadi huruf (4=a, 3=e, 0=o, dst), simbol dibuang,
  /// huruf berulang 3x atau lebih dipadatkan ("anjiiing" -> "anjing").
  static String _normalize(String input) {
    const leet = {
      '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '@': 'a', '\$': 's',
    };
    final buffer = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      buffer.write(leet[ch] ?? ch);
    }
    var s = buffer.toString().replaceAll(RegExp(r'[^a-z ]'), ' ');
    s = s.replaceAllMapped(RegExp(r'(.)\1{2,}'), (m) => m[1]!);
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}