import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'core/network/dio_client.dart';

/// Service locator. Semua dependency didaftarkan di sini
/// agar tidak ada `new` tersebar di mana-mana.
final sl = GetIt.instance;

Future<void> init() async {
  // ===== Core =====
  sl.registerLazySingleton<Dio>(() => DioClient.create());

  // ===== Features =====
  // Daftar datasource -> repository -> usecase -> bloc
  // per fitur akan ditambahkan di sini (auth, campaign, donation, dst).
}
