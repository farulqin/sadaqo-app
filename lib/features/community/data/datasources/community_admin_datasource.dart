import 'package:sadaqo/features/community/domain/entities/chat_message.dart';
import 'package:sadaqo/features/community/domain/entities/moderation.dart';

/// Jenis peristiwa moderasi yang dicatat (dipakai halaman Komunitas di dashboard admin).
enum ModerationAction {
  autoWarning('Peringatan otomatis'),
  autoBan('Banned otomatis'),
  adminWarning('Peringatan admin'),
  adminBan('Banned oleh admin'),
  adminUnban('Banned dibebaskan'),
  messageDeleted('Pesan dihapus'),
  reportDismissed('Laporan ditutup');

  const ModerationAction(this.label);
  final String label;

  bool get isAuto => this == autoWarning || this == autoBan;
}

class ModerationEvent {
  const ModerationEvent({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.detail,
    required this.at,
  });

  final String id;
  final String userId;
  final String userName;
  final ModerationAction action;
  final String detail;
  final DateTime at;
}

/// Laporan pengguna terhadap sebuah pesan (tombol "Laporkan" di Komunitas).
class MessageReport {
  const MessageReport({
    required this.messageId,
    required this.reporterId,
    required this.at,
  });

  final String messageId;
  final String reporterId;
  final DateTime at;
}

/// Akses khusus admin ke data Komunitas. Diimplementasikan oleh sumber data
/// yang sama dengan aplikasi pengguna, sehingga admin melihat data yang sama.
/// Saat backend Laravel siap, ganti dengan implementasi API admin.
abstract class CommunityAdminDataSource {
  /// Memancarkan sinyal setiap ada perubahan (pesan baru, laporan, banned, dll).
  Stream<void> get changes;

  List<ChatMessage> get messages; // terlama di indeks 0
  List<MessageReport> get reports;
  List<ModerationEvent> get events; // terbaru di indeks 0

  ModerationStatus statusOf(String userId);
  Map<String, ModerationStatus> get allStatuses;

  void deleteMessage(String messageId);
  void dismissReport(String messageId);
  void warnUser(String userId, String userName, {String? note});
  void banUser(String userId, String userName, Duration duration, {String? note});
  void liftBan(String userId, String userName);
}
