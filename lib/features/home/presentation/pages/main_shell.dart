import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/navigation/main_tab_controller.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_list_page.dart';
import 'package:sadaqo/features/community/presentation/pages/community_page.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/pages/donation_history_page.dart';
import 'package:sadaqo/features/donation/presentation/pages/donation_page.dart';
import 'package:sadaqo/features/home/presentation/pages/home_page.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_cubit.dart';
import 'package:sadaqo/injection_container.dart';

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
    const CommunityPage(),
  ];

  @override
  void initState() {
    super.initState();
    _tab.index.value = MainTabController.home; // mulai dari beranda
    // Data dimuat setelah login (nanti butuh token dari backend).
    context.read<CampaignCubit>().load();
    context.read<DonationHistoryCubit>().load();
    context.read<NewsCubit>().load();
  }

  void _goTo(int i) => _tab.index.value = i;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _tab.index,
      builder: (context, index, child) => Scaffold(
        body: IndexedStack(index: index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _goTo,
          destinations: const [
            NavigationDestination(
              icon: ImageIcon(AssetImage(AppAssets.iconBeranda)),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: ImageIcon(AssetImage(AppAssets.iconProgram)),
              label: 'Program',
            ),
            NavigationDestination(
              icon: ImageIcon(AssetImage(AppAssets.iconDonasi)),
              label: 'Donasi',
            ),
            NavigationDestination(
              icon: ImageIcon(AssetImage(AppAssets.iconRiwayat)),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: ImageIcon(AssetImage(AppAssets.iconKomunitas)),
              label: 'Komunitas',
            ),
          ],
        ),
      ),
    );
  }
}