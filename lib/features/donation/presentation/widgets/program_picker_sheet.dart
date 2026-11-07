import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';

/// Lembar pencarian program: cari berdasarkan nama, lokasi, kategori, atau jenis.
/// Mengembalikan [Campaign] yang dipilih lewat Navigator.pop.
class ProgramPickerSheet extends StatefulWidget {
  const ProgramPickerSheet({super.key, required this.campaigns});

  final List<Campaign> campaigns;

  @override
  State<ProgramPickerSheet> createState() => _ProgramPickerSheetState();
}

class _ProgramPickerSheetState extends State<ProgramPickerSheet> {
  final _controller = TextEditingController();
  String _query = '';
  ProgramCategory? _category;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Campaign> get _results {
    final q = _query.trim().toLowerCase();
    return widget.campaigns.where((c) {
      if (_category != null && c.category != _category) return false;
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.location.toLowerCase().contains(q) ||
          c.category.label.toLowerCase().contains(q) ||
          (c.subType ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final categories =
        ProgramCategory.values.where((c) => c != ProgramCategory.zakat).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sandBeige,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: TextField(
                  controller: _controller,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Cari program, lokasi, atau kategori',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _chip('Semua', _category == null, () => setState(() => _category = null)),
                    for (final c in categories)
                      _chip(c.shortLabel, _category == c, () => setState(() => _category = c)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: results.isEmpty
                    ? const Center(child: Text('Program tidak ditemukan'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: results.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final c = results[i];
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              onTap: () => Navigator.pop(context, c),
                              leading: ProgramImage(
                                category: c.category,
                                imageAsset: c.imageAsset,
                                height: 52,
                                width: 52,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              title: Text(
                                c.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${c.category.label} • ${c.location}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                '${c.progressPercent}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.forestGreen,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}