import 'package:intl/intl.dart';

class PengelolaFmt {
  PengelolaFmt._();

  static final NumberFormat _int = NumberFormat.decimalPattern('id_ID');

  /// 1245 -> "1.245"
  static String number(num v) => _int.format(v);

  /// 48500000 -> "Rp48,5 jt"
  static String rupiahShort(num v) {
    if (v >= 1000000000) return 'Rp${_trim(v / 1000000000)} M';
    if (v >= 1000000) return 'Rp${_trim(v / 1000000)} jt';
    if (v >= 1000) return 'Rp${_trim(v / 1000)} rb';
    return 'Rp${v.round()}';
  }

  static String _trim(double v) {
    final s = v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return (s.endsWith('.0') ? s.substring(0, s.length - 2) : s).replaceAll('.', ',');
  }
}