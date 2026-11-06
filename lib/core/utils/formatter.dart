import 'package:intl/intl.dart';

class Formatter {
  Formatter._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static final DateFormat _date = DateFormat('d MMM yyyy', 'id_ID');

  /// 1500000 -> "Rp 1.500.000"
  static String rupiah(num value) => _rupiah.format(value);

  /// 25000 -> "Rp 25rb", 2000000 -> "Rp 2jt", selain itu format biasa
  static String rupiahCompact(int value) {
    if (value >= 1000000 && value % 1000000 == 0) {
      return 'Rp ${value ~/ 1000000}jt';
    }
    if (value >= 1000 && value % 1000 == 0) {
      return 'Rp ${value ~/ 1000}rb';
    }
    return rupiah(value);
  }

  /// 2025-10-20 -> "20 Okt 2025" (butuh initializeDateFormatting di main)
  static String date(DateTime value) => _date.format(value);
}
