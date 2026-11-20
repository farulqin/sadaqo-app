// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/widgets/sadaqo_logo.dart';
import 'package:sadaqo/features/home/presentation/widgets/top_bar_actions.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/community_feed/domain/community_models.dart';
import 'package:sadaqo/features/community_feed/presentation/cubit/community_feed_cubit.dart';
import 'package:sadaqo/features/community_feed/presentation/pages/create_post_page.dart';
import 'package:sadaqo/features/community_feed/presentation/widgets/community_widgets.dart';
import 'package:sadaqo/features/community_feed/presentation/pages/community_agenda_page.dart';
import 'package:sadaqo/features/community_feed/presentation/pages/community_badges_page.dart';
import 'package:sadaqo/features/community_feed/presentation/pages/community_members_page.dart';

/// Halaman Komunitas: ringkasan, filter (Semua/Diskusi/Polling/Info), dan feed.
class CommunityHomePage extends StatefulWidget {
  const CommunityHomePage({super.key});

  @override
  State<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends State<CommunityHomePage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CommunityFeedCubit>().load(viewerId: context.read<AuthCubit>().user?.id);
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        context.read<CommunityFeedCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _compose() async {
    if (!await ensureJoined(context)) return;
    if (!mounted) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
    if (created == true && mounted) {
      showCommunitySnack(context, 'Post berhasil dibagikan');
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  Future<void> _toggleMembership(CommunityOverview o) async {
    final cubit = context.read<CommunityFeedCubit>();
    if (!o.joined) {
      final err = await cubit.join();
      if (mounted && err != null) showCommunitySnack(context, err);
      return;
    }
    final ok = await confirmCommunity(
      context,
      title: 'Keluar dari Komunitas?',
      message: 'Kamu tetap bisa membaca, tapi tidak bisa menulis atau berkomentar sampai bergabung lagi.',
      confirmLabel: 'Keluar',
    );
    if (!ok || !mounted) return;
    final err = await cubit.leave();
    if (mounted && err != null) showCommunitySnack(context, err);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommunityFeedCubit>();
    return Scaffold(
      body: Stack(
        children: [
          // Hiasan daun di dua sudut bawah (sesuai referensi).
          const Positioned(left: -20, bottom: -10, child: _Leaf(AppAssets.daunKiri, width: 150)),
          const Positioned(right: -20, bottom: -10, child: _Leaf(AppAssets.daunKanan, width: 140)),
          BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
            builder: (context, state) {
              final overview = state.overview;
              return RefreshIndicator(
                onRefresh: cubit.load,
                edgeOffset: MediaQuery.of(context).padding.top + 60,
                child: ListView.builder(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: state.posts.length + 5,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return _Header(
                        overview: overview,
                        onToggle: overview == null ? null : () => _toggleMembership(overview),
                      );
                    }
                    if (i == 1) return const _QuickActions();
                    if (i == 2) return _FilterBar(current: state.filter, onSelected: cubit.setFilter);
                    if (i == 3) return _padded(_Composer(onTap: _compose));
                    if (i == state.posts.length + 4) return _body(state, cubit);
                    final post = state.posts[i - 4];
                    return _padded(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostCard(post: post, onOpen: () => openPostDetail(context, post)),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _padded(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

  /// Bagian bawah daftar: loading awal, error, kosong, atau muat lebih banyak.
  Widget _body(CommunityFeedState state, CommunityFeedCubit cubit) {
    if (state.error != null && state.posts.isEmpty) {
      return SizedBox(height: 260, child: ErrorView(message: state.error!, onRetry: cubit.load));
    }
    return _Footer(state: state, onMore: cubit.loadMore);
  }
}

class _Leaf extends StatelessWidget {
  const _Leaf(this.asset, {required this.width});

  final String asset;
  final double width;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(opacity: 0.55, child: Image.asset(asset, width: width, fit: BoxFit.contain)),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onSelected});

  final String current;
  final ValueChanged<String> onSelected;

  static const _filters = [
    ('all', 'Semua'),
    ('diskusi', 'Diskusi'),
    ('polling', 'Polling'),
    ('info', 'Info'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.sandBeige.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            for (final f in _filters)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(f.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: current == f.$1 ? AppColors.forestGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: current == f.$1 ? Colors.white : AppColors.brandInk,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

class _Header extends StatelessWidget {
  const _Header({required this.overview, required this.onToggle});

  final CommunityOverview? overview;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final o = overview;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, top + 8, 8, 16),
      decoration: const BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: logo kiri, judul, notifikasi + profil kanan.
          Row(
            children: [
              const SadaqoLogo(size: 42),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Komunitas',
                  style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                ),
              ),
              const TopBarActions(),
            ],
          ),
          const SizedBox(height: 12),
          // Banner masjid.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 158,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(AppAssets.masjidModel, fit: BoxFit.cover, alignment: Alignment.centerRight),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.forestGreen.withValues(alpha: 0.92),
                            AppColors.forestGreen.withValues(alpha: 0.55),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 0.85],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      width: 170,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Komunitas\nSADAQO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Bersama berbagi,\nmenebar manfaat',
                            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Anggota + tombol gabung.
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                const _AvatarStack(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o == null ? 'Memuat...' : '${_compact(o.memberCount)} Anggota',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      if (o != null)
                        Text(
                          '${o.onlineCount} online • ${o.activePolls} polling aktif',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.limeGreen, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
                if (o != null)
                  o.joined
                      ? OutlinedButton.icon(
                          onPressed: onToggle,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Tergabung'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: onToggle,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Gabung'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.brandInk,
                          ),
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tumpukan foto anggota kecil (hiasan, memakai avatar bawaan aplikasi).
class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    const size = 30.0;
    const overlap = 20.0;
    final shown = AppAssets.avatars.take(4).toList();
    return SizedBox(
      width: size + overlap * (shown.length - 1),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brandInk, width: 2),
                ),
                child: ClipOval(child: Image.asset(shown[i], fit: BoxFit.cover)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandBeige),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.sandBeige,
                  child: Text(
                    user?.initial ?? '?',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brandInk),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Apa yang ingin kamu bagikan?',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
                Icon(Icons.edit_note_rounded, color: AppColors.brandInk),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onMore});

  final CommunityFeedState state;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Padding(padding: EdgeInsets.all(24), child: LoadingView());
    }
    if (state.posts.isEmpty) {
      final text = switch (state.filter) {
        'polling' => 'Belum ada polling.',
        'info' => 'Belum ada pengumuman.',
        'diskusi' => 'Belum ada diskusi. Mulailah yang pertama!',
        _ => 'Belum ada post. Mulailah yang pertama!',
      };
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(text, style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    if (state.loadingMore) {
      return const Padding(padding: EdgeInsets.all(16), child: LoadingView());
    }
    if (state.hasMore) {
      return Center(child: TextButton(onPressed: onMore, child: const Text('Muat lebih banyak')));
    }
    return const SizedBox(height: 8);
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.event_rounded,
              label: 'Agenda',
              onTap: () => _open(context, const CommunityAgendaPage()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: Icons.groups_rounded,
              label: 'Anggota',
              onTap: () => _open(context, const CommunityMembersPage()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: Icons.workspace_premium_rounded,
              label: 'Badge Saya',
              onTap: () => _open(context, const CommunityBadgesPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sandBeige),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.brandInk),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}