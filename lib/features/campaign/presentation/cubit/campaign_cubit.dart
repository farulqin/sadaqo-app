import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/campaign/domain/usecases/get_campaigns.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';

class CampaignCubit extends Cubit<CampaignState> {
  CampaignCubit(this._getCampaigns) : super(const CampaignInitial());

  final GetCampaigns _getCampaigns;

  /// Muat dengan indikator loading (pertama kali / coba lagi).
  Future<void> load() async {
    emit(const CampaignLoading());
    await refresh();
  }

  /// Muat ulang tanpa loading, mis. setelah donasi agar progres dana ikut berubah.
  Future<void> refresh() async {
    final result = await _getCampaigns(const NoParams());
    result.fold(
      (failure) => emit(CampaignError(failure.message)),
      (campaigns) => emit(CampaignLoaded(campaigns)),
    );
  }
}
