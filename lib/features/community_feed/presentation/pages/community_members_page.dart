// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/community_feed/data/community_feed_api.dart';
import 'package:sadaqo/features/community_feed/domain/community_models.dart';
import 'package:sadaqo/features/community_feed/presentation/widgets/community_widgets.dart';
import 'package:sadaqo/injection_container.dart';

/// Daftar anggota: cari nama, filter Semua/Online/Admin.
class CommunityMembersPage extends StatefulWidget {
  const CommunityMembersPage({super.key});

  @override
  State<CommunityMembersPage> createState() => _CommunityMembersPageState();
}

class _CommunityMembersPageState extends State<CommunityMembersPage> {
  final _api = sl<CommunityFeedApi>();
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  List<CommunityAuthor> _items = const [];
  String _filter = 'semua';
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  static const _filters = [
    ('semua', 'Semua'),
    ('online', 'Online'),
    ('admin', 'Admin'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
        _more();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.members(filter: _filter, q: _search.text.trim());
      if (!mounted) return;
      setState(() {
        _items = r.items;
        _page = r.page;
        _lastPage = r.lastPage;
        _loading = false;
      });
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _more() async {
    if (_loading || _loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final r = await _api.members(filter: _filter, q: _search.text.trim(), page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...r.items];
        _page = r.page;
        _lastPage = r.lastPage;
        _loadingMore = false;
      });
    } on ServerException {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        title: const Text('Anggota Komunitas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Cari anggota...',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      showCheckmark: false,
                      selectedColor: AppColors.forestGreen,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _filter == f.$1 ? Colors.white : AppColors.textDark,
                      ),
                      onSelected: (_) {
                        setState(() => _filter = f.$1);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : _items.isEmpty
                        ? Center(
                            child: Text('Tidak ada anggota yang cocok.',
                                style: TextStyle(color: AppColors.textMuted)),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              controller: _scroll,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: _items.length + (_loadingMore ? 1 : 0),
                              separatorBuilder: (context, i) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                if (i >= _items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: LoadingView(),
                                  );
                                }
                                return _MemberTile(member: _items[i]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final CommunityAuthor member;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sandBeige),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CommunityAvatar(member, radius: 22),
              if (member.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthorName(member),
                Text(
                  member.handle,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (!member.isStaff)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.pill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Anggota',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}