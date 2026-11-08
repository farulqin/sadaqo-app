import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.notificationsEnabled = true,
    this.hideNameByDefault = false,
  });

  /// Catat notifikasi di aplikasi (ucapan, konfirmasi donasi, info akun).
  final bool notificationsEnabled;

  /// Donasi baru otomatis atas nama "Hamba Allah".
  final bool hideNameByDefault;

  SettingsState copyWith({bool? notificationsEnabled, bool? hideNameByDefault}) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hideNameByDefault: hideNameByDefault ?? this.hideNameByDefault,
    );
  }

  @override
  List<Object?> get props => [notificationsEnabled, hideNameByDefault];
}

/// Pengaturan aplikasi. Disimpan di memori selama backend/penyimpanan lokal
/// belum dipasang (nanti dipindah ke shared_preferences atau akun pengguna).
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void setNotifications(bool value) => emit(state.copyWith(notificationsEnabled: value));

  void setHideNameByDefault(bool value) => emit(state.copyWith(hideNameByDefault: value));
}