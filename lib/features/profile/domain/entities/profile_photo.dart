import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Foto profil: salah satu dari avatar bawaan atau foto dari galeri.
class ProfilePhoto extends Equatable {
  const ProfilePhoto._({this.avatarAsset, this.bytes});

  const ProfilePhoto.avatar(String asset) : this._(avatarAsset: asset);
  const ProfilePhoto.gallery(Uint8List data) : this._(bytes: data);

  final String? avatarAsset;
  final Uint8List? bytes;

  @override
  List<Object?> get props => [avatarAsset, bytes];
}