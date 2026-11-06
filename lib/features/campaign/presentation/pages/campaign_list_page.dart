import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_detail_page.dart';
import 'package:sadaqo/features/campaign/presentation/widgets/campaign_card.dart';

/// Dipakai sebagai tab "Program" dan sebagai halaman hasil klik kategori.
class CampaignListPage extends StatefulWidget {
  const CampaignListPage({super.key, this.initialCategory});

  final ProgramCategory? initialCategory;

  @override
  State<CampaignListPage> createState() => _CampaignListPageState();
}

class _CampaignListPageState extends State<CampaignListPage> {
  ProgramCategory? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
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
                _chip('Semua', _category == null, () => setState(() => _category = null)),
                for (final c in ProgramCategory.values)
                  _chip(c.shortLabel, _category == c, () => setState(() => _category = c)),
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

                final items = state.campaigns
                    .where((c) => _category == null || c.category == _category)
                    .toList();
                if (items.isEmpty) {
                  return const Center(child: Text('Belum ada program'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => CampaignCard(
                    campaign: items[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CampaignDetailPage(campaign: items[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
