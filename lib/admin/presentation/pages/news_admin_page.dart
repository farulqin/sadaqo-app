import 'package:flutter/material.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/data/admin_activity_log.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/news/data/datasources/news_mock_datasource.dart';
import 'package:sadaqo/features/news/data/models/news_model.dart';
import 'package:sadaqo/features/news/domain/entities/news_article.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_cubit.dart';
import 'package:sadaqo/injection_container.dart';

/// Tambah, ubah, dan hapus berita yang tampil di beranda aplikasi.
class NewsAdminPage extends StatefulWidget {
  const NewsAdminPage({super.key, this.initialQuery, this.startCreate = false});

  final String? initialQuery;
  final bool startCreate;

  @override
  State<NewsAdminPage> createState() => _NewsAdminPageState();
}

class _NewsAdminPageState extends State<NewsAdminPage> {
  final _news = sl<NewsMockDataSource>();
  final _log = sl<AdminActivityLog>();
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.startCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openForm();
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm({NewsArticle? existing}) async {
    final result = await showDialog<NewsModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _NewsForm(existing: existing, newId: existing?.id ?? _news.adminNextId()),
    );
    if (result == null || !mounted) return;
    _news.adminSave(result);
    sl<NewsCubit>().load();
    _log.add(
      ActivityKind.content,
      existing == null ? 'Berita baru diterbitkan: "${result.title}"' : 'Berita diperbarui: "${result.title}"',
    );
    setState(() {});
    adminToast(context, existing == null ? 'Berita diterbitkan' : 'Perubahan disimpan');
  }

  Future<void> _delete(NewsArticle n) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus berita?',
      message: '"${n.title}" akan hilang dari aplikasi pengguna.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    _news.adminRemove(n.id);
    sl<NewsCubit>().load();
    _log.add(ActivityKind.content, 'Berita dihapus: "${n.title}"');
    setState(() {});
    adminToast(context, 'Berita dihapus');
  }

  @override
  Widget build(BuildContext context) {
    final all = _news.adminAll();
    final q = _search.text.trim().toLowerCase();
    final items = all
        .where((n) =>
            q.isEmpty ||
            n.title.toLowerCase().contains(q) ||
            n.summary.toLowerCase().contains(q) ||
            n.category.label.toLowerCase().contains(q))
        .toList();
    return LayoutBuilder(
      builder: (context, c) {
        final pad = c.maxWidth < 600 ? 14.0 : 24.0;
        final compact = c.maxWidth < 760;
        return ListView(
          padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
          children: [
            PageHeader(
              title: 'Berita',
              subtitle: '${all.length} berita • maksimal ${NewsArticle.maxWords} kata per berita.',
              actions: [
                AdminButton(label: 'Tambah Berita', icon: Icons.add_rounded, onPressed: () => _openForm()),
              ],
            ),
            AdminSearchField(
              controller: _search,
              hint: 'Cari judul atau kategori berita...',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const AdminCard(child: EmptyState(icon: Icons.newspaper_rounded, text: 'Tidak ada berita'))
            else
              for (final n in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AdminCard(
                    padding: const EdgeInsets.all(12),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AssetThumb(n.imageAsset, width: double.infinity, height: 130, radius: 14),
                              const SizedBox(height: 10),
                              _info(n),
                              Align(alignment: Alignment.centerRight, child: _actions(n)),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AssetThumb(n.imageAsset, width: 160, height: 110, radius: 14),
                              const SizedBox(width: 16),
                              Expanded(child: _info(n)),
                              _actions(n),
                            ],
                          ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _info(NewsArticle n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Pill(n.category.shortLabel, color: AdminColors.green, bg: AdminColors.limeSoft),
            Pill('${n.wordCount} kata • ${n.readMinutes} mnt baca', color: AdminColors.muted),
          ],
        ),
        const SizedBox(height: 8),
        Text(n.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(n.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6),
        Text(
          '${n.author} • ${AdminFmt.dayMonthYear(n.publishedAt)}',
          style: const TextStyle(fontSize: 12, color: AdminColors.muted),
        ),
      ],
    );
  }

  Widget _actions(NewsArticle n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(tooltip: 'Ubah', onPressed: () => _openForm(existing: n), icon: const Icon(Icons.edit_rounded, size: 20)),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          tooltip: 'Hapus',
          style: IconButton.styleFrom(backgroundColor: AdminColors.dangerSoft, foregroundColor: AdminColors.danger),
          onPressed: () => _delete(n),
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
        ),
      ],
    );
  }
}

class _NewsForm extends StatefulWidget {
  const _NewsForm({required this.newId, this.existing});

  final String newId;
  final NewsArticle? existing;

  @override
  State<_NewsForm> createState() => _NewsFormState();
}

class _NewsFormState extends State<_NewsForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _summary;
  late final TextEditingController _content;
  late final TextEditingController _author;
  late ProgramCategory _category;
  String? _campaignId;
  String? _image;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _summary = TextEditingController(text: e?.summary ?? '');
    _content = TextEditingController(text: e?.content ?? '');
    _author = TextEditingController(text: e?.author ?? 'Redaksi SADAQO');
    _category = e?.category ?? ProgramCategory.masjid;
    _campaignId = e?.campaignId;
    _image = e?.imageAsset;
  }

  @override
  void dispose() {
    for (final c in [_title, _summary, _content, _author]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _words {
    final t = _content.text.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }

  Future<void> _pickImage() async {
    final p = await showAssetPicker(
      context,
      title: 'Pilih gambar berita',
      groups: const ['news', 'masjid_mushola', 'bantuan_sosial', 'zakat', 'kaum_duafa', 'qurban_bersama'],
      initialGroup: 'news',
      selected: _image,
    );
    if (p != null) setState(() => _image = p);
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = sl<MockCampaignStore>().all;
    final size = MediaQuery.of(context).size;
    final over = _words > NewsArticle.maxWords;
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
                      widget.existing == null ? 'Tambah Berita' : 'Ubah Berita',
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
                  key: _key,
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickImage,
                        child: Container(
                          height: 140,
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
                                  child: Text(
                                    _image == null ? 'Pilih gambar' : 'Ganti gambar',
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(labelText: 'Judul berita'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _summary,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Ringkasan'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ringkasan wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _content,
                        minLines: 7,
                        maxLines: 14,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Isi berita (pisahkan paragraf dengan baris kosong)',
                          alignLabelWithHint: true,
                          helperText: '$_words / ${NewsArticle.maxWords} kata',
                          helperStyle: TextStyle(color: over ? AdminColors.danger : AdminColors.muted),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Isi berita wajib diisi';
                          if (over) return 'Maksimal ${NewsArticle.maxWords} kata';
                          return null;
                        },
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
                          final camp = DropdownButtonFormField<String?>(
                            initialValue: campaigns.any((x) => x.id == _campaignId) ? _campaignId : null,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Program terkait (tombol Donasi)'),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('Tanpa program')),
                              for (final x in campaigns)
                                DropdownMenuItem<String?>(
                                  value: x.id,
                                  child: Text(x.title, overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            onChanged: (v) => setState(() => _campaignId = v),
                          );
                          return two
                              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: cat), const SizedBox(width: 12), Expanded(child: camp)])
                              : Column(children: [cat, const SizedBox(height: 12), camp]);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _author,
                        decoration: const InputDecoration(labelText: 'Penulis'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Penulis wajib diisi' : null,
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
                    label: widget.existing == null ? 'Terbitkan' : 'Simpan Perubahan',
                    icon: Icons.check_rounded,
                    onPressed: () {
                      if (!_key.currentState!.validate()) return;
                      Navigator.pop(
                        context,
                        NewsModel(
                          id: widget.newId,
                          title: _title.text.trim(),
                          summary: _summary.text.trim(),
                          content: _content.text.trim(),
                          category: _category,
                          author: _author.text.trim(),
                          publishedAt: widget.existing?.publishedAt ?? DateTime.now(),
                          campaignId: _campaignId,
                          imageAsset: _image,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
