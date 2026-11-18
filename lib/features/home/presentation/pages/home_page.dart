import 'package:flutter/material.dart';
import 'package:sadaqo/core/widgets/sadaqo_logo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/navigation/main_tab_controller.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/core/widgets/section_header.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_detail_page.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_list_page.dart';
import 'package:sadaqo/features/campaign/presentation/widgets/campaign_card.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_state.dart';
import 'package:sadaqo/features/home/presentation/widgets/category_shortcuts.dart';
import 'package:sadaqo/features/home/presentation/widgets/top_bar_actions.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_cubit.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_state.dart';
import 'package:sadaqo/features/news/presentation/widgets/news_carousel.dart';
import 'package:sadaqo/features/zakat/presentation/pages/zakat_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onNavigateTab});

  /// Pindah tab di MainShell.
  final ValueChanged<int> onNavigateTab;

  /// "Program Baru" tayang paling lama 7 hari sejak disetujui, maksimal 5 program.
  static const int _newMaxDays = 7;
  static const int _newMaxItems = 5;

  /// "Program Pilihan": 3 program dengan dana terkumpul terbanyak.
  static const int _featuredItems = 3;

  static bool _isOpen(Campaign c, DateTime now) =>
      !c.isFull && c.deadline.isAfter(now);

  /// Program yang tayang kurang dari 7 hari, terbaru dulu. Berubah otomatis
  /// seiring waktu: program yang sudah lewat 7 hari hilang dari bagian ini.
  static List<Campaign> freshPrograms(List<Campaign> all, DateTime now) {
    final list = all.where((c) {
      final at = c.publishedAt;
      return at != null &&
          now.difference(at).inHours < _newMaxDays * 24 &&
          _isOpen(c, now);
    }).toList()
      ..sort((a, b) => b.publishedAt!.compareTo(a.publishedAt!));
    return list.take(_newMaxItems).toList();
  }

  /// 3 program dengan dana terkumpul terbanyak. Program yang sudah tampil di
  /// "Program Baru" didahulukan belakangan supaya beranda tidak berulang;
  /// bila program kurang, tetap diisi.
  static List<Campaign> featuredPrograms(
    List<Campaign> all,
    List<Campaign> fresh,
    DateTime now,
  ) {
    final open = all.where((c) => _isOpen(c, now)).toList()
      ..sort((a, b) => b.collectedAmount.compareTo(a.collectedAmount));
    final freshIds = fresh.map((c) => c.id).toSet();
    return [
      ...open.where((c) => !freshIds.contains(c.id)),
      ...open.where((c) => freshIds.contains(c.id)),
    ].take(_featuredItems).toList();
  }

  void _open(BuildContext context, Campaign c) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CampaignDetailPage(campaign: c)),
    );
  }

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
            total: total,
            onSeeHistory: () => onNavigateTab(MainTabController.history),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryShortcuts(
                  onSelected: (category) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => category == ProgramCategory.zakat
                          ? const ZakatPage()
                          : CampaignListPage(initialCategory: category),
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
                    final now = DateTime.now();
                    final fresh = freshPrograms(state.campaigns, now);
                    final featured = featuredPrograms(state.campaigns, fresh, now);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (fresh.isNotEmpty) ...[
                          SectionHeader(
                            title: 'Program Baru',
                            actionLabel: 'Lihat Semua',
                            onAction: () => onNavigateTab(MainTabController.programs),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 236,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: fresh.length,
                              separatorBuilder: (context, i) => const SizedBox(width: 12),
                              itemBuilder: (context, i) => _NewProgramTile(
                                campaign: fresh[i],
                                now: now,
                                onTap: () => _open(context, fresh[i]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        SectionHeader(
                          title: 'Program Unggulan',
                          actionLabel: 'Lihat Semua',
                          onAction: () => onNavigateTab(MainTabController.programs),
                        ),
                        const SizedBox(height: 12),
                        for (final c in featured)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: CampaignCard(
                              campaign: c,
                              onTap: () => _open(context, c),
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

/// Kartu ringkas untuk bagian "Program Baru".
class _NewProgramTile extends StatelessWidget {
  const _NewProgramTile({
    required this.campaign,
    required this.now,
    required this.onTap,
  });

  final Campaign campaign;
  final DateTime now;
  final VoidCallback onTap;

  String get _ago {
    final days = now.difference(campaign.publishedAt!).inDays;
    return days <= 0 ? 'BARU • Hari ini' : 'BARU • $days hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    return SizedBox(
      width: 260,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ProgramImage(
                    category: c.category,
                    imageAsset: c.imageAsset,
                    height: 118,
                    width: double.infinity,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _ago,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.25),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: c.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.sandBeige,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${Formatter.rupiah(c.collectedAmount)} • ${c.progressPercent}%',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.total,
    required this.onSeeHistory,
  });

  final String name;
  final int total;
  final VoidCallback onSeeHistory;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 10, 8, 18),
      decoration: const BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SadaqoLogo(size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $name 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              // Notifikasi + foto profil (membuka halaman Profil)
              const TopBarActions(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.only(right: 8),
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