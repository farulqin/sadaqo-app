import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/auth/presentation/pages/login_page.dart';
import 'package:sadaqo/features/profile/presentation/widgets/user_avatar.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/pengelola/core/pengelola_config.dart';
import 'package:sadaqo/pengelola/data/pengelola_store.dart';
import 'package:sadaqo/pengelola/presentation/widgets/pengelola_widgets.dart';

class PengelolaProfilePage extends StatelessWidget {
  const PengelolaProfilePage({super.key});

  static const _steps = [
    ('Membuat kampanye', 'Isi nama, kategori, deskripsi, target dana, foto, dan informasi pendukung.'),
    ('Mengirim pengajuan', 'Kampanye dikirim ke Admin untuk diverifikasi.'),
    ('Menunggu persetujuan', 'Admin menyetujui atau meminta revisi. Pengajuan bisa diperbaiki.'),
    ('Memantau kampanye', 'Setelah dipublikasikan, pantau progres dana dan jumlah donatur.'),
    ('Mengirim dokumentasi', 'Unggah foto kegiatan, bukti penyaluran, dan laporan kepada Admin.'),
    ('Menunggu pemeriksaan laporan', 'Admin memeriksa dokumentasi sebelum laporan ditampilkan kepada donatur.'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().user;
    final store = sl<PengelolaStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                UserAvatar(initial: user?.initial ?? 'P', radius: 42),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? PengelolaConfig.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(user?.email ?? PengelolaConfig.email, style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDEFC6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    PengelolaConfig.roleLabel,
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${store.totalPrograms} program dikelola',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SoftCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              leading: const Icon(Icons.route_rounded, color: AppColors.forestGreen),
              title: const Text('Alur Kerja Pengelola', style: TextStyle(fontWeight: FontWeight.w800)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              children: [
                for (var i = 0; i < _steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.forestGreen,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_steps[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                _steps[i].$2,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthCubit>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}