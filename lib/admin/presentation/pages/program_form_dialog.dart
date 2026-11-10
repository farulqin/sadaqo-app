import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/data/asset_library.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';

/// Formulir tambah / ubah program. Mengembalikan program yang sudah disusun,
/// atau null jika dibatalkan. Dana terkumpul TIDAK bisa diubah di sini
/// (berasal dari transaksi donatur dan bersifat hanya-baca).
Future<CampaignModel?> showProgramForm(
  BuildContext context, {
  required MockCampaignStore store,
  CampaignModel? existing,
}) {
  return showDialog<CampaignModel>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ProgramForm(store: store, existing: existing),
  );
}

class _ProgramForm extends StatefulWidget {
  const _ProgramForm({required this.store, this.existing});

  final MockCampaignStore store;
  final CampaignModel? existing;

  @override
  State<_ProgramForm> createState() => _ProgramFormState();
}

class _ProgramFormState extends State<_ProgramForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _desc;
  late final TextEditingController _sub;
  late final TextEditingController _target;
  late final TextEditingController _unitPrice;
  late final TextEditingController _unitLabel;
  late final TextEditingController _slots;

  late ProgramCategory _category;
  late DateTime _deadline;
  String? _image;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _sub = TextEditingController(text: e?.subType ?? '');
    _target = TextEditingController(text: e == null ? '' : '${e.targetAmount}');
    _unitPrice = TextEditingController(text: e?.unitPrice == null ? '' : '${e!.unitPrice}');
    _unitLabel = TextEditingController(text: e?.unitLabel ?? '');
    _slots = TextEditingController(text: e?.slotTotal == null ? '' : '${e!.slotTotal}');
    _category = e?.category ?? ProgramCategory.masjid;
    _deadline = e?.deadline ?? DateTime.now().add(const Duration(days: 30));
    _image = e?.imageAsset;
  }

  @override
  void dispose() {
    for (final c in [_title, _location, _desc, _sub, _target, _unitPrice, _unitLabel, _slots]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _pickImage() async {
    final picked = await showAssetPicker(
      context,
      title: 'Pilih foto program',
      groups: const [
        'masjid_mushola',
        'bantuan_sosial',
        'zakat',
        'kaum_duafa',
        'qurban_bersama',
        'news',
      ],
      initialGroup: AssetLibrary.groupFor(_category),
      selected: _image,
    );
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline.isBefore(now) ? now : _deadline,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (d != null) setState(() => _deadline = d);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final e = widget.existing;
    final price = _int(_unitPrice);
    final slotTotal = _int(_slots);
    final slotFilled = e?.slotFilled ?? 0;
    final id = e?.id ?? widget.store.adminNextId(_category);
    Navigator.pop(
      context,
      CampaignModel(
        id: id,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        category: _category,
        targetAmount: _int(_target)!,
        collectedAmount: e?.collectedAmount ?? 0,
        deadline: _deadline,
        location: _location.text.trim(),
        imageAsset: _image,
        subType: _sub.text.trim().isEmpty ? null : _sub.text.trim(),
        unitPrice: price,
        unitLabel: price == null
            ? null
            : (_unitLabel.text.trim().isEmpty ? 'unit' : _unitLabel.text.trim()),
        slotTotal: price == null ? null : slotTotal,
        slotFilled: (price != null && slotTotal != null) ? slotFilled : null,
      ),
    );
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final e = widget.existing;
    return Dialog(
      backgroundColor: AdminColors.card,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 760, maxHeight: size.height * 0.92),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? 'Ubah Program' : 'Tambah Program',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AdminColors.green),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _imageBox(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(labelText: 'Judul program'),
                        validator: (v) => _required(v, 'Judul'),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, c) {
                          final two = c.maxWidth > 520;
                          final cat = DropdownButtonFormField<ProgramCategory>(
                            initialValue: _category,
                            decoration: const InputDecoration(labelText: 'Kategori'),
                            items: [
                              for (final k in ProgramCategory.values)
                                DropdownMenuItem(value: k, child: Text(k.label)),
                            ],
                            onChanged: (v) => setState(() => _category = v ?? _category),
                          );
                          final sub = TextFormField(
                            controller: _sub,
                            decoration: const InputDecoration(
                              labelText: 'Jenis (opsional)',
                              hintText: 'Masjid, Banjir, Kolektif...',
                            ),
                          );
                          return two
                              ? Row(children: [Expanded(child: cat), const SizedBox(width: 12), Expanded(child: sub)])
                              : Column(children: [cat, const SizedBox(height: 12), sub]);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _location,
                        decoration: const InputDecoration(labelText: 'Lokasi'),
                        validator: (v) => _required(v, 'Lokasi'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _desc,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Deskripsi', alignLabelWithHint: true),
                        validator: (v) {
                          if (v == null || v.trim().length < 10) return 'Deskripsi minimal 10 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, c) {
                          final two = c.maxWidth > 520;
                          final target = TextFormField(
                            controller: _target,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Target dana', prefixText: 'Rp '),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              if (n == null || n <= 0) return 'Target harus lebih dari 0';
                              return null;
                            },
                          );
                          final date = InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Batas waktu',
                                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                              ),
                              child: Text(AdminFmt.dayMonthYear(_deadline)),
                            ),
                          );
                          return two
                              ? Row(children: [Expanded(child: target), const SizedBox(width: 12), Expanded(child: date)])
                              : Column(children: [target, const SizedBox(height: 12), date]);
                        },
                      ),
                      if (e != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AdminColors.limeSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline, size: 18, color: AdminColors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Dana terkumpul ${AdminFmt.rupiah(e.collectedAmount)} berasal dari transaksi donatur dan tidak dapat diubah admin.',
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const Text('Harga tetap per unit (opsional)',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text(
                        'Isi untuk program qurban per orang / kolektif. Kosongkan jika donatur bebas menentukan nominal.',
                        style: TextStyle(fontSize: 12.5, color: AdminColors.muted),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, c) {
                          final cols = c.maxWidth > 560 ? 3 : 1;
                          final fields = [
                            TextFormField(
                              controller: _unitPrice,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(labelText: 'Harga per unit', prefixText: 'Rp '),
                            ),
                            TextFormField(
                              controller: _unitLabel,
                              decoration: const InputDecoration(labelText: 'Satuan', hintText: 'ekor / slot'),
                            ),
                            TextFormField(
                              controller: _slots,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(labelText: 'Total slot (opsional)'),
                              validator: (v) {
                                final n = int.tryParse((v ?? '').trim());
                                final filled = e?.slotFilled ?? 0;
                                if (n != null && n < filled) return 'Minimal $filled (sudah terisi)';
                                return null;
                              },
                            ),
                          ];
                          if (cols == 1) {
                            return Column(
                              children: [
                                for (final f in fields) Padding(padding: const EdgeInsets.only(bottom: 10), child: f),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < fields.length; i++) ...[
                                if (i > 0) const SizedBox(width: 12),
                                Expanded(child: fields[i]),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminButton(label: 'Batal', outlined: true, onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  AdminButton(
                    label: _isEdit ? 'Simpan Perubahan' : 'Tambah Program',
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageBox() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AdminColors.limeSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_image != null) AssetThumb(_image, radius: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AdminColors.green.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _image == null ? 'Pilih foto program' : 'Ganti foto',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
