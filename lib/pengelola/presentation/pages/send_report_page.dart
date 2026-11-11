import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';
import 'package:sadaqo/features/report/presentation/widgets/report_widgets.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/pengelola/core/pengelola_config.dart';
import 'package:sadaqo/pengelola/data/pengelola_store.dart';
import 'package:sadaqo/pengelola/core/pengelola_layout.dart';

/// Formulir kirim dokumentasi: foto kegiatan, bukti penyaluran, dan laporan.
/// Jika [revising] diisi, formulir terisi data lama untuk diperbaiki.
class SendReportPage extends StatefulWidget {
  const SendReportPage({super.key, this.initialCampaignId, this.revising});

  final String? initialCampaignId;
  final CampaignReport? revising;

  @override
  State<SendReportPage> createState() => _SendReportPageState();
}

class _SendReportPageState extends State<SendReportPage> {
  static const int _maxPhotos = 6;

  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _people;
  late final TextEditingController _summary;
  late final List<CampaignModel> _programs;

  late String _campaignId;
  late DateTime _date;
  late final List<ReportPhoto> _activity;
  late final List<ReportPhoto> _proof;
  bool _photoError = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final r = widget.revising;
    _programs = sl<PengelolaStore>().programs;
    _campaignId = r?.campaignId ??
        (_programs.any((p) => p.id == widget.initialCampaignId)
            ? widget.initialCampaignId!
            : _programs.first.id);
    _date = r?.activityDate ?? DateTime.now();
    _title = TextEditingController(text: r?.title);
    _amount = TextEditingController(text: r?.distributedAmount.toString());
    _people = TextEditingController(text: r?.beneficiaries.toString());
    _summary = TextEditingController(text: r?.summary);
    _activity = [...?r?.activityPhotos];
    _proof = [...?r?.proofPhotos];
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _people.dispose();
    _summary.dispose();
    super.dispose();
  }

  CampaignModel get _campaign => _programs.firstWhere((p) => p.id == _campaignId);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pick(List<ReportPhoto> target) async {
    final room = _maxPhotos - target.length;
    if (room <= 0) return;
    try {
      final files = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 80);
      final added = <ReportPhoto>[];
      for (final f in files.take(room)) {
        added.add(ReportPhoto.memory(await f.readAsBytes()));
      }
      if (!mounted) return;
      setState(() {
        target.addAll(added);
        _photoError = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka galeri')),
      );
    }
  }

  Future<void> _submit() async {
    final valid = _form.currentState!.validate();
    final noPhoto = _activity.isEmpty || _proof.isEmpty;
    setState(() => _photoError = noPhoto);
    if (!valid || noPhoto) return;

    final c = _campaign;
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 700)); // simulasi kirim
    if (!mounted) return;

    final repo = sl<ReportRepository>();
    repo.submit(
      CampaignReport(
        id: widget.revising?.id ?? repo.nextId(),
        campaignId: c.id,
        campaignTitle: c.title,
        category: c.category,
        managerName: PengelolaConfig.name,
        title: _title.text.trim(),
        summary: _summary.text.trim(),
        distributedAmount: int.parse(_amount.text.trim()),
        beneficiaries: int.parse(_people.text.trim()),
        activityDate: _date,
        submittedAt: DateTime.now(),
        activityPhotos: List.of(_activity),
        proofPhotos: List.of(_proof),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final revising = widget.revising;
    return Scaffold(
      appBar: AppBar(title: Text(revising == null ? 'Kirim Dokumentasi' : 'Perbaiki Dokumentasi')),
      body: Form(
        key: _form,
        child: ContentListView(
          maxWidth: PengelolaLayout.formMax,
          children: [
            if (revising?.adminNote != null)
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
                    Text(revising!.adminNote!),
                  ],
                ),
              ),
            _label('Program'),
            DropdownButtonFormField<String>(
              initialValue: _campaignId,
              isExpanded: true,
              items: [
                for (final p in _programs)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text(p.title, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: revising == null
                  ? (v) => setState(() => _campaignId = v ?? _campaignId)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              'Dana terkumpul: ${Formatter.rupiah(_campaign.collectedAmount)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            _label('Judul laporan'),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Contoh: Penyaluran tahap 1'),
              validator: (v) =>
                  (v == null || v.trim().length < 5) ? 'Judul minimal 5 karakter' : null,
            ),
            _label('Tanggal kegiatan'),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(suffixIcon: Icon(Icons.event_rounded)),
                child: Text(Formatter.date(_date)),
              ),
            ),
            _label('Dana yang disalurkan (Rp)'),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'Contoh: 25000000', prefixText: 'Rp '),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Isi jumlah dana yang disalurkan';
                if (n > _campaign.collectedAmount) {
                  return 'Tidak boleh melebihi dana terkumpul';
                }
                return null;
              },
            ),
            _label('Jumlah penerima manfaat'),
            TextFormField(
              controller: _people,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'Contoh: 120', suffixText: 'orang'),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return (n == null || n <= 0) ? 'Isi jumlah penerima manfaat' : null;
              },
            ),
            _label('Laporan penyaluran'),
            TextFormField(
              controller: _summary,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ceritakan apa yang dilakukan, kepada siapa dana disalurkan, dan hasilnya.',
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 30) ? 'Laporan minimal 30 karakter' : null,
            ),
            _label('Foto kegiatan'),
            _PhotoPicker(
              photos: _activity,
              max: _maxPhotos,
              onAdd: () => _pick(_activity),
              onRemove: (i) => setState(() => _activity.removeAt(i)),
            ),
            _label('Bukti penyaluran (nota, tanda terima, foto serah terima)'),
            _PhotoPicker(
              photos: _proof,
              max: _maxPhotos,
              onAdd: () => _pick(_proof),
              onRemove: (i) => setState(() => _proof.removeAt(i)),
            ),
            if (_photoError)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Foto kegiatan dan bukti penyaluran masing-masing minimal 1.',
                  style: TextStyle(color: AppColors.error, fontSize: 12.5),
                ),
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
            const Text(
              'Laporan baru tampil ke donatur setelah diperiksa dan disetujui admin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
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

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photos,
    required this.max,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ReportPhoto> photos;
  final int max;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < photos.length; i++)
          Stack(
            children: [
              ReportPhotoImage(photos[i], width: 84, height: 84),
              Positioned(
                top: 2,
                right: 2,
                child: InkWell(
                  onTap: () => onRemove(i),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        if (photos.length < max)
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.5)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.forestGreen),
                  SizedBox(height: 2),
                  Text('Tambah', style: TextStyle(fontSize: 11, color: AppColors.forestGreen)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}