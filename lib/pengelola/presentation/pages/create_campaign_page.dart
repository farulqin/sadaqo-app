import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sadaqo/admin/data/admin_activity_log.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/pengelola/core/pengelola_config.dart';

/// Formulir buat kampanye (alur pengelola nomor 1-2): isi data, lalu kirim ke
/// Admin untuk diverifikasi. Jika [editing] diisi, formulir terisi data lama
/// untuk diperbaiki setelah admin meminta revisi.
class CreateCampaignPage extends StatefulWidget {
  const CreateCampaignPage({super.key, this.editing});

  final CampaignSubmission? editing;

  @override
  State<CreateCampaignPage> createState() => _CreateCampaignPageState();
}

class _CreateCampaignPageState extends State<CreateCampaignPage> {
  static const List<int> _durations = [15, 30, 45, 60, 90, 120];

  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _target;
  late final TextEditingController _info;

  late ProgramCategory _category;
  late int _days;
  Uint8List? _cover;
  bool _sending = false;

  /// Zakat bukan kampanye galang dana, jadi tidak ditawarkan.
  final List<ProgramCategory> _categories =
      ProgramCategory.values.where((c) => c != ProgramCategory.zakat).toList();

  @override
  void initState() {
    super.initState();
    final s = widget.editing;
    _title = TextEditingController(text: s?.title);
    _location = TextEditingController(text: s?.location);
    _description = TextEditingController(text: s?.description);
    _target = TextEditingController(text: s?.targetAmount.toString());
    _info = TextEditingController(text: s?.supportingInfo);
    _category = _categories.contains(s?.category) ? s!.category : _categories.first;
    _days = _durations.contains(s?.durationDays) ? s!.durationDays : 30;
    _cover = s?.imageBytes;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    _target.dispose();
    _info.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _cover = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka galeri')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 700)); // simulasi kirim
    if (!mounted) return;

    final store = sl<AdminVerificationStore>();
    final base = widget.editing;
    final submission = CampaignSubmission(
      id: base?.id ?? store.nextId(),
      title: _title.text.trim(),
      category: _category,
      organizer: PengelolaConfig.name,
      location: _location.text.trim(),
      description: _description.text.trim(),
      targetAmount: int.parse(_target.text.trim()),
      durationDays: _days,
      submittedAt: DateTime.now(),
      imageBytes: _cover,
      supportingInfo: _info.text.trim(),
      ownerId: PengelolaConfig.accountId,
    );
    if (base == null) {
      store.submit(submission);
    } else {
      store.resubmit(submission);
    }
    sl<AdminActivityLog>().add(
      ActivityKind.verified,
      base == null
          ? 'Pengajuan baru "${submission.title}" dari pengelola'
          : 'Pengajuan "${submission.title}" diperbaiki pengelola',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing;
    return Scaffold(
      appBar: AppBar(title: Text(editing == null ? 'Buat Kampanye' : 'Perbaiki Pengajuan')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (editing?.note != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8DEDB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Admin',
                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.error),
                    ),
                    const SizedBox(height: 4),
                    Text(editing!.note!),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.success),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kampanye diverifikasi Admin dulu. Setelah disetujui, kampanye tampil di aplikasi donatur.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            _label('Nama kampanye'),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Contoh: Renovasi Mushola Al-Hikmah'),
              validator: (v) =>
                  (v == null || v.trim().length < 8) ? 'Nama minimal 8 karakter' : null,
            ),
            _label('Kategori'),
            DropdownButtonFormField<ProgramCategory>(
              initialValue: _category,
              isExpanded: true,
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            _label('Lokasi'),
            TextFormField(
              controller: _location,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Contoh: Kediri, Jawa Timur'),
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Isi lokasi kampanye' : null,
            ),
            _label('Deskripsi'),
            TextFormField(
              controller: _description,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Jelaskan latar belakang, tujuan, dan rencana penggunaan dana.',
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 50) ? 'Deskripsi minimal 50 karakter' : null,
            ),
            _label('Target dana (Rp)'),
            TextFormField(
              controller: _target,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'Contoh: 50000000', prefixText: 'Rp '),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n < 1000000) return 'Target minimal Rp 1.000.000';
                if (n > 5000000000) return 'Target maksimal Rp 5.000.000.000';
                return null;
              },
            ),
            _label('Durasi penggalangan'),
            DropdownButtonFormField<int>(
              initialValue: _days,
              items: [
                for (final d in _durations) DropdownMenuItem(value: d, child: Text('$d hari')),
              ],
              onChanged: (v) => setState(() => _days = v ?? _days),
            ),
            _label('Foto sampul'),
            if (_cover != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      _cover!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () => setState(() => _cover = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: _pickCover,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.5)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.forestGreen),
                      SizedBox(height: 4),
                      Text('Pilih foto dari galeri', style: TextStyle(color: AppColors.forestGreen)),
                    ],
                  ),
                ),
              ),
            _label('Informasi pendukung'),
            TextFormField(
              controller: _info,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Penanggung jawab, nomor kontak, dan dokumen/legalitas pendukung.',
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? 'Isi penanggung jawab dan kontak' : null,
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_sending ? 'Mengirim...' : 'Kirim ke Admin'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}