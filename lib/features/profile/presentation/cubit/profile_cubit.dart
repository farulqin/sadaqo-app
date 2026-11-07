import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/profile/domain/entities/profile_photo.dart';
import 'package:sadaqo/features/profile/domain/usecases/get_profile_photo.dart';
import 'package:sadaqo/features/profile/domain/usecases/save_profile_photo.dart';

class ProfileState extends Equatable {
  const ProfileState({this.photo});

  final ProfilePhoto? photo;

  @override
  List<Object?> get props => [photo];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required GetProfilePhoto getPhoto,
    required SaveProfilePhoto savePhoto,
  })  : _getPhoto = getPhoto,
        _savePhoto = savePhoto,
        super(const ProfileState());

  final GetProfilePhoto _getPhoto;
  final SaveProfilePhoto _savePhoto;

  Future<void> load() async {
    final result = await _getPhoto(const NoParams());
    result.fold((_) {}, (photo) => emit(ProfileState(photo: photo)));
  }

  Future<void> setAvatar(String asset) => _persist(ProfilePhoto.avatar(asset));

  Future<void> setGalleryPhoto(Uint8List bytes) =>
      _persist(ProfilePhoto.gallery(bytes));

  Future<void> removePhoto() => _persist(null);

  Future<void> _persist(ProfilePhoto? photo) async {
    final result = await _savePhoto(SavePhotoParams(photo));
    result.fold((_) {}, (_) => emit(ProfileState(photo: photo)));
  }
}