import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/app_info.dart';
import 'package:sadaqo/core/utils/clipboard_helper.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const List<(String, String)> _faqs = [
    (
      'Apa itu SADAQO?',
      'SADAQO adalah aplikasi penggalangan dana komunitas untuk masjid dan mushola, '
          'bantuan sosial, zakat, kaum duafa, dan qurban bersama.'
    ),
    (
      'Bagaimana cara berdonasi?',
      'Pilih program (lewat Beranda, Program, atau tab Donasi), tentukan nominal, '
          'pilih metode pembayaran, lalu selesaikan pembayaran. Hasilnya langsung tercatat di Riwayat.'
    ),
    (
      'Berapa minimal donasi?',
      'Minimal semua transaksi adalah Rp 5.000. Zakat dikecualikan karena nominalnya '
          'dihitung kalkulator sesuai harta dan ketentuannya.'
    ),
    (
      'Metode pembayaran apa saja yang tersedia?',
      'QRIS (kode QR), E-Wallet (DANA, GoPay, OVO, ShopeePay, LinkAja), dan Transfer Bank '
          '(BCA, Mandiri, BRI, BNI, BSI, CIMB Niaga, Permata, BTN, Danamon, Mega, Jatim).'
    ),
    (
      'Bagaimana cara menghitung zakat?',
      'Buka menu Zakat di Beranda. Zakat fitrah dihitung dari jumlah jiwa dan disalurkan dalam '
          'bentuk beras. Zakat maal (penghasilan, tabungan, emas) disalurkan dalam bentuk uang. '
          'Hasilnya perkiraan dan bukan fatwa.'
    ),
    (
      'Apa bedanya qurban per orang, kolektif, dan bersama?',
      'Per orang: satu hewan untuk satu orang. Kolektif: satu hewan dipatungi 7 orang dengan '
          'kuota slot. Bersama: peserta tidak terbatas dengan nominal bebas sampai target dana tercapai.'
    ),
    (
      'Bagaimana jika saya ingin berdonasi tanpa nama?',
      'Nyalakan "Sembunyikan nama saya" saat berdonasi, atau aktifkan sebagai bawaan di '
          'Pengaturan. Namamu akan tampil sebagai "Hamba Allah".'
    ),
    (
      'Bagaimana memantau donasi saya?',
      'Buka tab Riwayat untuk melihat semua donasi. Konfirmasi juga masuk ke Notifikasi '
          '(ikon lonceng di Beranda).'
    ),
    (
      'Apakah transaksi di aplikasi ini sungguhan?',
      'Belum. Versi ini adalah aplikasi demo, sehingga pembayaran bersifat simulasi dan tidak ada '
          'uang yang berpindah.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan & FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pertanyaan Umum',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++) ...[
                  ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    title: Text(
                      _faqs[i].$1,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    children: [
                      Text(_faqs[i].$2, style: const TextStyle(height: 1.5)),
                    ],
                  ),
                  if (i != _faqs.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Masih butuh bantuan?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.mail_outline, color: AppColors.forestGreen),
                  title: const Text('Email CS'),
                  subtitle: const Text(AppInfo.email),
                  trailing: const Icon(Icons.copy, size: 18),
                  onTap: () => copyToClipboard(context, 'Email', AppInfo.email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_outlined, color: AppColors.forestGreen),
                  title: const Text('WhatsApp CS'),
                  subtitle: const Text(AppInfo.whatsapp),
                  trailing: const Icon(Icons.copy, size: 18),
                  onTap: () => copyToClipboard(context, 'Nomor WhatsApp', AppInfo.whatsapp),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kontak di atas adalah contoh untuk versi demo. Ketuk untuk menyalin.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}