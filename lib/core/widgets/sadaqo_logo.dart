import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_assets.dart';

/// Logo SADAQO (emblem) dalam lingkaran putih, untuk pojok kiri atas.
class SadaqoLogo extends StatelessWidget {
  const SadaqoLogo({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Image.asset(AppAssets.logoEmblem, fit: BoxFit.contain),
    );
  }
}

/// True bila halaman ini adalah tab utama (bukan halaman yang di-push).
/// Dipakai agar logo hanya menggantikan tombol kembali di tab utama.
bool isMainTab(BuildContext context) => !(ModalRoute.of(context)?.canPop ?? false);

/// Leading AppBar berisi logo SADAQO. Pasangkan dengan [sadaqoLeadingWidth].
Widget? sadaqoLeading(BuildContext context) =>
    isMainTab(context) ? const Padding(padding: EdgeInsets.only(left: 14), child: Center(child: SadaqoLogo(size: 36))) : null;

double? sadaqoLeadingWidth(BuildContext context) => isMainTab(context) ? 64 : null;
