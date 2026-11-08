import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/navigation/main_tab_controller.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/auth/presentation/pages/login_page.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_state.dart';
import 'package:sadaqo/features/favorite/presentation/pages/favorites_page.dart';
import 'package:sadaqo/features/profile/presentation/pages/about_page.dart';
import 'package:sadaqo/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:sadaqo/features/profile/presentation/pages/help_page.dart';
import 'package:sadaqo/features/profile/presentation/pages/settings_page.dart';
import 'package:sadaqo/features/profile/presentation/widgets/photo_picker_sheet.dart';
import 'package:sadaqo/features/profile/presentation/widgets/user_avatar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onNavigateTab});

  final ValueChanged<int> onNavigateTab;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().user;
    final history = context.watch<DonationHistoryCubit>().state;
    final total = history is DonationHistoryLoaded ? history.totalSuccess : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            children: [
              GestureDetector(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const PhotoPickerSheet(),
                ),
                child: Stack(
                  children: [
                    UserAvatar(initial: user?.initial ?? '?', radius: 44),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.forestGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user?.name ?? '-',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                user?.email ?? '-',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.forestGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: AppColors.limeGreen, size: 30),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Donasi',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      Formatter.rupiah(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Material (bukan Container) agar efek tekan ListTile terlihat.
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _MenuTile(
                  Icons.person_outline,
                  'Profil Saya',
                  () => _open(context, const EditProfilePage()),
                ),
                _MenuTile(
                  Icons.receipt_long_outlined,
                  'Riwayat Donasi',
                  () => onNavigateTab(MainTabController.history),
                ),
                _MenuTile(
                  Icons.favorite_border,
                  'Program Favorit',
                  () => _open(context, const FavoritesPage()),
                ),
                _MenuTile(
                  Icons.settings_outlined,
                  'Pengaturan',
                  () => _open(context, const SettingsPage()),
                ),
                _MenuTile(
                  Icons.help_outline,
                  'Bantuan & FAQ',
                  () => _open(context, const HelpPage()),
                ),
                _MenuTile(
                  Icons.info_outline,
                  'Tentang SADAQO',
                  () => _open(context, const AboutPage()),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthCubit>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
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

class _MenuTile extends StatelessWidget {
  const _MenuTile(this.icon, this.label, this.onTap, {this.last = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.forestGreen),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        if (!last) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}