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

/// Service locator: semua dependency didaftarkan di sini.
/// Urutan per fitur: datasource -> repository -> usecase -> cubit.
final sl = GetIt.instance;

Future<void> init() async {
  // ===== Core =====
  sl.registerLazySingleton<Dio>(() => DioClient.create());

  // ===== Auth =====
  // Saat backend Laravel siap, ganti AuthMockDataSource dengan
  // implementasi Dio (AuthRemoteDataSourceImpl(sl())). Layer lain tidak berubah.
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthMockDataSource());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<LoginUser>(() => LoginUser(sl()));
  sl.registerLazySingleton<LogoutUser>(() => LogoutUser(sl()));
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(loginUser: sl(), logoutUser: sl()),
  );

  // ===== Campaign =====
  sl.registerLazySingleton<CampaignRemoteDataSource>(
    () => CampaignMockDataSource(),
  );
  sl.registerLazySingleton<CampaignRepository>(
    () => CampaignRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<GetCampaigns>(() => GetCampaigns(sl()));
  sl.registerLazySingleton<CampaignCubit>(() => CampaignCubit(sl()));

  // ===== Donation =====
  sl.registerLazySingleton<DonationRemoteDataSource>(
    () => DonationMockDataSource(),
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
}
