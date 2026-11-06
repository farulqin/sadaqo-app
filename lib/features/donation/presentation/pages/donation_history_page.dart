import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_state.dart';

enum _Filter {
  semua('Semua'),
  program('Program'),
  qurban('Qurban');

  const _Filter(this.label);
  final String label;

  bool matches(Donation d) {
    switch (this) {
      case _Filter.semua:
        return true;
      case _Filter.program:
        return d.category != ProgramCategory.qurban;
      case _Filter.qurban:
        return d.category == ProgramCategory.qurban;
    }
  }
}

class DonationHistoryPage extends StatefulWidget {
  const DonationHistoryPage({super.key});

  @override
  State<DonationHistoryPage> createState() => _DonationHistoryPageState();
}

class _DonationHistoryPageState extends State<DonationHistoryPage> {
  _Filter _filter = _Filter.semua;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Donasi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.label),
                      selected: _filter == f,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.forestGreen,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _filter == f ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<DonationHistoryCubit, DonationHistoryState>(
              builder: (context, state) {
                if (state is DonationHistoryError) {
                  return ErrorView(
                    message: state.message,
                    onRetry: () => context.read<DonationHistoryCubit>().load(),
                  );
                }
                if (state is! DonationHistoryLoaded) return const LoadingView();

                final items = state.donations.where(_filter.matches).toList();
                return RefreshIndicator(
                  onRefresh: () => context.read<DonationHistoryCubit>().refresh(),
                  child: items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('Belum ada donasi')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => _DonationTile(donation: items[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DonationTile extends StatelessWidget {
  const _DonationTile({required this.donation});

  final Donation donation;

  @override
  Widget build(BuildContext context) {
    final success = donation.status == DonationStatus.success;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ProgramImage(
            category: donation.category,
            height: 56,
            width: 56,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.campaignTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatter.rupiah(donation.amount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  Formatter.date(donation.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: success ? AppColors.successSoft : AppColors.sandBeige,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              donation.status.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: success ? AppColors.success : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
