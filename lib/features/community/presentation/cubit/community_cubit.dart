import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/community/domain/entities/chat_message.dart';
import 'package:sadaqo/features/community/domain/entities/moderation.dart';
import 'package:sadaqo/features/community/domain/usecases/community_usecases.dart';

/// Peristiwa pelanggaran (untuk dialog dan notifikasi).
class CommunityNotice extends Equatable {
  const CommunityNotice({required this.type, required this.status});

  final ViolationType type;
  final ModerationStatus status;

  bool get isBan => status.isBanned();

  @override
  List<Object?> get props => [type, status];
}

class CommunityState extends Equatable {
  const CommunityState({
    this.messages = const <ChatMessage>[],
    this.status = const ModerationStatus(),
    this.loading = false,
    this.sending = false,
    this.notice,
    this.errorMessage,
    this.eventId = 0,
  });

  final List<ChatMessage> messages;
  final ModerationStatus status;
  final bool loading;
  final bool sending;

  /// Peristiwa sekali pakai: hanya ada pada emisi yang menaikkan [eventId].
  final CommunityNotice? notice;
  final String? errorMessage;
  final int eventId;

  CommunityState copyWith({
    List<ChatMessage>? messages,
    ModerationStatus? status,
    bool? loading,
    bool? sending,
    CommunityNotice? notice,
    String? errorMessage,
    int? eventId,
  }) {
    return CommunityState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      notice: notice, // sengaja tidak dipertahankan
      errorMessage: errorMessage, // sengaja tidak dipertahankan
      eventId: eventId ?? this.eventId,
    );
  }

  @override
  List<Object?> get props =>
      [messages, status, loading, sending, notice, errorMessage, eventId];
}

class CommunityCubit extends Cubit<CommunityState> {
  CommunityCubit({
    required GetMessages getMessages,
    required GetModerationStatus getStatus,
    required SendMessage sendMessage,
    required ToggleReaction toggleReaction,
    required ReportMessage reportMessage,
  })  : _getMessages = getMessages,
        _getStatus = getStatus,
        _send = sendMessage,
        _toggle = toggleReaction,
        _report = reportMessage,
        super(const CommunityState());

  final GetMessages _getMessages;
  final GetModerationStatus _getStatus;
  final SendMessage _send;
  final ToggleReaction _toggle;
  final ReportMessage _report;

  Future<void> load(String userId) async {
    emit(state.copyWith(loading: true));
    final messages = await _getMessages(const NoParams());
    final status = await _getStatus(userId);
    emit(
      state.copyWith(
        loading: false,
        messages: messages.getOrElse(() => const <ChatMessage>[]),
        status: status.getOrElse(() => const ModerationStatus()),
      ),
    );
  }

  /// true = pesan terkirim. false = ditolak (kosong, pelanggaran, atau banned).
  Future<bool> send({
    required String userId,
    required String userName,
    String? avatarAsset,
    required String text,
  }) async {
    emit(state.copyWith(sending: true));
    final result = await _send(
      SendMessageParams(
        userId: userId,
        userName: userName,
        avatarAsset: avatarAsset,
        text: text,
      ),
    );

    final Failure? failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure == null) {
      final messages = await _getMessages(const NoParams());
      emit(
        state.copyWith(
          sending: false,
          messages: messages.getOrElse(() => state.messages),
        ),
      );
      return true;
    }

    if (failure is ViolationFailure) {
      emit(
        state.copyWith(
          sending: false,
          status: failure.status,
          notice: CommunityNotice(type: failure.type, status: failure.status),
          eventId: state.eventId + 1,
        ),
      );
    } else if (failure is BannedFailure) {
      emit(state.copyWith(sending: false, status: failure.status));
    } else {
      emit(
        state.copyWith(
          sending: false,
          errorMessage: failure.message,
          eventId: state.eventId + 1,
        ),
      );
    }
    return false;
  }

  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final result = await _toggle(
      ToggleReactionParams(messageId: messageId, emoji: emoji, userId: userId),
    );
    result.fold((_) {}, (updated) {
      emit(
        state.copyWith(
          messages: [for (final m in state.messages) m.id == updated.id ? updated : m],
        ),
      );
    });
  }

  Future<bool> report({required String messageId, required String userId}) async {
    final result = await _report(ReportParams(messageId: messageId, reporterId: userId));
    return result.isRight();
  }
}