import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/error/exceptions.dart';
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
  Future<ModerationStatus> recordViolation(String userId);
}

/// Penyimpanan di memori selama backend belum siap (hilang saat aplikasi ditutup).
/// Pesan awal di bawah adalah contoh (fiktif).
class CommunityMemoryDataSource implements CommunityLocalDataSource {
  CommunityMemoryDataSource() : _messages = _seed();

  List<ChatMessage> _messages;
  final Map<String, ModerationStatus> _status = {};
  final List<(String, String)> _reports = []; // (id pesan, id pelapor)
  int _counter = 100;

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
    return updated;
  }

  @override
  Future<void> report(String messageId, String reporterId) async {
    _reports.add((messageId, reporterId)); // nanti dikirim ke admin lewat API
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
  Future<ModerationStatus> recordViolation(String userId) async {
    final current = await getStatus(userId);
    final strikes = current.strikes + 1;
    final next = ModerationStatus(
      strikes: strikes,
      bannedUntil: strikes >= CommunityPolicy.strikesBeforeBan
          ? DateTime.now().add(const Duration(days: CommunityPolicy.banDays))
          : null,
    );
    _status[userId] = next;
    return next;
  }
}