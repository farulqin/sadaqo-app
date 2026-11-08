import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';

/// Halaman Syarat & Ketentuan dan Kebijakan Privasi (draft untuk versi demo).
class LegalPage extends StatelessWidget {
  const LegalPage._({required this.title, required this.sections});

  factory LegalPage.terms() => const LegalPage._(
        title: 'Syarat & Ketentuan',
        sections: _terms,
      );

  factory LegalPage.privacy() => const LegalPage._(
        title: 'Kebijakan Privasi',
        sections: _privacy,
      );

  final String title;
  final List<(String, String)> sections;

  static const List<(String, String)> _terms = [
    (
      '1. Penerimaan ketentuan',
      'Dengan memakai SADAQO, kamu menyetujui syarat dan ketentuan ini. Jika tidak setuju, '
          'mohon berhenti menggunakan aplikasi.'
    ),
    (
      '2. Penggunaan aplikasi',
      'Gunakan aplikasi untuk tujuan yang baik dan sesuai hukum. Jaga kerahasiaan akun dan '
          'password, serta jangan menyalahgunakan fitur donasi.'
    ),
    (
      '3. Donasi dan pembayaran',
      'Minimal transaksi adalah Rp 5.000, kecuali zakat yang dihitung kalkulator. Pada versi '
          'demo ini, pembayaran bersifat simulasi dan tidak memindahkan uang sungguhan.'
    ),
    (
      '4. Program dan verifikasi',
      'Program ditayangkan setelah ditinjau admin. Label terverifikasi hanya diberikan melalui '
          'proses peninjauan tersebut. Data program pada versi demo adalah contoh.'
    ),
    (
      '5. Zakat',
      'Hasil kalkulator zakat bersifat perkiraan dan bukan fatwa. Konsultasikan ketentuan lengkap '
          'dengan lembaga amil zakat atau ustaz.'
    ),
    (
      '6. Perubahan ketentuan',
      'Ketentuan dapat diperbarui sewaktu-waktu. Perubahan penting akan diinformasikan melalui aplikasi.'
    ),
  ];

  static const List<(String, String)> _privacy = [
    (
      '1. Data yang dikumpulkan',
      'Nama, email, nomor HP (opsional), foto profil (opsional), dan riwayat donasi.'
    ),
    (
      '2. Penggunaan data',
      'Data dipakai untuk mengelola akun, mencatat donasi, menampilkan riwayat, dan mengirim '
          'notifikasi di dalam aplikasi.'
    ),
    (
      '3. Nama donatur',
      'Kamu bisa menyembunyikan identitas saat berdonasi. Nama yang tampil menjadi "Hamba Allah".'
    ),
    (
      '4. Keamanan data',
      'Password disimpan dalam bentuk terenkripsi (hash) pada sistem backend. Kami tidak menyimpan '
          'data kartu atau nomor rekening pembayaran.'
    ),
    (
      '5. Hak pengguna',
      'Kamu dapat melihat dan memperbarui data profil kapan saja melalui menu Profil Saya.'
    ),
    (
      '6. Kontak',
      'Pertanyaan tentang privasi dapat disampaikan melalui menu Bantuan & FAQ.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final s in sections) ...[
            Text(s.$1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(s.$2, style: const TextStyle(height: 1.55)),
            const SizedBox(height: 18),
          ],
          const Text(
            'Dokumen ini adalah draft untuk versi demo, bukan nasihat hukum.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}