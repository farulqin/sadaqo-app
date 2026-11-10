import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/community/domain/entities/chat_message.dart';
import 'package:sadaqo/features/community/domain/entities/moderation.dart';
import 'package:sadaqo/features/community/domain/repositories/community_repository.dart';
import 'package:sadaqo/features/community/domain/services/content_moderator.dart';

class GetMessages implements UseCase<List<ChatMessage>, NoParams> {
  const GetMessages(this._repository);

  final CommunityRepository _repository;

  @override
  Future<Either<Failure, List<ChatMessage>>> call(NoParams params) =>
      _repository.getMessages();
}

/// Parameter: id pengguna.
class GetModerationStatus implements UseCase<ModerationStatus, String> {
  const GetModerationStatus(this._repository);

  final CommunityRepository _repository;

  @override
  Future<Either<Failure, ModerationStatus>> call(String userId) =>
      _repository.getStatus(userId);
}

/// Aturan bisnis kirim pesan:
/// 1) tidak kosong dan maksimal 300 karakter,
/// 2) tolak jika pengguna sedang banned,
/// 3) periksa konten; jika terlarang, catat pelanggaran (peringatan atau banned)
///    dan pesan TIDAK dikirim.
class SendMessage implements UseCase<ChatMessage, SendMessageParams> {
  const SendMessage(this._repository);

  final CommunityRepository _repository;

  @override
  Future<Either<Failure, ChatMessage>> call(SendMessageParams p) async {
    final text = p.text.trim();
    if (text.isEmpty) {
      return Left(ValidationFailure('Pesan tidak boleh kosong'));
    }
    if (text.length > CommunityPolicy.maxMessageLength) {
      return Left(
        ValidationFailure('Pesan maksimal ${CommunityPolicy.maxMessageLength} karakter'),
      );
    }

    final statusResult = await _repository.getStatus(p.userId);
    final status = statusResult.getOrElse(() => const ModerationStatus());
    if (status.isBanned()) {
      return Left(BannedFailure(status, 'Akunmu sedang dibanned dari Komunitas'));
    }

    final violation = ContentModerator.check(text);
    if (violation != null) {
      final recorded = await _repository.recordViolation(
        p.userId,
        userName: p.userName,
        type: violation,
        excerpt: text,
      );
      final newStatus = recorded.getOrElse(() => status);
      return Left(
        ViolationFailure(violation, newStatus, 'Pesan mengandung ${violation.label}'),
      );
    }

    return _repository.postMessage(
      userId: p.userId,
      userName: p.userName,
      avatarAsset: p.avatarAsset,
      text: text,
    );
  }
}

class SendMessageParams extends Equatable {
  const SendMessageParams({
    required this.userId,
    required this.userName,
    required this.text,
    this.avatarAsset,
  });

  final String userId;
  final String userName;
  final String text;
  final String? avatarAsset;

  @override
  List<Object?> get props => [userId, userName, text, avatarAsset];
}

class ToggleReaction implements UseCase<ChatMessage, ToggleReactionParams> {
  const ToggleReaction(this._repository);

  final CommunityRepository _repository;

  @override
  Future<Either<Failure, ChatMessage>> call(ToggleReactionParams p) =>
      _repository.toggleReaction(
        messageId: p.messageId,
        emoji: p.emoji,
        userId: p.userId,
      );
}

class ToggleReactionParams extends Equatable {
  const ToggleReactionParams({
    required this.messageId,
    required this.emoji,
    required this.userId,
  });

  final String messageId;
  final String emoji;
  final String userId;

  @override
  List<Object?> get props => [messageId, emoji, userId];
}

class ReportMessage implements UseCase<Unit, ReportParams> {
  const ReportMessage(this._repository);

  final CommunityRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ReportParams p) =>
      _repository.reportMessage(messageId: p.messageId, reporterId: p.reporterId);
}

class ReportParams extends Equatable {
  const ReportParams({required this.messageId, required this.reporterId});

  final String messageId;
  final String reporterId;

  @override
  List<Object?> get props => [messageId, reporterId];
}