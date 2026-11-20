// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/navigation/main_tab_controller.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/core/constants/app_colors.dart';

/// Kembali ke Beranda dari halaman mana pun: tutup semua halaman yang
/// ditumpuk lalu pindahkan tab ke Beranda.
void goToHome(BuildContext context) {
  sl<MainTabController>().index.value = MainTabController.home;
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// Logo SADAQO (emblem) dalam lingkaran putih, untuk pojok kiri atas.
/// Bila diketuk, aplikasi kembali ke Beranda.
class SadaqoLogo extends StatelessWidget {
  const SadaqoLogo({super.key, this.size = 38, this.onTap});

  final double size;

  /// Bawaan: [goToHome].
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ke Beranda',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap ?? () => goToHome(context),
          child: Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.14),
            decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: Image.asset(AppAssets.logoEmblem, fit: BoxFit.contain),
          ),
        ),
      ),
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