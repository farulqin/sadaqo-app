import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/features/donation/domain/usecases/create_donation.dart';
import 'package:sadaqo/features/donation/presentation/cubit/donation_form_state.dart';

class DonationFormCubit extends Cubit<DonationFormState> {
  DonationFormCubit(this._createDonation) : super(const DonationFormInitial());

  final CreateDonation _createDonation;

  Future<void> submit(CreateDonationParams params) async {
    emit(const DonationFormSubmitting());
    final result = await _createDonation(params);
    result.fold(
      (failure) => emit(DonationFormError(failure.message)),
      (donation) => emit(DonationFormSuccess(donation)),
    );
  }

  void reset() => emit(const DonationFormInitial());
}
