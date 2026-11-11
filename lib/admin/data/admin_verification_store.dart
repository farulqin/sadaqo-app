import 'package:flutter/foundation.dart';
import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';

enum SubmissionStatus { pending, approved, rejected }

/// Pengajuan kampanye/program yang menunggu verifikasi admin
/// (dari pihak luar atau dari Pengelola Kampanye).
class CampaignSubmission {
  const CampaignSubmission({
    required this.id,
    required this.title,
    required this.category,
    required this.organizer,
    required this.location,
    required this.description,
    required this.targetAmount,
    required this.durationDays,
    required this.submittedAt,
    this.imageAsset,
    this.imageBytes,
    this.subType,
    this.supportingInfo,
    this.ownerId,
    this.campaignId,
    this.status = SubmissionStatus.pending,
    this.note,
  });

  final String id;
  final String title;
  final ProgramCategory category;
  final String organizer;
  final String location;
  final String description;
  final int targetAmount;
  final int durationDays;
  final DateTime submittedAt;
  final String? imageAsset;

  /// Foto sampul dari galeri pengelola (hanya untuk pratinjau verifikasi).
  final Uint8List? imageBytes;
  final String? subType;

  /// Penanggung jawab, kontak, dan dokumen pendukung dari pengelola.
  final String? supportingInfo;

  /// Id akun pengelola yang mengajukan (null = pihak luar).
  final String? ownerId;

  /// Id program yang terbentuk setelah pengajuan disetujui.
  final String? campaignId;
  final SubmissionStatus status;
  final String? note;

  CampaignSubmission copyWith({
    SubmissionStatus? status,
    String? note,
    String? campaignId,
  }) =>
      CampaignSubmission(
        id: id,
        title: title,
        category: category,
        organizer: organizer,
        location: location,
        description: description,
        targetAmount: targetAmount,
        durationDays: durationDays,
        submittedAt: submittedAt,
        imageAsset: imageAsset,
        imageBytes: imageBytes,
        subType: subType,
        supportingInfo: supportingInfo,
        ownerId: ownerId,
        campaignId: campaignId ?? this.campaignId,
        status: status ?? this.status,
        note: note ?? this.note,
      );
}

/// Antrean verifikasi kampanye (di memori; isi awal adalah contoh fiktif).
/// Menyetujui pengajuan langsung menambahkan program ke aplikasi pengguna.
class AdminVerificationStore extends ChangeNotifier {
  AdminVerificationStore(this._campaigns) : _items = _seed();

  final MockCampaignStore _campaigns;
  List<CampaignSubmission> _items;

  List<CampaignSubmission> get all => List.unmodifiable(_items);
  int get pendingCount =>
      _items.where((s) => s.status == SubmissionStatus.pending).length;

  String nextId() => 'v${_items.length + 1}';

  /// Pengajuan baru dari pengelola.
  void submit(CampaignSubmission s) {
    _items = [s, ..._items];
    notifyListeners();
  }

  /// Pengelola memperbaiki pengajuan yang dikembalikan admin, lalu antre ulang.
  void resubmit(CampaignSubmission s) {
    _items = [s, ..._items.where((x) => x.id != s.id)];
    notifyListeners();
  }

  /// Mengembalikan id program baru yang dibuat.
  String approve(String id) {
    final i = _items.indexWhere((s) => s.id == id);
    final s = _items[i];
    final newId = _campaigns.adminNextId(s.category);
    _campaigns.adminSave(
      CampaignModel(
        id: newId,
        title: s.title,
        description: s.description,
        category: s.category,
        targetAmount: s.targetAmount,
        collectedAmount: 0,
        deadline: DateTime.now().add(Duration(days: s.durationDays)),
        location: s.location,
        imageAsset: s.imageAsset ?? _defaultCover(s.category),
        subType: s.subType,
      ),
    );
    _items = List.of(_items)
      ..[i] = s.copyWith(
        status: SubmissionStatus.approved,
        note: 'Disetujui, program $newId aktif',
        campaignId: newId,
      );
    notifyListeners();
    return newId;
  }

  void reject(String id, String reason) {
    final i = _items.indexWhere((s) => s.id == id);
    _items = List.of(_items)
      ..[i] = _items[i].copyWith(status: SubmissionStatus.rejected, note: reason);
    notifyListeners();
  }

  /// Gambar bawaan sementara untuk pengajuan yang fotonya dari galeri
  /// (sampai ada upload ke backend).
  static String? _defaultCover(ProgramCategory c) {
    switch (c) {
      case ProgramCategory.masjid:
        return AppAssets.masjid('masjid_al_azzam.jpg');
      case ProgramCategory.sosial:
        return AppAssets.sosial('banjir.jpg');
      case ProgramCategory.duafa:
        return AppAssets.duafa('panti_asuhan.jpg');
      case ProgramCategory.qurban:
        return AppAssets.qurban('kambing.jpg');
      case ProgramCategory.zakat:
        return null;
    }
  }

  static List<CampaignSubmission> _seed() {
    final now = DateTime.now();
    return [
      CampaignSubmission(
        id: 'v1',
        title: 'Bantuan Air Bersih Desa Sukamaju',
        category: ProgramCategory.sosial,
        organizer: 'Karang Taruna Sukamaju',
        location: 'Cianjur, Jawa Barat',
        description:
            'Pengadaan sumur bor dan tandon air bersih bagi 120 keluarga yang selama musim kemarau harus berjalan jauh mengambil air.',
        targetAmount: 85000000,
        durationDays: 45,
        submittedAt: now.subtract(const Duration(hours: 2)),
        imageAsset: AppAssets.sosial('banjir.jpg'),
        subType: 'Banjir',
      ),
      CampaignSubmission(
        id: 'v2',
        title: 'Renovasi Mushola Al-Hikmah',
        category: ProgramCategory.masjid,
        organizer: 'Takmir Mushola Al-Hikmah',
        location: 'Kediri, Jawa Timur',
        description:
            'Perbaikan atap bocor, penggantian lantai, dan penambahan tempat wudhu untuk jamaah lingkungan RW 05.',
        targetAmount: 38000000,
        durationDays: 30,
        submittedAt: now.subtract(const Duration(hours: 9)),
        imageAsset: AppAssets.masjid('mushola_al_ihsan.jpg'),
        subType: 'Mushola',
      ),
      CampaignSubmission(
        id: 'v3',
        title: 'Santunan Anak Yatim Panti Al-Amin',
        category: ProgramCategory.duafa,
        organizer: 'Yayasan Al-Amin',
        location: 'Bekasi, Jawa Barat',
        description:
            'Biaya sekolah, seragam, dan kebutuhan gizi untuk 35 anak yatim dan dhuafa selama satu tahun ajaran.',
        targetAmount: 52000000,
        durationDays: 40,
        submittedAt: now.subtract(const Duration(days: 1, hours: 3)),
        imageAsset: AppAssets.duafa('panti_asuhan.jpg'),
        subType: 'Panti Asuhan',
      ),
      CampaignSubmission(
        id: 'v4',
        title: 'Qurban Kambing Desa Binaan',
        category: ProgramCategory.qurban,
        organizer: 'Komunitas Peduli Desa',
        location: 'Wonosobo, Jawa Tengah',
        description:
            'Pengadaan kambing qurban untuk dibagikan kepada warga desa binaan yang jarang menerima daging qurban.',
        targetAmount: 45000000,
        durationDays: 120,
        submittedAt: now.subtract(const Duration(days: 2)),
        imageAsset: AppAssets.qurban('kambing.jpg'),
        subType: 'Bersama',
      ),
    ];
  }
}
