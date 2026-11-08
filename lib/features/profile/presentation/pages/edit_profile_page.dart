import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/auth/domain/entities/gender.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:sadaqo/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sadaqo/features/profile/presentation/widgets/photo_picker_sheet.dart';
import 'package:sadaqo/features/profile/presentation/widgets/user_avatar.dart';

/// "Profil Saya": ubah foto, nama, jenis kelamin, dan nomor HP. Email tidak dapat diubah.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  Gender? _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _gender = user?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final error = await context.read<AuthCubit>().updateProfile(
          name: _nameController.text,
          phone: _phoneController.text,
          gender: _gender,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Jika avatar yang terpasang tidak sesuai jenis kelamin baru, foto dilepas.
    final profile = context.read<ProfileCubit>();
    final asset = profile.state.photo?.avatarAsset;
    if (asset != null && _gender != null) {
      final allowed =
          _gender == Gender.male ? AppAssets.avatarsMale : AppAssets.avatarsFemale;
      if (!allowed.contains(asset)) profile.removePhoto();
    }

    context.read<NotificationCubit>().add(
          title: 'Profil diperbarui',
          body: 'Perubahan data profilmu berhasil disimpan.',
        );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profil berhasil disimpan')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const PhotoPickerSheet(),
              ),
              child: Stack(
                children: [
                  UserAvatar(initial: user?.initial ?? '?', radius: 52),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Ketuk foto untuk mengganti (galeri atau avatar)',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama lengkap',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Jenis kelamin',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final g in Gender.values)
                ChoiceChip(
                  label: Text(g.label),
                  selected: _gender == g,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _gender = g),
                  selectedColor: AppColors.forestGreen,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _gender == g ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Dipakai untuk menyarankan foto dan avatar yang sesuai.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: user?.email ?? ''),
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              helperText: 'Email tidak dapat diubah',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor HP (opsional)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }
}