import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/app_info.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:sadaqo/features/profile/presentation/cubit/settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (ok == true && context.mounted) {
      context.read<NotificationCubit>().add(
            title: 'Password diperbarui',
            body: 'Password akunmu berhasil diubah.',
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah (simulasi)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          final cubit = context.read<SettingsCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Group(
                title: 'Notifikasi',
                children: [
                  SwitchListTile(
                    value: settings.notificationsEnabled,
                    onChanged: cubit.setNotifications,
                    secondary: const Icon(Icons.notifications_active_outlined,
                        color: AppColors.forestGreen),
                    title: const Text('Notifikasi di aplikasi'),
                    subtitle: const Text('Ucapan, konfirmasi donasi, dan info akun'),
                  ),
                ],
              ),
              _Group(
                title: 'Privasi donasi',
                children: [
                  SwitchListTile(
                    value: settings.hideNameByDefault,
                    onChanged: cubit.setHideNameByDefault,
                    secondary: const Icon(Icons.visibility_off_outlined,
                        color: AppColors.forestGreen),
                    title: const Text('Sembunyikan nama saya'),
                    subtitle: const Text(
                      'Donasi baru otomatis atas nama "Hamba Allah". '
                      'Tetap bisa diubah saat berdonasi.',
                    ),
                  ),
                ],
              ),
              _Group(
                title: 'Akun',
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.forestGreen),
                    title: const Text('Ubah password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _changePassword(context),
                  ),
                ],
              ),
              const _Group(
                title: 'Umum',
                children: [
                  ListTile(
                    leading: Icon(Icons.language, color: AppColors.forestGreen),
                    title: Text('Bahasa'),
                    trailing: Text('Indonesia'),
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: AppColors.forestGreen),
                    title: Text('Versi aplikasi'),
                    trailing: Text(AppInfo.version),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Pengaturan tersimpan selama aplikasi terbuka. Setelah backend siap, '
                  'pengaturan akan tersimpan di akunmu.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (_old.text.isEmpty) {
      setState(() => _error = 'Isi password saat ini');
    } else if (_new.text.length < 6) {
      setState(() => _error = 'Password baru minimal 6 karakter');
    } else if (_new.text != _confirm.text) {
      setState(() => _error = 'Konfirmasi password tidak sama');
    } else if (_new.text == _old.text) {
      setState(() => _error = 'Password baru harus berbeda dari yang lama');
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _old,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password saat ini'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _new,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password baru'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Ulangi password baru'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        TextButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}