import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_error.dart';
import 'package:sadaqo/features/community_feed/domain/moderation.dart';

/// Satu laporan dari anggota (post atau komentar).
class CommunityReport {
  const CommunityReport({
    required this.id,
    required this.status,
    required this.reason,
    required this.kind,
    required this.content,
    required this.reporterName,
    required this.createdAt,
    this.postId,
    this.commentId,
    this.authorName,
    this.isHidden = false,
  });

  final String id;
  final String status; // pending | valid | dismissed
  final String reason;
  final String kind; // post | comment
  final String content;
  final String reporterName;
  final DateTime createdAt;
  final String? postId;
  final String? commentId;
  final String? authorName;
  final bool isHidden;

  bool get isPending => status == 'pending';

  factory CommunityReport.fromJson(Map<String, dynamic> j) => CommunityReport(
        id: '${j['id']}',
        status: (j['status'] ?? 'pending') as String,
        reason: (j['reason'] ?? '') as String,
        kind: (j['kind'] ?? 'post') as String,
        content: (j['content'] ?? '') as String,
        reporterName: (j['reporter_name'] ?? '-') as String,
        createdAt: DateTime.tryParse('${j['created_at']}')?.toLocal() ?? DateTime.now(),
        postId: j['post_id'] == null ? null : '${j['post_id']}',
        commentId: j['comment_id'] == null ? null : '${j['comment_id']}',
        authorName: j['author_name'] as String?,
        isHidden: j['is_hidden'] == true,
      );
}

/// Laporan Komunitas untuk admin (data dari API, bukan data lokal).
class AdminCommunityStore extends ChangeNotifier {
  AdminCommunityStore(this._dio);

  final Dio _dio;

  List<CommunityReport> _reports = const [];
  bool _loading = false;
  String? _error;

  List<CommunityReport> get reports => _reports;
  bool get loading => _loading;
  String? get error => _error;
  int get pendingCount => _reports.where((r) => r.isPending).length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _dio.get('/admin/community/reports');
      _reports = ApiError.list(res.data).map(CommunityReport.fromJson).toList();
    } on DioException catch (e) {
      _error = ApiError.message(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// [valid] = konten disembunyikan dan penulis kena sanksi. Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> review(CommunityReport r, {required bool valid, ViolationType? violation}) async {
    try {
      await _dio.patch(
        '/admin/community/reports/${r.id}',
        data: {
          'decision': valid ? 'valid' : 'dismissed',
          if (valid) 'violation_type': (violation ?? ViolationType.hoax).code,
        },
      );
      await load();
      return null;
    } on DioException catch (e) {
      return ServerException(ApiError.message(e)).message;
    }
  }

  /// Peringatan ke seorang anggota. Endpoint: POST /admin/users/{id}/warn
  /// (peringatan ke-2 otomatis banned 30 hari, diatur backend).
  Future<String?> warnUser(String userId, {String message = '', ViolationType? violation}) async {
    final note = [
      if (violation != null) violation.label,
      if (message.isNotEmpty) message,
    ].join(': ');
    try {
      await _dio.post(
        '/admin/users/$userId/warn',
        data: {if (note.isNotEmpty) 'note': note},
      );
      return null;
    } on DioException catch (e) {
      return ServerException(ApiError.message(e)).message;
    }
  }

  /// Banned dari Komunitas selama [days] hari. Endpoint: POST /admin/users/{id}/ban
  Future<String?> banUser(String userId, {required int days, String reason = ''}) async {
    try {
      await _dio.post(
        '/admin/users/$userId/ban',
        data: {'days': days, if (reason.isNotEmpty) 'reason': reason},
      );
      return null;
    } on DioException catch (e) {
      return ServerException(ApiError.message(e)).message;
    }
  }

  /// Cabut banned dan reset pelanggaran. Endpoint: POST /admin/users/{id}/lift
  Future<String?> unbanUser(String userId) async {
    try {
      await _dio.post('/admin/users/$userId/lift');
      return null;
    } on DioException catch (e) {
      return ServerException(ApiError.message(e)).message;
    }
  }
}