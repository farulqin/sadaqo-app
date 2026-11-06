import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_detail_page.dart';
import 'package:sadaqo/features/campaign/presentation/widgets/campaign_card.dart';

/// Dipakai sebagai tab "Program" dan halaman hasil klik kategori.
/// Saat satu kategori dipilih, muncul filter jenis (mis. Masjid / Mushola).
class CampaignListPage extends StatefulWidget {
  const CampaignListPage({super.key, this.initialCategory});

  final ProgramCategory? initialCategory;

  @override
  State<CampaignListPage> createState() => _CampaignListPageState();
}

class _CampaignListPageState extends State<CampaignListPage> {
  ProgramCategory? _category;
  String? _subType;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  void _selectCategory(ProgramCategory? c) {
    setState(() {
      _category = c;
      _subType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialCategory?.label ?? 'Program Donasi')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _chip('Semua', _category == null, () => _selectCategory(null)),
                for (final c in ProgramCategory.values)
                  _chip(c.shortLabel, _category == c, () => _selectCategory(c)),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<CampaignCubit, CampaignState>(
              builder: (context, state) {
                if (state is CampaignError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: () => context.read<CampaignCubit>().load(),
                  );
                }
                if (state is! CampaignLoaded) return const LoadingView();

                final inCategory = state.campaigns
                    .where((c) => _category == null || c.category == _category)
                    .toList();

                // Jenis yang tersedia pada kategori terpilih.
                final subTypes = <String>[];
                if (_category != null) {
                  for (final c in inCategory) {
                    final s = c.subType;
                    if (s != null && !subTypes.contains(s)) subTypes.add(s);
                  }
                }

                final items = inCategory
                    .where((c) => _subType == null || c.subType == _subType)
                    .toList();

                return Column(
                  children: [
                    if (subTypes.length > 1)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Row(
                          children: [
                            _chip('Semua jenis', _subType == null,
                                () => setState(() => _subType = null),
                                small: true),
                            for (final s in subTypes)
                              _chip(s, _subType == s, () => setState(() => _subType = s),
                                  small: true),
                          ],
                        ),
                      ),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(child: Text('Belum ada program'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: items.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, i) => CampaignCard(
                                campaign: items[i],
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CampaignDetailPage(campaign: items[i]),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {bool small = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        visualDensity: small ? VisualDensity.compact : VisualDensity.standard,
        selectedColor: small ? AppColors.limeGreen : AppColors.forestGreen,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: small ? 12 : 14,
          color: selected
              ? (small ? AppColors.forestGreen : Colors.white)
              : AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}