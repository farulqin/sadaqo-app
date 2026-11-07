import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_list_page.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/pages/donation_history_page.dart';
import 'package:sadaqo/features/donation/presentation/pages/donation_page.dart';
import 'package:sadaqo/features/home/presentation/pages/home_page.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_cubit.dart';
import 'package:sadaqo/features/profile/presentation/pages/profile_page.dart';

/// Kerangka utama aplikasi: 5 tab navigasi bawah (ikon dari assets/icons).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _pages = [
    HomePage(onNavigateTab: _goTo),
    const CampaignListPage(),
    const DonationPage(),
    const DonationHistoryPage(),
    ProfilePage(onNavigateTab: _goTo),
  ];

  @override
  void initState() {
    super.initState();
    // Data dimuat setelah login (nanti butuh token dari backend).
    context.read<CampaignCubit>().load();
    context.read<DonationHistoryCubit>().load();
    context.read<NewsCubit>().load();
  }

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
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
            icon: ImageIcon(AssetImage(AppAssets.iconProfil)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}