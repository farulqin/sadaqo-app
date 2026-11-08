import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/auth/domain/entities/gender.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/profile/presentation/cubit/profile_cubit.dart';

/// Pilihan foto profil: galeri, avatar sesuai jenis kelamin, atau hapus foto.
class PhotoPickerSheet extends StatelessWidget {
  const PhotoPickerSheet({super.key});

  Future<void> _pickFromGallery(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Foto galeri wajib mengikuti ketentuan; pemeriksaan otomatis butuh server.
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ketentuan Foto Profil'),
        content: const Text(
          'Gunakan foto yang sopan dan pantas. Dilarang memakai foto bermuatan '
          'pornografi, penistaan agama, kekerasan, atau ujaran kebencian. '
          'Pelanggaran dapat membuat akunmu ditindak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Saya Setuju'),
          ),
        ],
      ),
    );
    if (agreed != true) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await cubit.setGalleryPhoto(bytes);
      navigator.pop();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal membuka galeri')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final hasPhoto = cubit.state.photo != null;
    final gender = context.read<AuthCubit>().user?.gender;

    // Avatar hanya yang sesuai jenis kelamin. Jika belum dipilih, tampilkan semua.
    final avatars = gender == Gender.male
        ? AppAssets.avatarsMale
        : gender == Gender.female
            ? AppAssets.avatarsFemale
            : AppAssets.avatars;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sandBeige,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Foto Profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sandBeige,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 18, color: AppColors.forestGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      gender == null
                          ? 'Pilih jenis kelamin di Profil Saya agar avatar yang '
                              'tampil sesuai.'
                          : 'Saran: gunakan foto atau avatar yang sesuai dengan jenis '
                              'kelamin yang kamu pilih (${gender.label}).',
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.forestGreen),
              title: const Text('Pilih dari galeri'),
              onTap: () => _pickFromGallery(context),
            ),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              gender == null ? 'Atau pilih avatar' : 'Atau pilih avatar (${gender.label})',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final path in avatars)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      cubit.setAvatar(path);
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.sandBeige,
                      backgroundImage: AssetImage(path),
                    ),
                  ),
              ],
            ),
            if (hasPhoto) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Hapus foto', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  cubit.removePhoto();
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}