import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sadaqo/core/network/dio_client.dart';
import 'package:sadaqo/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:sadaqo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sadaqo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sadaqo/features/auth/domain/repositories/auth_repository.dart';
import 'package:sadaqo/features/auth/domain/usecases/login_user.dart';
import 'package:sadaqo/features/auth/domain/usecases/logout_user.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_mock_datasource.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_remote_datasource.dart';
import 'package:sadaqo/features/campaign/data/repositories/campaign_repository_impl.dart';
import 'package:sadaqo/features/campaign/domain/repositories/campaign_repository.dart';
import 'package:sadaqo/features/campaign/domain/usecases/get_campaigns.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/donation/data/datasources/donation_mock_datasource.dart';
import 'package:sadaqo/features/donation/data/datasources/donation_remote_datasource.dart';
import 'package:sadaqo/features/donation/data/repositories/donation_repository_impl.dart';
import 'package:sadaqo/features/donation/domain/repositories/donation_repository.dart';
import 'package:sadaqo/features/donation/domain/usecases/create_donation.dart';
import 'package:sadaqo/features/donation/domain/usecases/get_donation_history.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_form_cubit.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_cubit.dart';
import 'package:sadaqo/features/news/data/datasources/news_mock_datasource.dart';
import 'package:sadaqo/features/news/data/datasources/news_remote_datasource.dart';
import 'package:sadaqo/features/news/data/repositories/news_repository_impl.dart';
import 'package:sadaqo/features/news/domain/repositories/news_repository.dart';
import 'package:sadaqo/features/news/domain/usecases/get_news.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_cubit.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:sadaqo/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:sadaqo/features/profile/domain/repositories/profile_repository.dart';
import 'package:sadaqo/features/profile/domain/usecases/get_profile_photo.dart';
import 'package:sadaqo/features/profile/domain/usecases/save_profile_photo.dart';
import 'package:sadaqo/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:sadaqo/features/auth/domain/usecases/login_with_provider.dart';
import 'package:sadaqo/features/auth/domain/usecases/register_user.dart';
import 'package:sadaqo/features/favorite/data/datasources/favorite_local_datasource.dart';
import 'package:sadaqo/features/favorite/data/repositories/favorite_repository_impl.dart';
import 'package:sadaqo/features/favorite/domain/repositories/favorite_repository.dart';
import 'package:sadaqo/features/favorite/domain/usecases/favorite_usecases.dart';
import 'package:sadaqo/features/favorite/presentation/cubit/favorite_cubit.dart';
import 'package:sadaqo/features/notification/data/datasources/notification_local_datasource.dart';
import 'package:sadaqo/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:sadaqo/features/notification/domain/repositories/notification_repository.dart';
import 'package:sadaqo/features/notification/domain/usecases/notification_usecases.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:sadaqo/admin/admin.dart';
import 'package:sadaqo/admin/data/admin_credentials_store.dart';
import 'package:sadaqo/admin/data/admin_user_store.dart';
import 'package:sadaqo/core/navigation/main_tab_controller.dart';
import 'package:sadaqo/features/auth/domain/usecases/update_profile.dart';
import 'package:sadaqo/features/profile/presentation/cubit/settings_cubit.dart';
import 'package:sadaqo/features/community/data/datasources/community_local_datasource.dart';
import 'package:sadaqo/features/community/data/repositories/community_repository_impl.dart';
import 'package:sadaqo/features/community/domain/repositories/community_repository.dart';
import 'package:sadaqo/features/community/domain/usecases/community_usecases.dart';
import 'package:sadaqo/features/community/presentation/cubit/community_cubit.dart';
import 'package:sadaqo/features/report/data/repositories/report_repository_impl.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';
import 'package:sadaqo/pengelola/pengelola.dart';
import 'package:sadaqo/pengelola/data/pengelola_account_store.dart';

// Service locator: semua dependency didaftarkan di sini.
// Urutan per fitur: datasource -> repository -> usecase -> cubit.
final sl = GetIt.instance;

Future<void> init() async {
  // ===== Core =====
  sl.registerLazySingleton<Dio>(() => DioClient.create());

  // ===== Admin (semua kode admin ada di lib/admin/) =====
  registerAdminDependencies(sl);

  // ===== Laporan & dokumentasi penyaluran (dipakai pengelola, admin, donatur) =====
  sl.registerLazySingleton<ReportRepository>(() => ReportRepositoryImpl());

  // ===== Pengelola Kampanye (semua kode ada di lib/pengelola/) =====
  registerPengelolaDependencies(sl);

  // ===== Auth =====
  // Saat backend Laravel siap, ganti AuthMockDataSource dengan
  // implementasi Dio (AuthRemoteDataSourceImpl(sl())). Layer lain tidak berubah.
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthMockDataSource(
      adminGate: sl<AdminCredentialsStore>(),
      directory: sl<AdminUserStore>(),
      pengelolaGate: sl<PengelolaAccountStore>(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<LoginUser>(() => LoginUser(sl()));
  sl.registerLazySingleton<LogoutUser>(() => LogoutUser(sl()));
  sl.registerLazySingleton<RegisterUser>(() => RegisterUser(sl()));
  sl.registerLazySingleton<LoginWithProvider>(() => LoginWithProvider(sl()));
  sl.registerLazySingleton<UpdateProfile>(() => UpdateProfile(sl()));
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      loginUser: sl(),
      registerUser: sl(),
      loginWithProvider: sl(),
      updateProfile: sl(),
      logoutUser: sl(),
    ),
  );

  // ===== Campaign =====
  // Penyimpanan data contoh bersama (hapus saat API asli dipakai).
  sl.registerLazySingleton<MockCampaignStore>(() => MockCampaignStore());
  sl.registerLazySingleton<CampaignRemoteDataSource>(
    () => CampaignMockDataSource(sl()),
  );
  sl.registerLazySingleton<CampaignRepository>(
    () => CampaignRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<GetCampaigns>(() => GetCampaigns(sl()));
  sl.registerLazySingleton<CampaignCubit>(() => CampaignCubit(sl()));

  // ===== Donation =====
  sl.registerLazySingleton<DonationRemoteDataSource>(
    () => DonationMockDataSource(sl()),
  );
  sl.registerLazySingleton<DonationRepository>(
    () => DonationRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<GetDonationHistory>(() => GetDonationHistory(sl()));
  sl.registerLazySingleton<CreateDonation>(() => CreateDonation(sl()));
  sl.registerLazySingleton<DonationHistoryCubit>(
    () => DonationHistoryCubit(sl()),
  );
  // Form dibuat baru setiap halaman donasi dibuka.
  sl.registerFactory<DonationFormCubit>(() => DonationFormCubit(sl()));

  // ===== News =====
  sl.registerLazySingleton<NewsRemoteDataSource>(() => NewsMockDataSource());
  sl.registerLazySingleton<NewsRepository>(() => NewsRepositoryImpl(sl()));
  sl.registerLazySingleton<GetNews>(() => GetNews(sl()));
  sl.registerLazySingleton<NewsCubit>(() => NewsCubit(sl()));

  // ===== Profile (foto profil) =====
  sl.registerLazySingleton<ProfileLocalDataSource>(() => ProfileMemoryDataSource());
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));
  sl.registerLazySingleton<GetProfilePhoto>(() => GetProfilePhoto(sl()));
  sl.registerLazySingleton<SaveProfilePhoto>(() => SaveProfilePhoto(sl()));
  sl.registerLazySingleton<ProfileCubit>(
    () => ProfileCubit(getPhoto: sl(), savePhoto: sl()),
  );

    // ===== Notification =====
  sl.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationMemoryDataSource(),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<GetNotifications>(() => GetNotifications(sl()));
  sl.registerLazySingleton<AddNotification>(() => AddNotification(sl()));
  sl.registerLazySingleton<MarkAllNotificationsRead>(
    () => MarkAllNotificationsRead(sl()),
  );
  sl.registerLazySingleton<NotificationCubit>(
    () => NotificationCubit(
      getNotifications: sl(),
      addNotification: sl(),
      markAllRead: sl(),
      isEnabled: () => sl<SettingsCubit>().state.notificationsEnabled,
    ),
  );

  // ===== Favorite =====
  sl.registerLazySingleton<FavoriteLocalDataSource>(() => FavoriteMemoryDataSource());
  sl.registerLazySingleton<FavoriteRepository>(() => FavoriteRepositoryImpl(sl()));
  sl.registerLazySingleton<GetFavoriteIds>(() => GetFavoriteIds(sl()));
  sl.registerLazySingleton<ToggleFavorite>(() => ToggleFavorite(sl()));
  sl.registerLazySingleton<FavoriteCubit>(() => FavoriteCubit(getIds: sl(), toggleFavorite: sl()),);

  // ===== Pengaturan dan navigasi tab =====
  sl.registerLazySingleton<SettingsCubit>(() => SettingsCubit());
  sl.registerLazySingleton<MainTabController>(() => MainTabController());

  // ===== Community =====
  sl.registerLazySingleton<CommunityLocalDataSource>(() => CommunityMemoryDataSource());
  sl.registerLazySingleton<CommunityRepository>(() => CommunityRepositoryImpl(sl()));
  sl.registerLazySingleton<GetMessages>(() => GetMessages(sl()));
  sl.registerLazySingleton<GetModerationStatus>(() => GetModerationStatus(sl()));
  sl.registerLazySingleton<SendMessage>(() => SendMessage(sl()));
  sl.registerLazySingleton<ToggleReaction>(() => ToggleReaction(sl()));
  sl.registerLazySingleton<ReportMessage>(() => ReportMessage(sl()));
  sl.registerLazySingleton<CommunityCubit>(
    () => CommunityCubit(
      getMessages: sl(),
      getStatus: sl(),
      sendMessage: sl(),
      toggleReaction: sl(),
      reportMessage: sl(),
    ),
  );
}
