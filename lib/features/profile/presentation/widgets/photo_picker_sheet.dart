import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/profile/presentation/cubit/profile_cubit.dart';

/// Pilihan foto profil: dari galeri, avatar bawaan, atau hapus foto.
class PhotoPickerSheet extends StatelessWidget {
  const PhotoPickerSheet({super.key});

  Future<void> _pickFromGallery(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
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
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.forestGreen),
              title: const Text('Pilih dari galeri'),
              onTap: () => _pickFromGallery(context),
            ),
            const Divider(),
            const SizedBox(height: 4),
            const Text(
              'Atau pilih avatar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final path in AppAssets.avatars)
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