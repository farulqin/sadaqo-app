import 'package:equatable/equatable.dart';
import 'package:sadaqo/features/auth/domain/entities/gender.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.gender,
    this.isAdmin = false,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final Gender? gender;

  /// true jika akun ini adalah admin (email terdaftar di AdminConfig).
  final bool isAdmin;

  String get firstName => name.split(' ').first;
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  AppUser copyWith({String? name, String? phone, Gender? gender}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        gender: gender ?? this.gender,
        isAdmin: isAdmin,
      );

  @override
  List<Object?> get props => [id, name, email, phone, gender, isAdmin];
}