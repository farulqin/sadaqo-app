import 'package:flutter/material.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/report/domain/entities/campaign_report.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/pengelola/data/pengelola_store.dart';
import 'package:sadaqo/pengelola/presentation/pages/create_campaign_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/pengelola_docs_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/pengelola_home_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/pengelola_profile_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/pengelola_programs_page.dart';
import 'package:sadaqo/pengelola/presentation/pages/send_report_page.dart';

/// Kerangka Dashboard Pengelola: 4 tab (Beranda, Program, Dokumentasi, Profil).
class PengelolaShell extends StatefulWidget {
  const PengelolaShell({super.key});

  @override
  State<PengelolaShell> createState() => _PengelolaShellState();
}

class _PengelolaShellState extends State<PengelolaShell> {
  static const double _maxWidth = 560;

  int _index = 0;

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

  @override
  Widget build(BuildContext context) {
    final store = sl<PengelolaStore>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: IndexedStack(index: _index, children: _pages),
        ),
      ),
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: ListenableBuilder(
            listenable: store.changes,
            builder: (context, _) => NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _goTo,
              destinations: [
                const NavigationDestination(
                  icon: ImageIcon(AssetImage(AppAssets.iconBeranda)),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: store.submissionRevisionCount > 0,
                    label: Text('${store.submissionRevisionCount}'),
                    child: const ImageIcon(AssetImage(AppAssets.iconProgram)),
                  ),
                  label: 'Program',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: store.revisionCount > 0,
                    label: Text('${store.revisionCount}'),
                    child: const Icon(Icons.description_outlined),
                  ),
                  label: 'Dokumentasi',
                ),
                const NavigationDestination(
                  icon: ImageIcon(AssetImage(AppAssets.iconProfil)),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}