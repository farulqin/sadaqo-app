import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/auth/presentation/pages/login_page.dart';
import 'package:sadaqo/features/profile/presentation/pages/about_page.dart';
import 'package:sadaqo/features/profile/presentation/widgets/user_avatar.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/pengelola/core/pengelola_config.dart';
import 'package:sadaqo/pengelola/core/pengelola_layout.dart';
import 'package:sadaqo/pengelola/data/pengelola_account_store.dart';
import 'package:sadaqo/pengelola/data/pengelola_store.dart';
import 'package:sadaqo/pengelola/presentation/pages/pengelola_edit_profile_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/pengelola_settings_page.dart';
import 'package:sadaqo/pengelola/presentation/widgets/pengelola_widgets.dart';

/// Profil pengelola: identitas, Edit Profil, Pengaturan, Tentang SADAQO, Keluar.
class PengelolaProfilePage extends StatelessWidget {
  const PengelolaProfilePage({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthCubit>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().user;
    final store = sl<PengelolaStore>();
    final account = sl<PengelolaAccountStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListenableBuilder(
        listenable: account,
        builder: (context, _) {
          final identity = _IdentityCard(
            initial: user?.initial ?? 'P',
            name: account.name,
            email: user?.email ?? PengelolaConfig.email,
            phone: account.phoneOrNull,
            programs: store.totalPrograms,
            complete: account.isProfileComplete,
          );

          final menu = Column(
            children: [
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profil',
                      subtitle: 'Nama dan nomor telepon',
                      onTap: () => _push(context, const PengelolaEditProfilePage()),
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.settings_outlined,
                      title: 'Pengaturan',
                      subtitle: 'Ganti password, notifikasi, bantuan',
                      onTap: () => _push(context, const PengelolaSettingsPage()),
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Tentang SADAQO',
                      subtitle: 'Identitas, visi, dan kontak SADAQO',
                      onTap: () => _push(context, const AboutPage()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _logout(context),
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
          );

          return ContentListView(
            maxWidth: 980,
            padding: const EdgeInsets.all(16),
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth < 760) {
                    return Column(children: [identity, const SizedBox(height: 16), menu]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 340, child: identity),
                      const SizedBox(width: 20),
                      Expanded(child: menu),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.initial,
    required this.name,
    required this.email,
    required this.phone,
    required this.programs,
    required this.complete,
  });

  final String initial;
  final String name;
  final String email;
  final String? phone;
  final int programs;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          UserAvatar(initial: initial, radius: 42),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(email, style: const TextStyle(color: AppColors.textMuted)),
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
          const Divider(height: 1),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.phone_rounded,
            text: phone ?? 'Nomor telepon belum diisi',
            warn: phone == null,
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.campaign_rounded, text: '$programs program dikelola'),
          if (!complete) ...[
            const SizedBox(height: 12),
            const Text(
              'Lengkapi profil agar admin bisa menghubungi kamu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.warn = false});

  final IconData icon;
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: warn ? AppColors.error : AppColors.forestGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              color: warn ? AppColors.error : AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.limeGreen.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.forestGreen),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
    );
  }
}