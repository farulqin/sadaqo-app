import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type = 'system',
    this.refType,
    this.refId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  /// activity (interaksi: komentar, apresiasi, agenda) atau system (pengumuman, program, laporan).
  final String type;

  /// Tujuan saat ditekan: post atau event (kosong = tidak membuka apa pun).
  final String? refType;
  final String? refId;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        type: type,
        refType: refType,
        refId: refId,
      );

  @override
  List<Object?> get props => [id, title, body, createdAt, isRead, type, refType, refId];
}