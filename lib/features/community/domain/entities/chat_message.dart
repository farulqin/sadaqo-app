import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.avatarAsset,
    this.reactions = const <String, Set<String>>{},
  });

  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;
  final String? avatarAsset;

  /// emote -> kumpulan id pengguna yang memberi reaksi.
  final Map<String, Set<String>> reactions;

  ChatMessage copyWith({Map<String, Set<String>>? reactions}) => ChatMessage(
        id: id,
        userId: userId,
        userName: userName,
        text: text,
        createdAt: createdAt,
        avatarAsset: avatarAsset,
        reactions: reactions ?? this.reactions,
      );

  @override
  List<Object?> get props =>
      [id, userId, userName, text, createdAt, avatarAsset, reactions];
}