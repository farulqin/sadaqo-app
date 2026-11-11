import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/app_info.dart';
import 'package:sadaqo/core/utils/clipboard_helper.dart';
import 'package:sadaqo/features/profile/presentation/pages/about_page.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/pengelola/core/pengelola_layout.dart';
import 'package:sadaqo/pengelola/data/pengelola_account_store.dart';
import 'package:sadaqo/pengelola/presentation/widgets/pengelola_widgets.dart';

/// Pengaturan pengelola: keamanan (ganti password), notifikasi, bantuan, tentang.
class PengelolaSettingsPage extends StatelessWidget {
  const PengelolaSettingsPage({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Password berhasil diganti. Gunakan saat masuk berikutnya.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = sl<PengelolaAccountStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ContentListView(
        maxWidth: 720,
        children: [
          _Group(
            title: 'Keamanan',
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded, color: AppColors.forestGreen),
                title: const Text('Ganti Password'),
                subtitle: const Text('Disarankan diganti secara berkala'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _changePassword(context),
              ),
            ],
          ),
          _Group(
            title: 'Notifikasi',
            children: [
              ListenableBuilder(
                listenable: account,
                builder: (context, _) => SwitchListTile(
                  value: account.notificationsEnabled,
                  onChanged: account.setNotifications,
                  secondary: const Icon(Icons.notifications_active_outlined,
                      color: AppColors.forestGreen),
                  title: const Text('Penanda pemberitahuan'),
                  subtitle: const Text('Titik merah di lonceng beranda'),
                ),
              ),
            ],
          ),
          _Group(
            title: 'Bantuan',
            children: [
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded, color: AppColors.forestGreen),
                title: const Text('Email Admin SADAQO'),
                subtitle: const Text(AppInfo.email),
                onTap: () => copyToClipboard(context, 'Email', AppInfo.email),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.chat_outlined, color: AppColors.forestGreen),
                title: const Text('WhatsApp Admin SADAQO'),
                subtitle: const Text(AppInfo.whatsapp),
                onTap: () => copyToClipboard(context, 'Nomor WhatsApp', AppInfo.whatsapp),
              ),
            ],
          ),
          _Group(
            title: 'Aplikasi',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: AppColors.forestGreen),
                title: const Text('Tentang SADAQO'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutPage()),
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.verified_outlined, color: AppColors.forestGreen),
                title: Text('Versi Aplikasi'),
                trailing: Text('Version ${AppInfo.version}'),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.forestGreen,
              ),
            ),
          ),
          SoftCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(children: children),
            ),
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
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final error = sl<PengelolaAccountStore>().changePassword(
      current: _current.text,
      next: _next.text,
      confirm: _confirm.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _show = !_show),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ganti Password'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _current,
                obscureText: !_show,
                decoration: _deco('Password saat ini'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _next,
                obscureText: !_show,
                decoration: _deco('Password baru (min. ${PengelolaAccountStore.minPasswordLength} karakter)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirm,
                obscureText: !_show,
                decoration: _deco('Ulangi password baru'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}