/// Pilihan penyedia pembayaran. Tambah/ubah daftar di sini saja.
class PaymentOptions {
  PaymentOptions._();

  static const List<String> ewallets = [
    'DANA',
    'GoPay',
    'OVO',
    'ShopeePay',
    'LinkAja',
  ];

  static const List<String> banks = [
    'BCA',
    'Mandiri',
    'BRI',
    'BNI',
    'BSI',
    'CIMB Niaga',
    'Permata',
    'BTN',
    'Danamon',
    'Mega',
    'Jatim',
  ];
}