import 'package:intl/intl.dart';
import 'package:sadaqo/core/utils/formatter.dart';

/// Format angka, waktu, dan tanggal untuk dashboard admin.
class AdminFmt {
  AdminFmt._();

  static final NumberFormat _int = NumberFormat.decimalPattern('id_ID');

  /// 12480 -> "12.480"
  static String number(num v) => _int.format(v);

  static String rupiah(num v) => Formatter.rupiah(v);

  /// 85000000 -> "Rp 85 jt", 1250000000 -> "Rp 1,25 M"
  static String rupiahShort(num v) {
    if (v >= 1000000000) return 'Rp ${_trim(v / 1000000000)} M';
    if (v >= 1000000) return 'Rp ${_trim(v / 1000000)} jt';
    if (v >= 1000) return 'Rp ${_trim(v / 1000)} rb';
    return 'Rp ${v.round()}';
  }

  /// Sumbu grafik: 25000000 -> "25 jt"
  static String axis(num v) {
    if (v >= 1000000000) return '${_trim(v / 1000000000)} M';
    if (v >= 1000000) return '${_trim(v / 1000000)} jt';
    if (v >= 1000) return '${_trim(v / 1000)} rb';
    return '${v.round()}';
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(v >= 100 ? 0 : (v >= 10 ? 1 : 2));
    final t = s.contains('.')
        ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
        : s;
    return t.replaceAll('.', ',');
  }

  static String date(DateTime d) => Formatter.date(d);

  static final DateFormat _dm = DateFormat('d MMM', 'id_ID');
  static final DateFormat _dmy = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _hm = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _mon = DateFormat('MMM yy', 'id_ID');

  static String dayMonth(DateTime d) => _dm.format(d);
  static String dayMonthYear(DateTime d) => _dmy.format(d);
  static String time(DateTime d) => _hm.format(d);
  static String monthYear(DateTime d) => _mon.format(d);
  static String dateTime(DateTime d) => '${_dmy.format(d)}, ${_hm.format(d)}';

  /// "2 menit yang lalu", "1 jam yang lalu", "Kemarin", atau tanggal.
  static String ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 45) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
    return _dmy.format(d);
  }

  /// Sisa waktu banned, mis. "29 hari 4 jam", "Permanen".
  static String remaining(DateTime until) {
    final diff = until.difference(DateTime.now());
    if (diff.isNegative) return 'Selesai';
    if (diff.inDays >= 3650) return 'Permanen';
    if (diff.inDays >= 1) {
      final h = diff.inHours - diff.inDays * 24;
      return h > 0 ? '${diff.inDays} hari $h jam' : '${diff.inDays} hari';
    }
    if (diff.inHours >= 1) return '${diff.inHours} jam ${diff.inMinutes % 60} menit';
    return '${diff.inMinutes.clamp(1, 59)} menit';
  }
}
