import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/community/data/datasources/community_local_datasource.dart';
import 'package:sadaqo/features/community/domain/entities/chat_message.dart';
import 'package:sadaqo/features/community/domain/entities/moderation.dart';
import 'package:sadaqo/features/community/domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  const CommunityRepositoryImpl(this._local);

  final CommunityLocalDataSource _local;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages() =>
      _guard(() => _local.getMessages());

  @override
  Future<Either<Failure, ChatMessage>> postMessage({
    required String userId,
    required String userName,
    String? avatarAsset,
    required String text,
  }) =>
      _guard(
        () => _local.postMessage(
          userId: userId,
          userName: userName,
          avatarAsset: avatarAsset,
          text: text,
        ),
      );

  @override
  Future<Either<Failure, ChatMessage>> toggleReaction({
    required String messageId,
    required String emoji,
    required String userId,
  }) =>
      _guard(() => _local.toggleReaction(messageId, emoji, userId));

  @override
  Future<Either<Failure, Unit>> reportMessage({
    required String messageId,
    required String reporterId,
  }) =>
      _guard(() async {
        await _local.report(messageId, reporterId);
        return unit;
      });

  @override
  Future<Either<Failure, ModerationStatus>> getStatus(String userId) =>
      _guard(() => _local.getStatus(userId));

  @override
  Future<Either<Failure, ModerationStatus>> recordViolation(String userId) =>
      _guard(() => _local.recordViolation(userId));
}