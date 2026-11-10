import 'package:get_it/get_it.dart';
import 'package:sadaqo/admin/data/admin_activity_log.dart';
import 'package:sadaqo/admin/data/admin_analytics_store.dart';
import 'package:sadaqo/admin/data/admin_credentials_store.dart';
import 'package:sadaqo/admin/data/admin_user_store.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/community/data/datasources/community_admin_datasource.dart';
import 'package:sadaqo/features/community/data/datasources/community_local_datasource.dart';
import 'package:sadaqo/features/donation/data/datasources/donation_remote_datasource.dart';
import 'package:sadaqo/features/news/data/datasources/news_mock_datasource.dart';
import 'package:sadaqo/features/news/data/datasources/news_remote_datasource.dart';

/// Semua dependency dashboard admin didaftarkan di sini (dipanggil SEKALI dari
/// injection_container.dart). Semuanya lazy, jadi tidak membebani aplikasi pengguna.
///
/// Admin memakai data sumber yang SAMA dengan aplikasi pengguna
/// (MockCampaignStore, data Komunitas, data Berita), sehingga perubahan dari
/// admin langsung terlihat di aplikasi.
void registerAdminDependencies(GetIt sl) {
  sl.registerLazySingleton<AdminCredentialsStore>(() => AdminCredentialsStore());
  sl.registerLazySingleton<AdminUserStore>(() => AdminUserStore());
  sl.registerLazySingleton<AdminActivityLog>(() => AdminActivityLog());
  sl.registerLazySingleton<AdminAnalyticsStore>(
    () => AdminAnalyticsStore(sl<MockCampaignStore>(), sl<DonationRemoteDataSource>()),
  );
  sl.registerLazySingleton<AdminVerificationStore>(
    () => AdminVerificationStore(sl<MockCampaignStore>()),
  );

  // Komunitas: sumber data yang sama dengan aplikasi, dilihat dari sisi admin.
  sl.registerLazySingleton<CommunityAdminDataSource>(
    () => sl<CommunityLocalDataSource>() as CommunityAdminDataSource,
  );

  // Berita: sumber data contoh yang bisa diubah admin.
  // Saat memakai API sungguhan, ganti dengan repository admin berbasis Dio.
  sl.registerLazySingleton<NewsMockDataSource>(
    () => sl<NewsRemoteDataSource>() as NewsMockDataSource,
  );
}
