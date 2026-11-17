import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/community_feed/presentation/cubit/community_feed_cubit.dart';
import 'package:sadaqo/features/community_feed/presentation/widgets/community_widgets.dart';

/// Buat post: kategori, tulisan, foto, dan polling opsional.
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _form = GlobalKey<FormState>();
  final _body = TextEditingController();
  final _question = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
  ];

  String _category = 'diskusi';
  Uint8List? _image;
  bool _withPoll = false;
  int _days = 3;
  bool _sending = false;

  @override
  void dispose() {
    _body.dispose();
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _image = bytes);
    } catch (_) {
      if (mounted) showCommunitySnack(context, 'Gagal membuka galeri. Coba lagi.');
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    final err = await context.read<CommunityFeedCubit>().createPost(
          category: _category,
          body: _body.text.trim(),
          imageBytes: _image,
          pollQuestion: _withPoll ? _question.text.trim() : null,
          pollOptions: _withPoll ? [for (final c in _options) c.text.trim()] : const [],
          pollDays: _days,
        );
    if (!mounted) return;
    if (err != null) {
      setState(() => _sending = false);
      showCommunitySnack(context, err);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().user;
    final isStaff = (user?.isAdmin ?? false) || (user?.isManager ?? false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        title: const Text('Buat Post'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                const DropdownMenuItem(value: 'diskusi', child: Text('Diskusi')),
                if (isStaff) const DropdownMenuItem(value: 'info', child: Text('Info / Pengumuman')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'diskusi'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              minLines: 5,
              maxLines: 10,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Tulis pesanmu di sini...',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Tulisan tidak boleh kosong';
                if (t.length < 3) return 'Minimal 3 karakter';
                return null;
              },
            ),
            if (_image != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(_image!, width: double.infinity, height: 190, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        color: Colors.white,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _image = null),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _sending ? null : _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(_image == null ? 'Tambah Foto' : 'Ganti Foto'),
                ),
              ],
            ),
            const Divider(height: 28),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.forestGreen,
              title: const Text('Tambahkan Polling', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Opsional'),
              value: _withPoll,
              onChanged: _sending ? null : (v) => setState(() => _withPoll = v),
            ),
            if (_withPoll) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _question,
                decoration: const InputDecoration(labelText: 'Pertanyaan polling'),
                validator: (v) {
                  if (!_withPoll) return null;
                  final t = (v ?? '').trim();
                  if (t.length < 5) return 'Pertanyaan minimal 5 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < _options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _options[i],
                          maxLength: 100,
                          decoration: InputDecoration(labelText: 'Opsi ${i + 1}', counterText: ''),
                          validator: (v) {
                            if (!_withPoll) return null;
                            return (v ?? '').trim().isEmpty ? 'Opsi tidak boleh kosong' : null;
                          },
                        ),
                      ),
                      if (_options.length > 2)
                        IconButton(
                          tooltip: 'Hapus opsi',
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          onPressed: () => setState(() => _options.removeAt(i).dispose()),
                        ),
                    ],
                  ),
                ),
              if (_options.length < 6)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _options.add(TextEditingController())),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Opsi'),
                  ),
                ),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                initialValue: _days,
                decoration: const InputDecoration(labelText: 'Batas waktu polling'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 hari')),
                  DropdownMenuItem(value: 3, child: Text('3 hari')),
                  DropdownMenuItem(value: 7, child: Text('7 hari')),
                  DropdownMenuItem(value: 14, child: Text('14 hari')),
                ],
                onChanged: (v) => setState(() => _days = v ?? 3),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _sending ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.forestGreen),
                child: Text(_sending ? 'Memposting...' : 'Posting'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jaga adab: tanpa hoaks, ujaran kebencian, penipuan, atau konten dewasa. Pelanggaran pertama mendapat peringatan, pelanggaran kedua dibanned 30 hari.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}