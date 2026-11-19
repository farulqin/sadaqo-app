import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/navigation/main_tab_controller.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/percent_chip.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_state.dart';
import 'package:sadaqo/features/favorite/presentation/cubit/favorite_cubit.dart';
import 'package:sadaqo/features/favorite/presentation/widgets/favorite_button.dart';
import 'package:sadaqo/injection_container.dart';
import 'package:sadaqo/core/widgets/category_icon.dart';
import 'package:sadaqo/core/widgets/state_views.dart';

enum _Sort {
  relevant('Paling relevan'),
  nearGoal('Hampir tercapai'),
  mostCollected('Dana terbanyak'),
  deadline('Segera berakhir');

  const _Sort(this.label);
  final String label;
}

/// Tampilan tab Donasi sebelum program dipilih: pencarian, kategori, banner,
/// program unggulan, ringkasan donasi, dan program favorit.
class DonationExplore extends StatefulWidget {
  const DonationExplore({super.key, required this.campaigns, required this.loading, required this.onPick});

  final List<Campaign> campaigns;
  final bool loading;
  final ValueChanged<Campaign> onPick;

  @override
  State<DonationExplore> createState() => _DonationExploreState();
}

class _DonationExploreState extends State<DonationExplore> {
  final _search = TextEditingController();
  ProgramCategory? _category;
  _Sort _sort = _Sort.relevant;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _filtering => _search.text.trim().isNotEmpty || _category != null || _sort != _Sort.relevant;

  List<Campaign> get _results {
    final q = _search.text.trim().toLowerCase();
    final list = widget.campaigns.where((c) {
      if (_category != null && c.category != _category) return false;
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.location.toLowerCase().contains(q) ||
          c.category.label.toLowerCase().contains(q) ||
          (c.subType ?? '').toLowerCase().contains(q);
    }).toList();
    switch (_sort) {
      case _Sort.nearGoal:
        list.sort((a, b) => b.progress.compareTo(a.progress));
      case _Sort.mostCollected:
        list.sort((a, b) => b.collectedAmount.compareTo(a.collectedAmount));
      case _Sort.deadline:
        list.sort((a, b) => a.deadline.compareTo(b.deadline));
      case _Sort.relevant:
        break;
    }
    return list;
  }

  List<Campaign> get _featured {
    final list = [...widget.campaigns]..sort((a, b) => b.collectedAmount.compareTo(a.collectedAmount));
    return list.take(4).toList();
  }

  Future<void> _openFilter() async {
    final picked = await showModalBottomSheet<_Sort>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('Urutkan program', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            for (final s in _Sort.values)
              ListTile(
                title: Text(s.label),
                trailing: s == _sort ? const Icon(Icons.check_rounded, color: AppColors.forestGreen) : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _searchRow(),
        const SizedBox(height: 12),
        _chips(),
        const SizedBox(height: 14),
        if (widget.loading)
          const LoadingView(variant: LoadingVariant.programList)
        else if (_filtering) ...[
          _sectionTitle(Icons.search_rounded, 'Hasil pencarian (${results.length})'),
          const SizedBox(height: 10),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Program tidak ditemukan. Coba kata kunci lain.')),
            )
          else
            _grid(results),
        ] else ...[
          _banner(),
          const SizedBox(height: 18),
          _sectionTitle(
            Icons.local_fire_department_rounded,
            'Program Unggulan',
            trailing: TextButton(
              onPressed: () => sl<MainTabController>().index.value = MainTabController.programs,
              child: const Text('Lihat Semua →'),
            ),
          ),
          const SizedBox(height: 8),
          _grid(_featured),
          const SizedBox(height: 18),
          _summaryCard(),
          const SizedBox(height: 12),
          _favoriteCard(),
        ],
        const SizedBox(height: 8),
        const Text(
          'Untuk zakat, gunakan menu Zakat di beranda.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String text, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE8892B), size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        ?trailing,
      ],
    );
  }

  Widget _searchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.sandBeige),
            ),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari dan pilih program donasi...',
                hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.forestGreen),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => setState(_search.clear),
                      ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: _sort == _Sort.relevant ? AppColors.sandBeige.withValues(alpha: 0.5) : AppColors.limeGreen,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: _openFilter,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: AppColors.forestGreen),
                  SizedBox(width: 6),
                  Text('Filter', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.forestGreen)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chips() {
    final cats = ProgramCategory.values.where((c) => c != ProgramCategory.zakat).toList();
    Widget chip(String label, Widget Function(Color color) icon, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.forestGreen : AppColors.sandBeige.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  icon(selected ? Colors.white : AppColors.forestGreen),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Semua', (color) => Icon(Icons.grid_view_rounded, size: 18, color: color), _category == null, () => setState(() => _category = null)),
          for (final c in cats) chip(c.shortLabel, (color) => CategoryIcon(c, size: 18, color: color), _category == c, () => setState(() => _category = c)),
        ],
      ),
    );
  }

  Widget _banner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 168,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFEFF3DC)),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 230,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (r) => const LinearGradient(
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.0, 0.45],
                ).createShader(r),
                child: Image.asset(AppAssets.masjidModel, fit: BoxFit.cover),
              ),
            ),
            Positioned(left: -14, bottom: -14, child: Image.asset(AppAssets.daunKiri, width: 110, opacity: const AlwaysStoppedAnimation(0.9))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 140, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berbagi Kebaikan,\nMenebar Manfaat',
                    style: TextStyle(fontSize: 21, height: 1.15, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Setiap donasi Anda membawa harapan bagi yang membutuhkan.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _featured.isEmpty ? null : () => widget.onPick(_featured.first),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Donasi Sekarang  ›'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<Campaign> items) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 380 ? 2 : 1);
        const gap = 12.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final x in items) SizedBox(width: w, child: _ProgramTile(campaign: x, onDonate: () => widget.onPick(x)))],
        );
      },
    );
  }

  Widget _summaryCard() {
    return BlocBuilder<DonationHistoryCubit, DonationHistoryState>(
      builder: (context, state) {
        var total = 0;
        var programs = <String>{};
        var social = 0;
        if (state is DonationHistoryLoaded) {
          final ok = state.donations.where((d) => d.status == DonationStatus.success).toList();
          total = state.totalSuccess;
          programs = ok.map((d) => d.campaignId).toSet();
          social = ok.where((d) => d.category == ProgramCategory.sosial || d.category == ProgramCategory.duafa).length;
        }
        Widget stat(IconData icon, Color color, String value, String label) => Expanded(
              child: Column(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 4),
                  FittedBox(
                    child: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            );
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, color: AppColors.forestGreen),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Ringkasan Donasi Saya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  GestureDetector(
                    onTap: () => sl<MainTabController>().index.value = MainTabController.history,
                    child: const Text('Lihat Detail →', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  stat(Icons.volunteer_activism_rounded, AppColors.forestGreen, Formatter.rupiah(total), 'Total Donasi'),
                  stat(Icons.star_rounded, const Color(0xFFF2B01E), '${programs.length}', 'Program Diikuti'),
                  stat(Icons.favorite_rounded, const Color(0xFFE53935), '$social', 'Kegiatan Sosial'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _favoriteCard() {
    return BlocBuilder<FavoriteCubit, FavoriteState>(
      builder: (context, fav) {
        Campaign? first;
        for (final c in widget.campaigns) {
          if (fav.isFavorite(c.id)) {
            first = c;
            break;
          }
        }
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: Color(0xFFF2B01E)),
                  SizedBox(width: 8),
                  Text('Program Favorit Saya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 12),
              if (first == null)
                const Text(
                  'Belum ada program favorit. Tekan ikon hati pada program untuk menyimpannya.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                )
              else
                Row(
                  children: [
                    ProgramImage(
                      category: first.category,
                      imageAsset: first.imageAsset,
                      height: 64,
                      width: 76,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(first.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          PercentChip(percent: first.progressPercent),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => widget.onPick(first!),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forestGreen,
                        backgroundColor: AppColors.successSoft,
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Donasi Lagi ›', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.sandBeige.withValues(alpha: 0.6)),
        ),
        child: child,
      );
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({required this.campaign, required this.onDonate});

  final Campaign campaign;
  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDonate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ProgramImage(category: c.category, imageAsset: c.imageAsset, height: 96, width: double.infinity),
                Positioned(left: 8, top: 8, child: PercentChip(percent: c.progressPercent)),
                Positioned(right: 8, top: 8, child: FavoriteButton(campaignId: c.id, size: 30)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 38,
                    child: Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.2)),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: c.progress, minHeight: 6, backgroundColor: AppColors.sandBeige, color: AppColors.limeGreen),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${Formatter.rupiah(c.collectedAmount)} / ${Formatter.rupiah(c.targetAmount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: c.isFull ? null : onDonate,
                      icon: const Icon(Icons.favorite_rounded, size: 16),
                      label: Text(c.isFull ? 'Kuota penuh' : 'Donasi Sekarang'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
