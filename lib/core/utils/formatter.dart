import 'package:intl/intl.dart';

class Formatter {
  Formatter._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// 1500000 -> "Rp 1.500.000"
  static String rupiah(num value) => _rupiah.format(value);
}
