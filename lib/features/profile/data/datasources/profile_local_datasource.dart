import 'package:sadaqo/features/profile/domain/entities/profile_photo.dart';

abstract class ProfileLocalDataSource {
  Future<ProfilePhoto?> getPhoto();
  Future<void> savePhoto(ProfilePhoto? photo);
}

/// Penyimpanan di memori selama backend belum siap: foto hilang saat aplikasi
/// ditutup. Nanti diganti dengan upload foto ke server (Laravel storage).
class ProfileMemoryDataSource implements ProfileLocalDataSource {
  ProfilePhoto? _photo;

  @override
  Future<ProfilePhoto?> getPhoto() async => _photo;

  @override
  Future<void> savePhoto(ProfilePhoto? photo) async {
    _photo = photo;
  }
}