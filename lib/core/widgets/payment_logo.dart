import 'package:flutter/material.dart';

/// Logo penyedia pembayaran (e-wallet, bank, QRIS).
///
/// Memakai file `assets/images/payment/<nama>.png` bila ada (logo resmi, lihat
/// README di folder itu). Jika tidak ada, tampil lencana berwarna merek.
class PaymentLogo extends StatelessWidget {
  const PaymentLogo(this.name, {super.key, this.height = 30});

  final String name;
  final double height;

  static String slug(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static const _brands = <String, _Brand>{
    'dana': _Brand('DANA', Color(0xFF118EEA), Colors.white),
    'gopay': _Brand('GoPay', Color(0xFF00AED6), Colors.white),
    'ovo': _Brand('OVO', Color(0xFF4C3494), Colors.white),
    'shopeepay': _Brand('ShopeePay', Color(0xFFEE4D2D), Colors.white),
    'linkaja': _Brand('LinkAja', Color(0xFFE82529), Colors.white),
    'qris': _Brand('QRIS', Color(0xFFE31E25), Colors.white),
    'bca': _Brand('BCA', Color(0xFF0060AF), Colors.white),
    'mandiri': _Brand('mandiri', Color(0xFF003D79), Color(0xFFFFB81C)),
    'bri': _Brand('BRI', Color(0xFF00529C), Colors.white),
    'bni': _Brand('BNI', Color(0xFFF15A23), Colors.white),
    'bsi': _Brand('BSI', Color(0xFF00A39D), Colors.white),
    'cimbniaga': _Brand('CIMB', Color(0xFF7B0D1E), Colors.white),
    'permata': _Brand('PermataBank', Color(0xFF3FA535), Colors.white),
    'btn': _Brand('BTN', Color(0xFFFFC20E), Color(0xFF004B8D)),
    'danamon': _Brand('Danamon', Color(0xFFF58220), Colors.white),
    'mega': _Brand('MEGA', Color(0xFF0054A6), Colors.white),
    'jatim': _Brand('Bank Jatim', Color(0xFF0F4C81), Colors.white),
  };

  @override
  Widget build(BuildContext context) {
    final key = slug(name);
    final width = height * 1.7;
    final brand = _brands[key] ?? _Brand(name, const Color(0xFF1F3D2B), Colors.white);
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/images/payment/$key.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: height * 0.15),
          decoration: BoxDecoration(
            color: brand.bg,
            borderRadius: BorderRadius.circular(height * 0.22),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              brand.text,
              maxLines: 1,
              style: TextStyle(
                color: brand.fg,
                fontWeight: FontWeight.w800,
                fontSize: height * 0.42,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand {
  const _Brand(this.text, this.bg, this.fg);

  final String text;
  final Color bg;
  final Color fg;
}
