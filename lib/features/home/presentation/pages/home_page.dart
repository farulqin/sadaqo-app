import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/section_header.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_detail_page.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_list_page.dart';
import 'package:sadaqo/features/campaign/presentation/widgets/campaign_card.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_state.dart';
import 'package:sadaqo/features/home/presentation/widgets/category_shortcuts.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_cubit.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_state.dart';
import 'package:sadaqo/features/news/presentation/widgets/news_carousel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onNavigateTab});

  /// Pindah tab di MainShell (1 = Program, 3 = Riwayat).
  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().user;
    final history = context.watch<DonationHistoryCubit>().state;
    final total = history is DonationHistoryLoaded ? history.totalSuccess : 0;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(
            name: user?.firstName ?? 'Sahabat',
            initial: user?.initial ?? '?',
            total: total,
            onSeeHistory: () => onNavigateTab(3),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryShortcuts(
                  onSelected: (category) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CampaignListPage(initialCategory: category),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Berita Terbaru'),
                const SizedBox(height: 12),
                BlocBuilder<NewsCubit, NewsState>(
                  builder: (context, state) {
                    if (state is NewsError) {
                      return ErrorView(
                        message: state.message,
                        onRetry: () => context.read<NewsCubit>().load(),
                      );
                    }
                    if (state is! NewsLoaded) {
                      return const SizedBox(height: 190, child: LoadingView());
                    }
                    if (state.articles.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return NewsCarousel(articles: state.articles);
                  },
                ),
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'Program Pilihan',
                  actionLabel: 'Lihat Semua',
                  onAction: () => onNavigateTab(1),
                ),
                const SizedBox(height: 12),
                BlocBuilder<CampaignCubit, CampaignState>(
                  builder: (context, state) {
                    if (state is CampaignError) {
                      return ErrorView(
                        message: state.message,
                        onRetry: () => context.read<CampaignCubit>().load(),
                      );
                    }
                    if (state is! CampaignLoaded) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: LoadingView(),
                      );
                    }
                    return Column(
                      children: [
                        for (final c in state.campaigns.take(2))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: CampaignCard(
                              campaign: c,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CampaignDetailPage(campaign: c),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.initial,
    required this.total,
    required this.onSeeHistory,
  });

  final String name;
  final String initial;
  final int total;
  final VoidCallback onSeeHistory;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 18),
      decoration: const BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.sandBeige,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $name 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Semoga hari ini penuh keberkahan',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifikasi menyusul')),
                ),
                icon: const Icon(Icons.notifications_none, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.forestGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Donasi Anda',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      Text(
                        Formatter.rupiah(total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onSeeHistory,
                  child: const Text('Lihat Riwayat'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
