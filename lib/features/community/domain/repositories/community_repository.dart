import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/community/domain/entities/chat_message.dart';
import 'package:sadaqo/features/community/domain/entities/moderation.dart';

abstract class CommunityRepository {
  Future<Either<Failure, List<ChatMessage>>> getMessages();

  Future<Either<Failure, ChatMessage>> postMessage({
    required String userId,
    required String userName,
    String? avatarAsset,
    required String text,
  });

  Future<Either<Failure, ChatMessage>> toggleReaction({
    required String messageId,
    required String emoji,
    required String userId,
  });

  Future<Either<Failure, Unit>> reportMessage({
    required String messageId,
    required String reporterId,
  });

  Future<Either<Failure, ModerationStatus>> getStatus(String userId);

  /// Mencatat pelanggaran; mengembalikan status terbaru (peringatan atau banned).
  Future<Either<Failure, ModerationStatus>> recordViolation(String userId);
}