import 'package:get_it/get_it.dart';
import 'package:sadaqo/admin/data/admin_verification_store.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/report/domain/repositories/report_repository.dart';
import 'package:sadaqo/pengelola/data/pengelola_store.dart';

/// Dipanggil SEKALI dari injection_container.dart.
void registerPengelolaDependencies(GetIt sl) {
  sl.registerLazySingleton<PengelolaStore>(
    () => PengelolaStore(
      sl<MockCampaignStore>(),
      sl<ReportRepository>(),
      sl<AdminVerificationStore>(),
    ),
  );
}