import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/admin/core/admin_config.dart';
import 'package:sadaqo/admin/data/admin_credentials_store.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/community/domain/entities/moderation.dart';
import 'package:sadaqo/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sadaqo/features/profile/presentation/widgets/user_avatar.dart';
import 'package:sadaqo/injection_container.dart';

/// Pengaturan admin: profil, ganti password (berlaku untuk kedua email), dan info sistem.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _creds = sl<AdminCredentialsStore>();
  late final TextEditingController _name;
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _creds.adminName);
  }

  @override
  void dispose() {
    _name.dispose();
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _saveName() {
    if (_name.text.trim().isEmpty) {
      adminToast(context, 'Nama tidak boleh kosong');
      return;
    }
    _creds.setName(_name.text);
    adminToast(context, 'Nama admin disimpan');
  }

  void _changePassword() {
    final err = _creds.changePassword(
      current: _current.text,
      next: _next.text,
      confirm: _confirm.text,
    );
    setState(() => _error = err);
    if (err == null) {
      _current.clear();
      _next.clear();
      _confirm.clear();
      adminToast(context, 'Password diganti. Berlaku untuk kedua email admin.');
    }
  }

  Future<void> _pickAvatar() async {
    final p = await showAssetPicker(context, title: 'Pilih avatar admin', groups: const ['avatar']);
    if (p != null && mounted) context.read<ProfileCubit>().setAvatar(p);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.read<AuthCubit>().user?.email;
    return LayoutBuilder(
      builder: (context, c) {
        final pad = c.maxWidth < 600 ? 14.0 : 24.0;
        final wide = c.maxWidth >= 900;
        final profile = _profileCard(signedIn);
        final password = _passwordCard();
        final info = _infoCard();
        return ListView(
          padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
          children: [
            const PageHeader(title: 'Pengaturan', subtitle: 'Profil admin, keamanan, dan informasi sistem.'),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: [profile, const SizedBox(height: 16), info])),
                  const SizedBox(width: 16),
                  Expanded(child: password),
                ],
              )
            else
              Column(children: [profile, const SizedBox(height: 16), password, const SizedBox(height: 16), info]),
          ],
        );
      },
    );
  }

  Widget _profileCard(String? signedIn) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Profil Admin', icon: Icons.badge_outlined),
          const SizedBox(height: 14),
          Row(
            children: [
              ListenableBuilder(
                listenable: _creds,
                builder: (context, _) => UserAvatar(
                  initial: _creds.adminName.isEmpty ? 'A' : _creds.adminName[0].toUpperCase(),
                  radius: 34,
                ),
              ),
              const SizedBox(width: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminButton(label: 'Ganti Avatar', icon: Icons.face_rounded, outlined: true, onPressed: _pickAvatar),
                  AdminButton(
                    label: 'Hapus',
                    outlined: true,
                    danger: true,
                    onPressed: () => context.read<ProfileCubit>().removePhoto(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nama tampilan')),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AdminButton(label: 'Simpan Nama', icon: Icons.check_rounded, onPressed: _saveName),
          ),
          const SizedBox(height: 14),
          const Text('Email admin yang bisa masuk', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final e in AdminConfig.emails)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.alternate_email_rounded, size: 18, color: AdminColors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e)),
                  if (signedIn != null && signedIn.toLowerCase() == e)
                    const Pill('Sedang masuk', color: AdminColors.green, bg: AdminColors.limeSoft),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _passwordCard() {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Ganti Password', icon: Icons.lock_reset_rounded),
          const SizedBox(height: 6),
          const Text(
            'Password dipakai bersama oleh kedua email admin. Setelah diganti, kedua email wajib memakai password baru dan isi dashboard tetap sama.',
            style: TextStyle(fontSize: 12.5, color: AdminColors.muted),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _current,
            obscureText: !_show,
            decoration: const InputDecoration(labelText: 'Password saat ini'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _next,
            obscureText: !_show,
            decoration: InputDecoration(
              labelText: 'Password baru',
              helperText: 'Minimal ${AdminConfig.minPasswordLength} karakter',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: !_show,
            decoration: InputDecoration(
              labelText: 'Ulangi password baru',
              errorText: _error,
              errorMaxLines: 2,
            ),
          ),
          const SizedBox(height: 6),
          CheckboxListTile(
            value: _show,
            onChanged: (v) => setState(() => _show = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Tampilkan password', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: AdminButton(label: 'Ganti Password', icon: Icons.lock_outline_rounded, onPressed: _changePassword),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AdminColors.green),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
            ],
          ),
        );
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Aturan Sistem', icon: Icons.rule_rounded),
          const SizedBox(height: 10),
          line(Icons.security_rounded,
              'Banned otomatis: pelanggaran ke-${CommunityPolicy.strikesBeforeBan} dibanned ${CommunityPolicy.banDays} hari. Admin bisa mengubah durasi atau membebaskannya kapan saja.'),
          line(Icons.edit_note_rounded, 'Panjang pesan Komunitas maksimal ${CommunityPolicy.maxMessageLength} karakter.'),
          line(Icons.receipt_long_rounded, 'Transaksi donatur hanya bisa dilihat. Admin tidak bisa mengubah atau menghapusnya.'),
          line(Icons.sync_rounded, 'Data dashboard sama untuk kedua email admin (satu akun, dua pintu masuk).'),
        ],
      ),
    );
  }
}
