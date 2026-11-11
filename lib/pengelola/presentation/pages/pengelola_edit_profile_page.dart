import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/auth/presentation/pages/login_page.dart';
import 'package:sadaqo/features/profile/presentation/widgets/user_avatar.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/pengelola/core/pengelola_config.dart';
import 'package:sadaqo/pengelola/core/pengelola_layout.dart';
import 'package:sadaqo/pengelola/data/pengelola_account_store.dart';

/// Edit profil pengelola. Nama dan nomor telepon WAJIB diisi agar admin bisa
/// menghubungi pengelola (tim teknis SADAQO).
/// [forced] = true: dibuka otomatis saat profil belum lengkap dan tidak bisa ditutup
/// sebelum disimpan (hanya bisa keluar dari akun).
class PengelolaEditProfilePage extends StatefulWidget {
  const PengelolaEditProfilePage({super.key, this.forced = false});

  final bool forced;

  @override
  State<PengelolaEditProfilePage> createState() => _PengelolaEditProfilePageState();
}

class _PengelolaEditProfilePageState extends State<PengelolaEditProfilePage> {
  final _form = GlobalKey<FormState>();
  final _account = sl<PengelolaAccountStore>();
  late final TextEditingController _name = TextEditingController(text: _account.name);
  late final TextEditingController _phone = TextEditingController(text: _account.phone);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await context.read<AuthCubit>().updateProfile(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(true);
    messenger.showSnackBar(
      const SnackBar(content: Text('Profil disimpan. Admin dapat melihat data ini.')),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthCubit>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().user;
    return PopScope(
      canPop: !widget.forced,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.forced ? 'Lengkapi Profil' : 'Edit Profil'),
          automaticallyImplyLeading: !widget.forced,
        ),
        body: Form(
          key: _form,
          child: ContentListView(
            maxWidth: 560,
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: UserAvatar(initial: user?.initial ?? 'P', radius: 46)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.success),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nama dan nomor telepon wajib diisi agar Admin SADAQO dapat '
                        'menghubungi kamu sebagai tim teknis.',
                        style: TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap *',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: PengelolaAccountStore.validateName,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))],
                decoration: const InputDecoration(
                  labelText: 'Nomor telepon / WhatsApp *',
                  hintText: '0812-3456-7890',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: PengelolaAccountStore.validatePhone,
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: user?.email ?? PengelolaConfig.email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email (tidak dapat diubah)',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: PengelolaConfig.roleLabel,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Peran',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.forced ? 'Simpan & Lanjutkan' : 'Simpan'),
              ),
              if (widget.forced)
                TextButton(
                  onPressed: _logout,
                  child: const Text('Keluar dari akun'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}