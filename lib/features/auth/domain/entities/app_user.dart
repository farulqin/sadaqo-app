import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  String get firstName => name.split(' ').first;
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  @override
  List<Object?> get props => [id, name, email];
}
