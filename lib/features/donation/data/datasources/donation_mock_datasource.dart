import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/donation/data/datasources/donation_remote_datasource.dart';
import 'package:sadaqo/features/donation/data/models/donation_model.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';

/// Penyimpanan di memori: donasi baru langsung muncul di riwayat,
/// tapi hilang saat aplikasi ditutup. Pembayaran hanya simulasi.
class DonationMockDataSource implements DonationRemoteDataSource {
  final List<DonationModel> _items = [
    DonationModel(
      id: 'd1',
      campaignId: 'c1',
      campaignTitle: 'Pembangunan Masjid Al-Falah',
      category: ProgramCategory.masjid,
      amount: 50000,
      paymentMethod: PaymentMethod.ewallet,
      status: DonationStatus.success,
      createdAt: DateTime(2025, 10, 20),
    ),
    DonationModel(
      id: 'd2',
      campaignId: 'c4',
      campaignTitle: 'Qurban Bersama 1447 H',
      category: ProgramCategory.qurban,
      amount: 1500000,
      paymentMethod: PaymentMethod.transfer,
      status: DonationStatus.success,
      createdAt: DateTime(2025, 6, 12),
    ),
    DonationModel(
      id: 'd3',
      campaignId: 'c2',
      campaignTitle: 'Paket Sembako untuk Fakir Miskin',
      category: ProgramCategory.sosial,
      amount: 100000,
      paymentMethod: PaymentMethod.ewallet,
      status: DonationStatus.success,
      createdAt: DateTime(2025, 4, 5),
    ),
  ];

  @override
  Future<List<DonationModel>> getHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.of(_items); // terbaru di indeks 0
  }

  @override
  Future<DonationModel> createDonation({
    required String campaignId,
    required String campaignTitle,
    required ProgramCategory category,
    required int amount,
    required PaymentMethod paymentMethod,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final donation = DonationModel(
      id: 'd${_items.length + 1}',
      campaignId: campaignId,
      campaignTitle: campaignTitle,
      category: category,
      amount: amount,
      paymentMethod: paymentMethod,
      status: DonationStatus.success,
      createdAt: DateTime.now(),
    );
    _items.insert(0, donation);
    return donation;
  }
}
