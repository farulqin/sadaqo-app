import 'package:get_it/get_it.dart';
import 'package:sadaqo/admin/data/admin_activity_log.dart';
import 'package:sadaqo/admin/data/admin_analytics_store.dart';
import 'package:sadaqo/admin/data/admin_credentials_store.dart';
import 'package:sadaqo/admin/data/admin_user_store.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/admin/data/admin_community_store.dart';
import 'package:dio/dio.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_manage_api.dart';
import 'package:sadaqo/admin/data/admin_program_store.dart';
import 'package:sadaqo/admin/data/admin_news_store.dart';
import 'package:sadaqo/admin/data/admin_user_api.dart';

/// Semua dependency dashboard admin didaftarkan di sini (dipanggil SEKALI dari
/// injection_container.dart). Semuanya lazy, jadi tidak membebani aplikasi pengguna.
/// Admin memakai data sumber yang SAMA dengan aplikasi pengguna
/// (MockCampaignStore, data Komunitas, data Berita), sehingga perubahan dari
/// admin langsung terlihat di aplikasi.
void registerAdminDependencies(GetIt sl) {
  sl.registerLazySingleton<AdminCredentialsStore>(() => AdminCredentialsStore());
  sl.registerLazySingleton<AdminUserApi>(() => AdminUserApi(sl<Dio>()));
  sl.registerLazySingleton<AdminUserStore>(
    () => AdminUserStore(sl<AdminUserApi>(), sl<CampaignManageApi>()),
  );
  sl.registerLazySingleton<AdminActivityLog>(() => AdminActivityLog());
  sl.registerLazySingleton<AdminAnalyticsStore>(
    () => AdminAnalyticsStore(sl<CampaignManageApi>()),
  );
    sl.registerLazySingleton<CampaignManageApi>(
    () => CampaignManageApi(sl<Dio>()),
  );
  sl.registerLazySingleton<AdminProgramStore>(
    () => AdminProgramStore(sl<CampaignManageApi>()),
  );
  sl.registerLazySingleton<AdminVerificationStore>(
    () => AdminVerificationStore(sl<CampaignManageApi>()),
  );

  // Moderasi Komunitas: laporan diambil dari API.
  sl.registerLazySingleton<AdminCommunityStore>(() => AdminCommunityStore(sl<Dio>()));

  // Berita untuk halaman admin: data sudah disambungkan ke API.
  // Perubahan admin belum tampil di aplikasi donatur sampai disambungkan ke Dio.
    sl.registerLazySingleton<AdminNewsStore>(
    () => AdminNewsStore(sl<CampaignManageApi>()),
  );
}
