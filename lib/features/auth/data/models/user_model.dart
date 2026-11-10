import 'package:sadaqo/features/auth/domain/entities/app_user.dart';
import 'package:sadaqo/features/auth/domain/entities/gender.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.gender,
    super.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      gender: Gender.fromKey(json['gender'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender?.key,
      };
}