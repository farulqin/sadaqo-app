import 'dart:async';

import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/community/data/datasources/community_admin_datasource.dart';
import 'package:sadaqo/features/community/domain/entities/chat_message.dart';
import 'package:sadaqo/features/community/domain/entities/moderation.dart';

abstract class CommunityLocalDataSource {
  Future<List<ChatMessage>> getMessages();
  Future<ChatMessage> postMessage({
    required String userId,
    required String userName,
    String? avatarAsset,
    required String text,
  });
  Future<ChatMessage> toggleReaction(String messageId, String emoji, String userId);
  Future<void> report(String messageId, String reporterId);
  Future<ModerationStatus> getStatus(String userId);
  Future<ModerationStatus> recordViolation(
    String userId, {
    String? userName,
    ViolationType? type,
    String? excerpt,
  });
}

/// Penyimpanan di memori selama backend belum siap (hilang saat aplikasi ditutup).
/// Pesan awal di bawah adalah contoh (fiktif).
class CommunityMemoryDataSource
    implements CommunityLocalDataSource, CommunityAdminDataSource {
  CommunityMemoryDataSource() : _messages = _seed();

  List<ChatMessage> _messages;
  final Map<String, ModerationStatus> _status = {};
  final List<MessageReport> _reports = []; // dibaca admin lewat API admin
  final List<ModerationEvent> _events = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _counter = 100;
  int _eventCounter = 1;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void _log(
    String userId,
    String userName,
    ModerationAction action,
    String detail,
  ) {
    _events.insert(
      0,
      ModerationEvent(
        id: 'e${_eventCounter++}',
        userId: userId,
        userName: userName,
        action: action,
        detail: detail,
        at: DateTime.now(),
      ),
    );
    if (_events.length > 300) _events.removeRange(300, _events.length);
  }

  static String _short(String text) =>
      text.length <= 80 ? text : '${text.substring(0, 80)}...';

  static List<ChatMessage> _seed() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 'c1',
        userId: 'seed-1',
        userName: 'Siti Rahma',
        avatarAsset: AppAssets.avatarsFemale[2],
        text: 'Assalamualaikum, semoga donasi untuk Masjid Al-Azzam segera tercapai ya 🤲',
        createdAt: now.subtract(const Duration(hours: 3)),
        reactions: {
          '🤲': {'seed-2', 'seed-3'},
        },
      ),
      ChatMessage(
        id: 'c2',
        userId: 'seed-2',
        userName: 'Ahmad Fauzi',
        avatarAsset: AppAssets.avatarsMale[2],
        text: 'Alhamdulillah barusan ikut Qurban Kolektif, tinggal beberapa slot lagi!',
        createdAt: now.subtract(const Duration(hours: 2)),
        reactions: {
          '❤️': {'seed-1'},
        },
      ),
      ChatMessage(
        id: 'c3',
        userId: 'seed-3',
        userName: 'Hamba Allah',
        text: 'Semangat berbagi, sekecil apa pun kebaikan itu berarti ❤️',
        createdAt: now.subtract(const Duration(minutes: 90)),
      ),
      ChatMessage(
        id: 'c4',
        userId: 'seed-4',
        userName: 'Nur Aini',
        avatarAsset: AppAssets.avatarsFemale[1],
        text: 'Ada yang sudah coba kalkulator zakat? Hitungnya mudah banget 😊',
        createdAt: now.subtract(const Duration(minutes: 40)),
      ),
    ];
  }

  @override
  Future<List<ChatMessage>> getMessages() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.of(_messages); // terlama di indeks 0
  }

  @override
  Future<ChatMessage> postMessage({
    required String userId,
    required String userName,
    String? avatarAsset,
    required String text,
  }) async {
    final message = ChatMessage(
      id: 'c${_counter++}',
      userId: userId,
      userName: userName,
      avatarAsset: avatarAsset,
      text: text,
      createdAt: DateTime.now(),
    );
    _messages = [..._messages, message];
    _notify();
    return message;
  }

  @override
  Future<ChatMessage> toggleReaction(String messageId, String emoji, String userId) async {
    final i = _messages.indexWhere((m) => m.id == messageId);
    if (i < 0) throw const CacheException('Pesan tidak ditemukan');

    final map = {
      for (final e in _messages[i].reactions.entries) e.key: Set<String>.of(e.value),
    };
    final users = map.putIfAbsent(emoji, () => <String>{});
    if (!users.remove(userId)) users.add(userId);
    if (users.isEmpty) map.remove(emoji);

    final updated = _messages[i].copyWith(reactions: map);
    _messages = List.of(_messages)..[i] = updated;
    _notify();
    return updated;
  }

  @override
  Future<void> report(String messageId, String reporterId) async {
    _reports.add(
      MessageReport(messageId: messageId, reporterId: reporterId, at: DateTime.now()),
    );
    _notify();
  }

  @override
  Future<ModerationStatus> getStatus(String userId) async {
    final s = _status[userId] ?? const ModerationStatus();
    // Masa banned selesai: catatan pelanggaran dibersihkan.
    if (s.bannedUntil != null && !s.isBanned()) {
      _status[userId] = const ModerationStatus();
      return const ModerationStatus();
    }
    return s;
  }

  @override
  Future<ModerationStatus> recordViolation(
    String userId, {
    String? userName,
    ViolationType? type,
    String? excerpt,
  }) async {
    final current = await getStatus(userId);
    final strikes = current.strikes + 1;
    final banned = strikes >= CommunityPolicy.strikesBeforeBan;
    final next = ModerationStatus(
      strikes: strikes,
      bannedUntil: banned
          ? DateTime.now().add(const Duration(days: CommunityPolicy.banDays))
          : null,
    );
    _status[userId] = next;

    final kind = type?.label ?? 'Pelanggaran';
    final quote = excerpt == null ? '' : ' - "${_short(excerpt)}"';
    _log(
      userId,
      userName ?? userId,
      banned ? ModerationAction.autoBan : ModerationAction.autoWarning,
      '$kind$quote',
    );
    _notify();
    return next;
  }

  // ===================== API ADMIN =====================
  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  @override
  List<MessageReport> get reports => List.unmodifiable(_reports);

  @override
  List<ModerationEvent> get events => List.unmodifiable(_events);

  @override
  ModerationStatus statusOf(String userId) {
    final s = _status[userId] ?? const ModerationStatus();
    if (s.bannedUntil != null && !s.isBanned()) {
      _status[userId] = const ModerationStatus();
      return const ModerationStatus();
    }
    return s;
  }

  @override
  Map<String, ModerationStatus> get allStatuses => {
        for (final id in List<String>.of(_status.keys)) id: statusOf(id),
      };

  @override
  void deleteMessage(String messageId) {
    final i = _messages.indexWhere((m) => m.id == messageId);
    if (i < 0) return;
    final m = _messages[i];
    _messages = List.of(_messages)..removeAt(i);
    _reports.removeWhere((r) => r.messageId == messageId);
    _log(m.userId, m.userName, ModerationAction.messageDeleted, _short(m.text));
    _notify();
  }

  @override
  void dismissReport(String messageId) {
    _reports.removeWhere((r) => r.messageId == messageId);
    _log('-', '-', ModerationAction.reportDismissed, 'Laporan pesan $messageId ditutup');
    _notify();
  }

  @override
  void warnUser(String userId, String userName, {String? note}) {
    final cur = statusOf(userId);
    _status[userId] = ModerationStatus(
      strikes: cur.strikes + 1,
      bannedUntil: cur.bannedUntil,
    );
    _log(userId, userName, ModerationAction.adminWarning, note ?? 'Peringatan dari admin');
    _notify();
  }

  @override
  void banUser(String userId, String userName, Duration duration, {String? note}) {
    final cur = statusOf(userId);
    final strikes = cur.strikes < CommunityPolicy.strikesBeforeBan
        ? CommunityPolicy.strikesBeforeBan
        : cur.strikes;
    _status[userId] = ModerationStatus(
      strikes: strikes,
      bannedUntil: DateTime.now().add(duration),
    );
    final days = duration.inDays;
    _log(
      userId,
      userName,
      ModerationAction.adminBan,
      '${days >= 3650 ? 'Permanen' : '$days hari'}${note == null || note.isEmpty ? '' : ' - $note'}',
    );
    _notify();
  }

  @override
  void liftBan(String userId, String userName) {
    _status[userId] = const ModerationStatus();
    _log(userId, userName, ModerationAction.adminUnban, 'Banned dibebaskan, catatan pelanggaran direset');
    _notify();
  }
}