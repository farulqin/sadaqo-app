import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/community_feed/domain/community_models.dart';
import 'package:sadaqo/features/community_feed/presentation/cubit/community_feed_cubit.dart';
import 'package:sadaqo/features/community_feed/presentation/pages/create_post_page.dart';
import 'package:sadaqo/features/community_feed/presentation/widgets/community_widgets.dart';

/// Halaman Komunitas: ringkasan, filter (Semua/Diskusi/Polling/Info), dan feed.
class CommunityHomePage extends StatefulWidget {
  const CommunityHomePage({super.key});

  @override
  State<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends State<CommunityHomePage> {
  final _scroll = ScrollController();

  static const _filters = [
    ('all', 'Semua'),
    ('diskusi', 'Diskusi'),
    ('polling', 'Polling'),
    ('info', 'Info'),
  ];

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
      body: BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
        builder: (context, state) {
          final overview = state.overview;
          return Column(
            children: [
              _Header(overview: overview, onToggle: overview == null ? null : () => _toggleMembership(overview)),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    for (final f in _filters)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f.$2),
                          selected: state.filter == f.$1,
                          showCheckmark: false,
                          selectedColor: AppColors.forestGreen,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: state.filter == f.$1 ? Colors.white : AppColors.textDark,
                          ),
                          onSelected: (_) => cubit.setFilter(f.$1),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _feed(state, cubit)),
            ],
          );
        },
      ),
    );
  }

  Widget _feed(CommunityFeedState state, CommunityFeedCubit cubit) {
    if (state.loading && state.posts.isEmpty) return const LoadingView();
    if (state.error != null && state.posts.isEmpty) {
      return ErrorView(message: state.error!, onRetry: cubit.load);
    }
    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: state.posts.length + 2,
        itemBuilder: (context, i) {
          if (i == 0) return _Composer(onTap: _compose);
          if (i == state.posts.length + 1) return _Footer(state: state, onMore: cubit.loadMore);
          final post = state.posts[i - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(post: post, onOpen: () => openPostDetail(context, post)),
          );
        },
      ),
    );
  }
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
      padding: EdgeInsets.fromLTRB(16, top + 14, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Komunitas SADAQO',
                      style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Bersama berbagi, menebar manfaat',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o == null ? 'Memuat...' : '${o.memberCount} Anggota',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    if (o != null)
                      Text(
                        '${o.onlineCount} online • ${o.activePolls} polling aktif',
                        style: const TextStyle(color: AppColors.limeGreen, fontSize: 12, fontWeight: FontWeight.w600),
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
                          backgroundColor: AppColors.limeGreen,
                          foregroundColor: AppColors.forestGreen,
                        ),
                      ),
            ],
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
        color: Colors.white,
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
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Apa yang ingin kamu bagikan?',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
                const Icon(Icons.edit_note_rounded, color: AppColors.forestGreen),
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
          child: Text(text, style: const TextStyle(color: AppColors.textMuted)),
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