import 'package:equatable/equatable.dart';

/// Jenis pelanggaran di fitur Komunitas (sama dengan nilai di backend).
enum ViolationType {
  hoax('hoax', 'Berita bohong (hoaks)'),
  hate('hate', 'Ujaran kebencian'),
  scam('scam', 'Penipuan / scam'),
  porn('porn', 'Pornografi'),
  blasphemy('blasphemy', 'Penistaan agama'),
  profanity('profanity', 'Kata-kata kotor');

  const ViolationType(this.code, this.label);
  final String code;
  final String label;
}

/// Aturan sanksi. Ubah angka di sini jika kebijakan berubah
/// (harus sama dengan CommunityGuard di backend).
class CommunityPolicy {
  CommunityPolicy._();

  /// Pelanggaran ke-1 = peringatan keras, ke-2 = banned.
  static const int strikesBeforeBan = 2;
  static const int banDays = 30;
}

class ModerationStatus extends Equatable {
  const ModerationStatus({this.strikes = 0, this.bannedUntil});

  final int strikes;
  final DateTime? bannedUntil;

  bool isBanned([DateTime? now]) {
    final until = bannedUntil;
    return until != null && until.isAfter(now ?? DateTime.now());
  }

  int get daysLeft {
    final until = bannedUntil;
    if (until == null) return 0;
    final hours = until.difference(DateTime.now()).inHours;
    return hours <= 0 ? 0 : (hours / 24).ceil();
  }

  @override
  List<Object?> get props => [strikes, bannedUntil];
}
