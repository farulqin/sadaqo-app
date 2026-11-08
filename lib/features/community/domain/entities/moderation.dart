import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/error/failures.dart';

/// Jenis pelanggaran di fitur Komunitas.
enum ViolationType {
  hoax('Berita bohong (hoaks)'),
  hate('Ujaran kebencian'),
  scam('Penipuan / scam'),
  porn('Pornografi'),
  blasphemy('Penistaan agama'),
  profanity('Kata-kata kotor');

  const ViolationType(this.label);
  final String label;
}

/// Aturan sanksi. Ubah angka di sini jika kebijakan berubah.
class CommunityPolicy {
  CommunityPolicy._();

  /// Pelanggaran ke-1 = peringatan keras, ke-2 = banned.
  static const int strikesBeforeBan = 2;
  static const int banDays = 30;
  static const int maxMessageLength = 300;
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

/// Pesan mengandung konten terlarang. [status] = status SETELAH pelanggaran dicatat.
class ViolationFailure extends Failure {
  const ViolationFailure(this.type, this.status, super.message);

  final ViolationType type;
  final ModerationStatus status;
}

/// Pengguna sedang dibanned dari Komunitas.
class BannedFailure extends Failure {
  const BannedFailure(this.status, super.message);

  final ModerationStatus status;
}