import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/navigation/main_tab_controller.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_list_page.dart';
import 'package:sadaqo/features/community_feed/presentation/cubit/community_feed_cubit.dart';
import 'package:sadaqo/features/community_feed/presentation/pages/community_home_page.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/pages/donation_history_page.dart';
import 'package:sadaqo/features/donation/presentation/pages/donation_page.dart';
import 'package:sadaqo/features/home/presentation/pages/home_page.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_cubit.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/features/report/presentation/widgets/report_widgets.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';
import 'package:sadaqo/features/favorite/presentation/cubit/favorite_cubit.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:sadaqo/core/widgets/glass_nav_bar.dart';

/// Kerangka utama aplikasi: 5 tab navigasi bawah (ikon dari assets/icons).
/// Profil tidak lagi menjadi tab: dibuka dari ikon foto di bagian atas.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final MainTabController _tab = sl<MainTabController>();

  late final List<Widget> _pages = [
    HomePage(onNavigateTab: _goTo),
    const CampaignListPage(),
    const DonationPage(),
    const DonationHistoryPage(),
    const CommunityHomePage(),
  ];

  @override
  void initState() {
    super.initState();
    _tab.index.value = MainTabController.home; // mulai dari beranda
    // Data dimuat setelah login (nanti butuh token dari backend).
    context.read<CampaignCubit>().load();
    context.read<DonationHistoryCubit>().load();
    context.read<NewsCubit>().load();
    sl<ReportRepository>().loadForDonor();
    context.read<NotificationCubit>().load();
    context.read<FavoriteCubit>().load();
  }

  void _goTo(int i) {
    _tab.index.value = i;
    context.read<NotificationCubit>().load();
    if (i == MainTabController.community) {
      context.read<CommunityFeedCubit>().refreshQuiet();
    }
    // Muat ulang dari server saat tab dibuka (token mati / server mati langsung terdeteksi).
    if (i == MainTabController.history) {
      context.read<DonationHistoryCubit>().refresh();
      sl<ReportRepository>().loadForDonor();
    } else if (i == MainTabController.programs) {
      context.read<CampaignCubit>().refresh();
    }
  }

    @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _tab.index,
      builder: (context, index, child) => Scaffold(
        body: IndexedStack(index: index, children: _pages),
        bottomNavigationBar: GlassNavBar(
          selectedIndex: index,
          onSelected: _goTo,
          items: [
            GlassNavItem(
              label: 'Beranda',
              iconBuilder: (c) => ImageIcon(const AssetImage(AppAssets.iconBeranda), color: c, size: 24),
            ),
            GlassNavItem(
              label: 'Program',
              iconBuilder: (c) => ImageIcon(const AssetImage(AppAssets.iconProgram), color: c, size: 24),
            ),
            GlassNavItem(
              label: 'Donasi',
              iconBuilder: (c) => ImageIcon(const AssetImage(AppAssets.iconDonasi), color: c, size: 24),
            ),
            GlassNavItem(
              label: 'Riwayat',
              iconBuilder: (c) => ReportUnreadBadge(
                child: ImageIcon(const AssetImage(AppAssets.iconRiwayat), color: c, size: 24),
              ),
            ),
            GlassNavItem(
              label: 'Komunitas',
              iconBuilder: (c) => ImageIcon(const AssetImage(AppAssets.iconKomunitas), color: c, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}