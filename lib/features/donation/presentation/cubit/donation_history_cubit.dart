import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/donation/domain/usecases/get_donation_history.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_history_state.dart';

class DonationHistoryCubit extends Cubit<DonationHistoryState> {
  DonationHistoryCubit(this._getHistory) : super(const DonationHistoryInitial());

  final GetDonationHistory _getHistory;

  /// Muat dengan indikator loading (pertama kali).
  Future<void> load() async {
    emit(const DonationHistoryLoading());
    await refresh();
  }

  /// Muat ulang tanpa memunculkan loading (setelah donasi baru, pull-to-refresh).
  Future<void> refresh() async {
    final result = await _getHistory(const NoParams());
    result.fold(
      (failure) => emit(DonationHistoryError(failure.message)),
      (items) => emit(DonationHistoryLoaded(items)),
    );
  }
}
