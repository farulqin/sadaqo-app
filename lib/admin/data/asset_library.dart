import 'package:flutter/services.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/program_category.dart';

/// Daftar gambar yang ada di aplikasi, dikelompokkan per folder.
/// Dibaca otomatis dari AssetManifest, jadi foto baru yang kamu masukkan ke
/// assets/images/... langsung muncul di pemilih gambar admin tanpa ubah kode.
class AssetLibrary {
  AssetLibrary._();

  static const Map<String, String> groups = {
    'masjid_mushola': 'Masjid & Mushola',
    'bantuan_sosial': 'Bantuan Sosial',
    'zakat': 'Zakat',
    'kaum_duafa': 'Kaum Duafa',
    'qurban_bersama': 'Qurban Bersama',
    'news': 'Berita',
    'avatar': 'Avatar',
    'icons': 'Ikon',
  };

  /// Folder foto untuk tiap kategori program.
  static String groupFor(ProgramCategory c) {
    switch (c) {
      case ProgramCategory.masjid:
        return 'masjid_mushola';
      case ProgramCategory.sosial:
        return 'bantuan_sosial';
      case ProgramCategory.zakat:
        return 'zakat';
      case ProgramCategory.duafa:
        return 'kaum_duafa';
      case ProgramCategory.qurban:
        return 'qurban_bersama';
    }
  }

  static Map<String, List<String>>? _cache;

  static Future<Map<String, List<String>>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final result = <String, List<String>>{for (final k in groups.keys) k: <String>[]};
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final path in manifest.listAssets()) {
        final lower = path.toLowerCase();
        final isImage = lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp');
        if (!isImage) continue;
        for (final key in groups.keys) {
          final folder = key == 'icons' ? 'assets/icons/' : 'assets/images/$key/';
          if (path.startsWith(folder)) {
            result[key]!.add(path);
            break;
          }
        }
      }
    } catch (_) {
      // Cadangan jika manifest tidak terbaca: pakai daftar yang diketahui kode.
      result['avatar']!.addAll(AppAssets.avatars);
      result['icons']!.addAll([
        AppAssets.iconMasjid,
        AppAssets.iconSosial,
        AppAssets.iconZakat,
        AppAssets.iconDuafa,
        AppAssets.iconQurban,
      ]);
    }
    for (final list in result.values) {
      list.sort();
    }
    return _cache = result;
  }

  /// Nama file tanpa folder, mis. "masjid_al_azzam.jpg".
  static String fileName(String path) => path.split('/').last;

  /// Hapus cache (mis. setelah hot restart tidak perlu; hanya jika aset berubah).
  static void reset() => _cache = null;
}
