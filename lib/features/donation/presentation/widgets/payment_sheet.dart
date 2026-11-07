import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';

/// Langkah pembayaran (SIMULASI). Mengembalikan true jika donatur menekan
/// "Saya Sudah Membayar", false jika dibatalkan.
/// - QRIS: menampilkan kode QR untuk dipindai.
/// - E-Wallet: petunjuk membuka aplikasi e-wallet terpilih.
/// - Transfer Bank: menampilkan kode pembayaran contoh.
class PaymentSheet extends StatefulWidget {
  const PaymentSheet({
    super.key,
    required this.method,
    required this.provider,
    required this.amount,
    required this.title,
  });

  final PaymentMethod method;
  final String? provider;
  final int amount;
  final String title;

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  late final String _ref =
      'SDQ${(DateTime.now().millisecondsSinceEpoch % 100000000).toString().padLeft(8, '0')}';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sandBeige,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selesaikan Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              Formatter.rupiah(widget.amount),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 16),
            _body(),
            const SizedBox(height: 12),
            const Text(
              'Simulasi: tidak ada uang sungguhan yang berpindah.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Saya Sudah Membayar (Simulasi)'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (widget.method) {
      case PaymentMethod.qris:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sandBeige),
              ),
              child: QrImageView(
                data: 'SADAQO-DEMO|$_ref|${widget.amount}',
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pindai kode QRIS ini dengan aplikasi e-wallet atau m-banking',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kode contoh untuk simulasi, tidak dapat dibayar sungguhan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              'Kode referensi: $_ref',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        );
      case PaymentMethod.ewallet:
        return _panel(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Bayar dengan ${widget.provider}',
          text: 'Buka aplikasi ${widget.provider}, lalu konfirmasi pembayaran '
              'sesuai nominal di atas.',
        );
      case PaymentMethod.transfer:
        return _panel(
          icon: Icons.account_balance_outlined,
          title: 'Transfer melalui Bank ${widget.provider}',
          text: 'Gunakan kode pembayaran contoh berikut pada m-banking:',
          code: _ref,
        );
    }
  }

  Widget _panel({
    required IconData icon,
    required String title,
    required String text,
    String? code,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBeige),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.forestGreen),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(height: 1.4)),
          if (code != null) ...[
            const SizedBox(height: 10),
            SelectableText(
              code,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: AppColors.forestGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }
}