import 'package:flutter/material.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/pengelola/core/pengelola_layout.dart';
import 'package:sadaqo/pengelola/data/pengelola_account_store.dart';
import 'package:sadaqo/pengelola/data/pengelola_store.dart';
import 'package:sadaqo/pengelola/presentation/pages/create_campaign_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/pengelola_docs_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/pengelola_edit_profile_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/pengelola_home_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/pengelola_profile_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/pengelola_programs_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/send_report_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';

/// Kerangka Dashboard Pengelola: 4 tab (Beranda, Program, Dokumentasi, Profil).
/// - HP (< 700 px): navigasi bawah.
/// - Tablet (700-1099 px): navigasi samping ringkas.
/// - Laptop/web (>= 1100 px): navigasi samping lebar dengan logo.
class PengelolaShell extends StatefulWidget {
  const PengelolaShell({super.key});

  @override
  State<PengelolaShell> createState() => _PengelolaShellState();
}

class _PengelolaShellState extends State<PengelolaShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    sl<AdminVerificationStore>().loadForPengelola();

    // Samakan data akun lokal dengan data pengguna dari server.
    final user = context.read<AuthCubit>().user;
    if (user != null) {
      sl<PengelolaAccountStore>().saveProfile(
        name: user.name,
        phone: user.phone ?? '',
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _requireProfile());
  }

  /// Nama dan nomor telepon wajib diisi sebelum pengelola bisa bekerja.
  Future<void> _requireProfile() async {
    if (!mounted || sl<PengelolaAccountStore>().isProfileComplete) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => const PengelolaEditProfilePage(forced: true),
      ),
    );
  }

  void _goTo(int i) => setState(() => _index = i);

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Formulir kirim dokumentasi (baru, untuk program tertentu, atau revisi).
  Future<void> _openSend({String? campaignId, CampaignReport? revise}) async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SendReportPage(initialCampaignId: campaignId, revising: revise),
      ),
    );
    if (sent == true && mounted) {
      _goTo(2);
      _snack('Dokumentasi terkirim. Admin akan memeriksanya sebelum ditampilkan ke donatur.');
    }
  }

  /// Formulir buat kampanye (baru, atau perbaikan pengajuan yang dikembalikan admin).
  Future<void> _openCreate({CampaignSubmission? edit}) async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => CreateCampaignPage(editing: edit)),
    );
    if (sent == true && mounted) {
      _goTo(1);
      _snack('Pengajuan terkirim. Admin akan memverifikasinya sebelum kampanye dipublikasikan.');
    }
  }

  late final List<Widget> _pages = [
    PengelolaHomePage(
      onNavigateTab: _goTo,
      onSendDocs: () => _openSend(),
    ),
    PengelolaProgramsPage(
      onSendDocs: (id) => _openSend(campaignId: id),
      onCreate: () => _openCreate(),
      onEdit: (s) => _openCreate(edit: s),
    ),
    PengelolaDocsPage(
      onSend: () => _openSend(),
      onRevise: (r) => _openSend(revise: r),
    ),
    const PengelolaProfilePage(),
  ];

  List<({Widget icon, String label})> _items(PengelolaStore store) => [
        (
          icon: const ImageIcon(AssetImage(AppAssets.iconBeranda)),
          label: 'Beranda',
        ),
        (
          icon: Badge(
            isLabelVisible: store.submissionRevisionCount > 0,
            label: Text('${store.submissionRevisionCount}'),
            child: const ImageIcon(AssetImage(AppAssets.iconProgram)),
          ),
          label: 'Program',
        ),
        (
          icon: Badge(
            isLabelVisible: store.revisionCount > 0,
            label: Text('${store.revisionCount}'),
            child: const Icon(Icons.description_outlined),
          ),
          label: 'Dokumentasi',
        ),
        (
          icon: const ImageIcon(AssetImage(AppAssets.iconProfil)),
          label: 'Profil',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final store = sl<PengelolaStore>();
    return ListenableBuilder(
      listenable: store.changes,
      builder: (context, _) {
        final items = _items(store);
        final body = IndexedStack(index: _index, children: _pages);
        return LayoutBuilder(
          builder: (context, c) {
            final useRail = c.maxWidth >= PengelolaLayout.tablet;
            if (!useRail) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: body,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _goTo,
                  destinations: [
                    for (final it in items)
                      NavigationDestination(icon: it.icon, label: it.label),
                  ],
                ),
              );
            }

            final extended = c.maxWidth >= PengelolaLayout.desktop;
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Row(
                children: [
                  SafeArea(
                    child: NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: _goTo,
                      extended: extended,
                      minExtendedWidth: 220,
                      labelType: extended
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      backgroundColor: Colors.white,
                      indicatorColor: AppColors.limeGreen,
                      selectedIconTheme: const IconThemeData(color: AppColors.forestGreen),
                      unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
                      selectedLabelTextStyle: const TextStyle(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted),
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Column(
                          children: [
                            Image.asset(
                              AppAssets.logoEmblem,
                              height: extended ? 58 : 44,
                              errorBuilder: (context, e, s) => const Icon(
                                Icons.mosque,
                                size: 40,
                                color: AppColors.forestGreen,
                              ),
                            ),
                            if (extended) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'SADAQO',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                              const Text(
                                'Pengelola Kampanye',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      destinations: [
                        for (final it in items)
                          NavigationRailDestination(
                            icon: it.icon,
                            label: Text(it.label),
                          ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: body),
                ],
              ),
            );
          },
        );
      },
    );
  }
}