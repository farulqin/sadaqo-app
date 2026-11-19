import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/widgets/sadaqo_logo.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_detail_page.dart';
import 'package:sadaqo/features/campaign/presentation/widgets/program_list_card.dart';
import 'package:sadaqo/features/donation/presentation/pages/donation_page.dart';
import 'package:sadaqo/features/home/presentation/widgets/top_bar_actions.dart';
import 'package:sadaqo/core/widgets/category_icon.dart';

enum _Sort {
  newest('Terbaru'),
  nearGoal('Hampir tercapai'),
  mostCollected('Dana terbanyak'),
  deadline('Segera berakhir');

  const _Sort(this.label);
  final String label;
}

/// Dipakai sebagai tab "Program" dan halaman hasil klik kategori.
/// Saat satu kategori dipilih, muncul filter jenis (mis. Masjid / Mushola).
class CampaignListPage extends StatefulWidget {
  const CampaignListPage({super.key, this.initialCategory});

  final ProgramCategory? initialCategory;

  @override
  State<CampaignListPage> createState() => _CampaignListPageState();
}

class _CampaignListPageState extends State<CampaignListPage> {
  final _search = TextEditingController();
  ProgramCategory? _category;
  String? _subType;
  _Sort _sort = _Sort.newest;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _selectCategory(ProgramCategory? c) {
    setState(() {
      _category = c;
      _subType = null;
    });
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

  /// Lencana untuk kartu: unggulan (dana terbanyak), mendesak, atau terbaru.
  String? _badgeFor(Campaign c, Campaign? top) {
    if (top != null && c.id == top.id) return 'Program Unggulan';
    if (!c.isFull && c.daysLeft <= 7 && c.deadline.isAfter(DateTime.now())) return 'Mendesak';
    final p = c.publishedAt;
    if (p != null && DateTime.now().difference(p).inDays <= 14) return 'Terbaru';
    return null;
  }

  void _donate(Campaign c) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DonationPage(campaign: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CampaignCubit, CampaignState>(
        builder: (context, state) {
          final children = <Widget>[_hero(context)];

          if (state is CampaignError) {
            children.add(SizedBox(
              height: 300,
              child: ErrorView(message: state.message, onRetry: () => context.read<CampaignCubit>().load()),
            ));
          } else if (state is! CampaignLoaded) {
            children.add(const SizedBox(height: 300, child: LoadingView()));
          } else {
            final all = state.campaigns;
            Campaign? top;
            for (final c in all.where((c) => !c.isZakat)) {
              if (top == null || c.collectedAmount > top.collectedAmount) top = c;
            }

            final q = _search.text.trim().toLowerCase();
            final inCategory = all.where((c) => _category == null || c.category == _category).toList();

            final subTypes = <String>[];
            if (_category != null) {
              for (final c in inCategory) {
                final s = c.subType;
                if (s != null && !subTypes.contains(s)) subTypes.add(s);
              }
            }

            final items = inCategory.where((c) {
              if (_subType != null && c.subType != _subType) return false;
              if (q.isEmpty) return true;
              return c.title.toLowerCase().contains(q) ||
                  c.location.toLowerCase().contains(q) ||
                  c.description.toLowerCase().contains(q) ||
                  c.category.label.toLowerCase().contains(q) ||
                  (c.subType ?? '').toLowerCase().contains(q);
            }).toList();

            switch (_sort) {
              case _Sort.newest:
                items.sort((a, b) => (b.publishedAt ?? DateTime(2000)).compareTo(a.publishedAt ?? DateTime(2000)));
              case _Sort.nearGoal:
                items.sort((a, b) => b.progress.compareTo(a.progress));
              case _Sort.mostCollected:
                items.sort((a, b) => b.collectedAmount.compareTo(a.collectedAmount));
              case _Sort.deadline:
                items.sort((a, b) => a.deadline.compareTo(b.deadline));
            }

            children.add(_searchRow());
            children.add(_categoryChips());
            if (subTypes.length > 1) children.add(_subTypeChips(subTypes));

            if (items.isEmpty) {
              children.add(const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: Text('Program tidak ditemukan')),
              ));
            } else {
              for (final c in items) {
                children.add(Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: ProgramListCard(
                    campaign: c,
                    badge: _badgeFor(c, top),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CampaignDetailPage(campaign: c)),
                    ),
                    onDonate: () => c.isZakat
                        ? Navigator.of(context).push(MaterialPageRoute(builder: (_) => CampaignDetailPage(campaign: c)))
                        : _donate(c),
                  ),
                ));
              }
            }
            children.add(_tipCard());
          }

          return ListView(padding: const EdgeInsets.only(bottom: 24), children: children);
        },
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = !isMainTab(context);
    return SizedBox(
      height: top + 200,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFFF1EFDD))),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.66,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                colors: [Colors.transparent, Colors.black, Colors.black],
                stops: [0.0, 0.5, 1.0],
              ).createShader(r),
              child: Image.asset(AppAssets.masjidModel, fit: BoxFit.cover, alignment: Alignment.centerRight),
            ),
          ),
          Positioned(top: -10, right: -24, child: Image.asset(AppAssets.daunKanan, width: 130)),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(canPop ? 4 : 16, top + 10, 26, 12),
              decoration: const BoxDecoration(
                color: AppColors.forestGreen,
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(44)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canPop)
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                  const SadaqoLogo(size: 40),
                  const SizedBox(width: 10),
                  const Text('SADAQO', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: top + 6,
            child: const TopBarActions(color: AppColors.forestGreen),
          ),
          Positioned(
            left: 20,
            bottom: 16,
            right: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialCategory?.label ?? 'Program Donasi',
                  style: const TextStyle(fontSize: 28, height: 1.1, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Berbagi kebaikan, menebar manfaat untuk sesama',
                  style: TextStyle(fontSize: 13.5, height: 1.3, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
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
                decoration: InputDecoration(
                  hintText: 'Cari program donasi...',
                  hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.forestGreen),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => setState(_search.clear)),
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
            color: _sort == _Sort.newest ? Colors.white : AppColors.limeGreen,
            shape: const StadiumBorder(side: BorderSide(color: AppColors.sandBeige)),
            child: InkWell(
              customBorder: const StadiumBorder(),
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
      ),
    );
  }

  Widget _categoryChips() {
    Widget chip(String label, Widget Function(Color color) icon, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.forestGreen : AppColors.sandBeige.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  icon(selected ? Colors.white : AppColors.forestGreen),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textDark)),
                ],
              ),
            ),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          chip('Semua', (color) => Icon(Icons.grid_view_rounded, size: 18, color: color), _category == null, () => _selectCategory(null)),
          for (final c in ProgramCategory.values) chip(c.shortLabel, (color) => CategoryIcon(c, size: 18, color: color), _category == c, () => _selectCategory(c)),
        ],
      ),
    );
  }

  Widget _subTypeChips(List<String> subTypes) {
    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => onTap(),
            visualDensity: VisualDensity.compact,
            selectedColor: AppColors.limeGreen,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColors.forestGreen : AppColors.textDark),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          chip('Semua jenis', _subType == null, () => setState(() => _subType = null)),
          for (final s in subTypes) chip(s, _subType == s, () => setState(() => _subType = s)),
        ],
      ),
    );
  }

  Widget _tipCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EBC8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.eco_rounded, color: AppColors.success, size: 30),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bersama SADAQO, setiap donasi Anda menjadi bagian dari keberkahan yang lebih luas.',
                style: TextStyle(fontSize: 12.5, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
