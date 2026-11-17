import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/community_feed/data/community_feed_api.dart';
import 'package:sadaqo/features/community_feed/domain/community_models.dart';

class CommunityFeedState {
  const CommunityFeedState({
    this.viewerId,
    this.filter = 'all',
    this.posts = const [],
    this.page = 1,
    this.lastPage = 1,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.overview,
  });

  final String? viewerId;
  final String filter; // all | diskusi | polling | info
  final List<CommunityPost> posts;
  final int page;
  final int lastPage;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final CommunityOverview? overview;

  bool get hasMore => page < lastPage;

  CommunityFeedState copyWith({
    String? viewerId,
    String? filter,
    List<CommunityPost>? posts,
    int? page,
    int? lastPage,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
    CommunityOverview? overview,
  }) =>
      CommunityFeedState(
        viewerId: viewerId ?? this.viewerId,
        filter: filter ?? this.filter,
        posts: posts ?? this.posts,
        page: page ?? this.page,
        lastPage: lastPage ?? this.lastPage,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        error: clearError ? null : (error ?? this.error),
        overview: overview ?? this.overview,
      );
}

/// Feed Komunitas. Aksi mengembalikan pesan error (String) atau null bila berhasil.
class CommunityFeedCubit extends Cubit<CommunityFeedState> {
  CommunityFeedCubit(this._api) : super(const CommunityFeedState());

  final CommunityFeedApi _api;

  /// Muat ringkasan dan feed. Bila pengguna berganti akun, data lama dibuang.
  Future<void> load({String? viewerId}) async {
    final changedUser = viewerId != null && viewerId != state.viewerId;
    emit(
      (changedUser ? const CommunityFeedState() : state).copyWith(
        viewerId: viewerId ?? state.viewerId,
        loading: true,
        clearError: true,
      ),
    );
    try {
      final results = await Future.wait([
        _api.overview(),
        _api.posts(filter: state.filter),
      ]);
      final page = results[1] as PostPage;
      emit(state.copyWith(
        overview: results[0] as CommunityOverview,
        posts: page.items,
        page: page.page,
        lastPage: page.lastPage,
        loading: false,
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }

  /// Muat ulang tanpa memunculkan spinner (saat tab dibuka lagi).
  Future<void> refreshQuiet() async {
    if (state.loading) return;
    try {
      final results = await Future.wait([
        _api.overview(),
        _api.posts(filter: state.filter),
      ]);
      final page = results[1] as PostPage;
      emit(state.copyWith(
        overview: results[0] as CommunityOverview,
        posts: page.items,
        page: page.page,
        lastPage: page.lastPage,
        clearError: true,
      ));
    } on ServerException {
      // Biarkan data lama.
    }
  }

  Future<void> setFilter(String filter) async {
    if (filter == state.filter) return;
    emit(state.copyWith(filter: filter, posts: const [], loading: true, clearError: true));
    try {
      final page = await _api.posts(filter: filter);
      emit(state.copyWith(
        posts: page.items,
        page: page.page,
        lastPage: page.lastPage,
        loading: false,
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final next = await _api.posts(filter: state.filter, page: state.page + 1);
      emit(state.copyWith(
        posts: [...state.posts, ...next.items],
        page: next.page,
        lastPage: next.lastPage,
        loadingMore: false,
      ));
    } on ServerException {
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> _refreshOverview() async {
    try {
      emit(state.copyWith(overview: await _api.overview()));
    } on ServerException {
      // Abaikan.
    }
  }

  Future<String?> join() async {
    try {
      await _api.join();
      await _refreshOverview();
      return null;
    } on ServerException catch (e) {
      return e.message;
    }
  }

  Future<String?> leave() async {
    try {
      await _api.leave();
      await _refreshOverview();
      return null;
    } on ServerException catch (e) {
      return e.message;
    }
  }

  void _replace(CommunityPost p) => emit(
        state.copyWith(posts: [for (final x in state.posts) x.id == p.id ? p : x]),
      );

  /// Apresiasi: berubah di layar dulu, dikembalikan bila server menolak.
  Future<String?> toggleLike(CommunityPost post) async {
    final optimistic = post.copyWith(
      liked: !post.liked,
      likeCount: post.likeCount + (post.liked ? -1 : 1),
    );
    _replace(optimistic);
    try {
      final r = await _api.toggleLike(post.id);
      _replace(optimistic.copyWith(liked: r.liked, likeCount: r.count));
      return null;
    } on ServerException catch (e) {
      _replace(post);
      return e.message;
    }
  }

  Future<String?> vote(CommunityPost post, int optionId) async {
    final poll = post.poll;
    if (poll == null) return 'Polling tidak ditemukan.';
    try {
      final updated = await _api.vote(poll.id, optionId);
      _replace(post.copyWith(poll: updated));
      return null;
    } on ServerException catch (e) {
      return e.message;
    }
  }

  Future<String?> createPost({
    required String category,
    required String body,
    Uint8List? imageBytes,
    String? pollQuestion,
    List<String> pollOptions = const [],
    int pollDays = 3,
  }) async {
    try {
      final imageId = imageBytes == null ? null : await _api.uploadPhoto(imageBytes);
      final post = await _api.createPost(
        category: category,
        body: body,
        imageId: imageId,
        pollQuestion: pollQuestion,
        pollOptions: pollOptions,
        pollDays: pollDays,
      );
      final f = state.filter;
      final matches = f == 'all' || f == category || (f == 'polling' && post.poll != null);
      emit(state.copyWith(posts: matches ? [post, ...state.posts] : state.posts));
      _refreshOverview();
      return null;
    } on ServerException catch (e) {
      return e.message;
    }
  }

  Future<String?> deletePost(CommunityPost post) async {
    try {
      await _api.deletePost(post.id);
      emit(state.copyWith(posts: [for (final x in state.posts) if (x.id != post.id) x]));
      _refreshOverview();
      return null;
    } on ServerException catch (e) {
      return e.message;
    }
  }

  Future<String?> reportPost(CommunityPost post, String reason) async {
    try {
      await _api.reportPost(post.id, reason);
      return null;
    } on ServerException catch (e) {
      return e.message;
    }
  }

  /// Dipanggil halaman detail saat komentar ditambah (+) atau dihapus (-).
  void adjustCommentCount(String postId, int delta) {
    emit(state.copyWith(posts: [
      for (final p in state.posts)
        p.id == postId
            ? p.copyWith(commentCount: (p.commentCount + delta).clamp(0, 1 << 30))
            : p,
    ]));
  }
}