import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/donation/data/datasources/donation_remote_datasource.dart';
import 'package:sadaqo/features/donation/data/models/donation_model.dart';
import 'package:sadaqo/features/donation/domain/entities/donation.dart';

/// Penyimpanan di memori: donasi baru langsung muncul di riwayat dan mengubah
/// progres dana serta kuota slot. Hilang saat aplikasi ditutup. Pembayaran simulasi.
class DonationMockDataSource implements DonationRemoteDataSource {
  DonationMockDataSource(this._campaigns);

  final MockCampaignStore _campaigns;

  final List<DonationModel> _items = [
    DonationModel(
      id: 'd1',
      campaignId: 'z2',
      campaignTitle: 'Zakat Maal (Uang)',
      category: ProgramCategory.zakat,
      amount: 1500000,
      paymentMethod: PaymentMethod.transfer,
      status: DonationStatus.success,
      createdAt: DateTime(2026, 3, 14),
    ),
    DonationModel(
      id: 'd2',
      campaignId: 's1',
      campaignTitle: 'Bantuan Korban Banjir',
      category: ProgramCategory.sosial,
      amount: 100000,
      paymentMethod: PaymentMethod.ewallet,
      status: DonationStatus.success,
      createdAt: DateTime(2026, 1, 5),
    ),
    DonationModel(
      id: 'd3',
      campaignId: 'm1',
      campaignTitle: 'Pembangunan Masjid Al-Azzam',
      category: ProgramCategory.masjid,
      amount: 50000,
      paymentMethod: PaymentMethod.ewallet,
      status: DonationStatus.success,
      createdAt: DateTime(2025, 10, 20),
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
    String? paymentProvider,
    required String donorName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // Cek kuota slot (qurban kolektif) sebelum menerima donasi.
    final campaign = _campaigns.byId(campaignId);
    if (campaign != null && campaign.isSlotBased) {
      final units = amount ~/ (campaign.unitPrice ?? 1);
      if (campaign.isFull || units > campaign.slotsLeft) {
        throw const ServerException('Sisa kuota tidak mencukupi');
      }
    }

    final donation = DonationModel(
      id: 'd${_items.length + 1}',
      campaignId: campaignId,
      campaignTitle: campaignTitle,
      category: category,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentProvider: paymentProvider,
      status: DonationStatus.success,
      createdAt: DateTime.now(),
      donorName: donorName,
    );
    _items.insert(0, donation);
    _campaigns.applyDonation(campaignId: campaignId, amount: amount);
    return donation;
  }
}