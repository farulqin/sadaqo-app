import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_error.dart';
import 'package:sadaqo/features/community_feed/domain/community_models.dart';

/// Panggilan API Komunitas. Semua kegagalan dilempar sebagai ServerException
/// dengan pesan dari server (banned, konten terlarang, belum gabung, dst).
class CommunityFeedApi {
  const CommunityFeedApi(this._dio);

  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ServerException(ApiError.message(e));
    }
  }

  Future<CommunityOverview> overview() => _run(() async {
        final res = await _dio.get('/community/overview');
        return CommunityOverview.fromJson(ApiError.object(res.data));
      });

  Future<void> join() => _run(() => _dio.post('/community/join'));

  Future<void> leave() => _run(() => _dio.delete('/community/join'));

  Future<PostPage> posts({String filter = 'all', int page = 1}) => _run(() async {
        final res = await _dio.get(
          '/community/posts',
          queryParameters: {'filter': filter, 'page': page},
        );
        final body = res.data as Map<String, dynamic>;
        final meta = body['meta'] is Map ? body['meta'] as Map : const {};
        return PostPage(
          items: ApiError.list(body).map(CommunityPost.fromJson).toList(),
          page: (meta['page'] as num?)?.toInt() ?? page,
          lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
        );
      });

  Future<int> uploadPhoto(Uint8List bytes) => _run(() async {
        final form = FormData.fromMap({
          'group': 'other',
          'file': MultipartFile.fromBytes(bytes, filename: 'foto.jpg'),
        });
        final res = await _dio.post('/uploads', data: form);
        return (ApiError.object(res.data)['id'] as num).toInt();
      });

  Future<CommunityPost> createPost({
    required String category,
    required String body,
    int? imageId,
    String? pollQuestion,
    List<String> pollOptions = const [],
    int pollDays = 3,
  }) =>
      _run(() async {
        final res = await _dio.post(
          '/community/posts',
          data: {
            'category': category,
            'body': body,
            'image_asset_id': ?imageId,
            if (pollQuestion != null)
              'poll': {
                'question': pollQuestion,
                'options': pollOptions,
                'days': pollDays,
              },
          },
        );
        return CommunityPost.fromJson(ApiError.object(res.data));
      });

  Future<void> deletePost(String id) => _run(() => _dio.delete('/community/posts/$id'));

  Future<({bool liked, int count})> toggleLike(String id) => _run(() async {
        final res = await _dio.post('/community/posts/$id/like');
        final d = ApiError.object(res.data);
        return (liked: d['liked'] == true, count: (d['like_count'] as num?)?.toInt() ?? 0);
      });

  Future<CommunityPoll> vote(int pollId, int optionId) => _run(() async {
        final res = await _dio.post(
          '/community/polls/$pollId/vote',
          data: {'option_id': optionId},
        );
        return CommunityPoll.fromJson(ApiError.object(res.data));
      });

  Future<void> reportPost(String id, String reason) =>
      _run(() => _dio.post('/community/posts/$id/report', data: {'reason': reason}));

  Future<void> reportComment(String id, String reason) =>
      _run(() => _dio.post('/community/comments/$id/report', data: {'reason': reason}));

  Future<List<CommunityComment>> comments(String postId) => _run(() async {
        final res = await _dio.get('/community/posts/$postId/comments');
        return ApiError.list(res.data).map(CommunityComment.fromJson).toList();
      });

  Future<CommunityComment> addComment(String postId, String body, {String? parentId}) =>
      _run(() async {
        final res = await _dio.post(
          '/community/posts/$postId/comments',
          data: {
            'body': body,
            if (parentId != null) 'parent_id': int.tryParse(parentId) ?? parentId,
          },
        );
        return CommunityComment.fromJson(ApiError.object(res.data));
      });

  Future<void> deleteComment(String id) =>
      _run(() => _dio.delete('/community/comments/$id'));

  Future<CommunityPost> post(String id) => _run(() async {
        final res = await _dio.get('/community/posts/$id');
        return CommunityPost.fromJson(ApiError.object(res.data));
      });

  Future<List<CommunityEvent>> events() => _run(() async {
        final res = await _dio.get('/community/events');
        return ApiError.list(res.data).map(CommunityEvent.fromJson).toList();
      });

  Future<({bool interested, int count})> toggleInterest(String id) => _run(() async {
        final res = await _dio.post('/community/events/$id/interest');
        final d = ApiError.object(res.data);
        return (
          interested: d['interested'] == true,
          count: (d['interested_count'] as num?)?.toInt() ?? 0,
        );
      });

  Future<({List<CommunityAuthor> items, int page, int lastPage})> members({
    String filter = 'semua',
    String q = '',
    int page = 1,
  }) =>
      _run(() async {
        final res = await _dio.get(
          '/community/members',
          queryParameters: {'filter': filter, 'q': q, 'page': page},
        );
        final body = res.data as Map<String, dynamic>;
        final meta = body['meta'] is Map ? body['meta'] as Map : const {};
        return (
          items: ApiError.list(body).map(CommunityAuthor.fromJson).toList(),
          page: (meta['page'] as num?)?.toInt() ?? page,
          lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
        );
      });
}