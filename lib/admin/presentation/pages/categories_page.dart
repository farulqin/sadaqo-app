import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sadaqo/admin/data/admin_activity_log.dart';
import 'package:sadaqo/admin/data/asset_library.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/widgets/category_icon.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/injection_container.dart';

/// Kelola nama dan ikon kategori, serta lihat pustaka gambar, ikon, dan avatar aplikasi.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _campaigns = sl<MockCampaignStore>();
  final _log = sl<AdminActivityLog>();
  Map<String, List<String>>? _library;
  String _group = 'masjid_mushola';

  @override
  void initState() {
    super.initState();
    AssetLibrary.load().then((d) {
      if (mounted) setState(() => _library = d);
    });
  }

  Future<void> _edit(ProgramCategory k) async {
    final result = await showDialog<_CategoryEdit>(
      context: context,
      builder: (ctx) => _CategoryDialog(category: k),
    );
    if (result == null || !mounted) return;
    if (result.reset) {
      CategoryOverrides.labels.remove(k.key);
      CategoryOverrides.shortLabels.remove(k.key);
      CategoryOverrides.iconAssets.remove(k.key);
      _log.add(ActivityKind.content, 'Kategori "${k.defaultLabel}" dikembalikan ke bawaan');
    } else {
      CategoryOverrides.labels[k.key] = result.label;
      CategoryOverrides.shortLabels[k.key] = result.shortLabel;
      if (result.icon != null) CategoryOverrides.iconAssets[k.key] = result.icon!;
      _log.add(ActivityKind.content, 'Kategori diperbarui: "${result.label}"');
    }
    setState(() {});
    adminToast(context, 'Kategori disimpan. Tampil di aplikasi saat halaman dimuat ulang.');
  }

  @override
  Widget build(BuildContext context) {
    final lib = _library;
    return LayoutBuilder(
      builder: (context, c) {
        final pad = c.maxWidth < 600 ? 14.0 : 24.0;
        final cols = c.maxWidth >= 1100 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
        const gap = 14.0;
        final cardW = (c.maxWidth - pad * 2 - gap * (cols - 1)) / cols;
        final keys = lib == null
            ? const <String>[]
            : AssetLibrary.groups.keys.where((k) => (lib[k] ?? const <String>[]).isNotEmpty).toList();
        final files = lib == null ? const <String>[] : (lib[_group] ?? const <String>[]);
        return ListView(
          padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
          children: [
            const PageHeader(
              title: 'Kategori & Media',
              subtitle: 'Atur nama dan ikon kategori, serta lihat semua gambar yang dipakai aplikasi.',
            ),
            const SectionTitle('Kategori Program', icon: Icons.category_rounded),
            const SizedBox(height: 12),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final k in ProgramCategory.values)
                  SizedBox(
                    width: cardW,
                    child: AdminCard(
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AdminColors.limeSoft, borderRadius: BorderRadius.circular(16)),
                            child: CategoryIcon(k, size: 34, color: AdminColors.green),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(k.label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                                Text(
                                  '${_campaigns.all.where((x) => x.category == k).length} program • "${k.shortLabel}"',
                                  style: const TextStyle(fontSize: 12.5, color: AdminColors.muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Ubah kategori',
                            onPressed: () => _edit(k),
                            icon: const Icon(Icons.edit_rounded, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 26),
            const SectionTitle('Pustaka Media', icon: Icons.photo_library_rounded),
            const SizedBox(height: 4),
            const Text(
              'Gambar dibaca otomatis dari folder assets. Untuk menambah atau mengganti file, masukkan ke folder assets/ lalu jalankan ulang aplikasi. Pengunggahan langsung dari dashboard menyusul bersama backend.',
              style: TextStyle(fontSize: 12.5, color: AdminColors.muted),
            ),
            const SizedBox(height: 12),
            if (lib == null)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator(color: AdminColors.green)),
              )
            else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final k in keys)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${AssetLibrary.groups[k]} (${lib[k]!.length})'),
                          selected: _group == k,
                          showCheckmark: false,
                          selectedColor: AdminColors.green,
                          backgroundColor: AdminColors.card,
                          labelStyle: TextStyle(
                            color: _group == k ? Colors.white : const Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _group = k),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (files.isEmpty)
                const AdminCard(child: EmptyState(icon: Icons.image_not_supported_outlined, text: 'Folder ini belum berisi gambar'))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 190,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: files.length,
                  itemBuilder: (context, i) {
                    final path = files[i];
                    final isIcon = _group == 'icons';
                    return AdminCard(
                      padding: const EdgeInsets.all(8),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: path));
                        adminToast(context, 'Path disalin: $path');
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: isIcon
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: AdminColors.limeSoft,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Image.asset(path, fit: BoxFit.contain),
                                    )
                                  : AssetThumb(path, radius: 10),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AssetLibrary.fileName(path),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 6),
              const Text('Ketuk gambar untuk menyalin path-nya.', style: TextStyle(fontSize: 12, color: AdminColors.muted)),
            ],
          ],
        );
      },
    );
  }
}

class _CategoryEdit {
  const _CategoryEdit({this.label = '', this.shortLabel = '', this.icon, this.reset = false});

  final String label;
  final String shortLabel;
  final String? icon;
  final bool reset;
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.category});

  final ProgramCategory category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _label;
  late final TextEditingController _short;
  String? _icon;
  String? _error;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.category.label);
    _short = TextEditingController(text: widget.category.shortLabel);
    _icon = widget.category.iconAsset;
  }

  @override
  void dispose() {
    _label.dispose();
    _short.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final p = await showAssetPicker(
      context,
      title: 'Pilih ikon kategori',
      groups: const ['icons'],
      initialGroup: 'icons',
      selected: _icon,
    );
    if (p != null) setState(() => _icon = p);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AdminColors.card,
      title: const Text('Ubah Kategori'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _pickIcon,
                child: Container(
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AdminColors.limeSoft, borderRadius: BorderRadius.circular(20)),
                  child: _icon == null
                      ? Icon(widget.category.icon, size: 42, color: AdminColors.green)
                      : Image.asset(_icon!, color: AdminColors.green, errorBuilder: (c, e, s) => const Icon(Icons.image_outlined)),
                ),
              ),
              TextButton(onPressed: _pickIcon, child: const Text('Ganti ikon')),
              const SizedBox(height: 6),
              TextField(controller: _label, decoration: const InputDecoration(labelText: 'Nama kategori')),
              const SizedBox(height: 12),
              TextField(
                controller: _short,
                decoration: InputDecoration(labelText: 'Nama singkat', errorText: _error),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const _CategoryEdit(reset: true)),
          child: const Text('Kembalikan bawaan'),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AdminColors.green),
          onPressed: () {
            if (_label.text.trim().isEmpty || _short.text.trim().isEmpty) {
              setState(() => _error = 'Nama dan nama singkat wajib diisi');
              return;
            }
            Navigator.pop(
              context,
              _CategoryEdit(label: _label.text.trim(), shortLabel: _short.text.trim(), icon: _icon),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
