import 'package:sadaqo/core/constants/app_assets.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';

/// Penyimpanan data contoh di memori, dipakai bersama oleh datasource campaign
/// dan donation agar donasi baru ikut mengubah progres dana dan kuota slot.
/// Semua nama, lokasi, dan angka bersifat contoh (fiktif). Hapus saat API asli dipakai.
class MockCampaignStore {
  MockCampaignStore() : _items = _seed();

  List<CampaignModel> _items;

  List<CampaignModel> get all => List.unmodifiable(_items);

  CampaignModel? byId(String id) {
    for (final c in _items) {
      if (c.id == id) return c;
    }
    return null;
  }

  void applyDonation({required String campaignId, required int amount}) {
    final i = _items.indexWhere((c) => c.id == campaignId);
    if (i < 0) return;
    final c = _items[i];
    final price = c.unitPrice;
    final units = price == null ? 0 : amount ~/ price;
    final updated = c.copyWith(
      collectedAmount: c.collectedAmount + amount,
      slotFilled: c.slotTotal == null ? null : (c.slotFilled ?? 0) + units,
    );
    _items = List.of(_items)..[i] = updated;
  }

  // ===== Dipakai dashboard admin (tambah, ubah, hapus program) =====
  void adminSave(CampaignModel campaign) {
    final i = _items.indexWhere((c) => c.id == campaign.id);
    _items = i < 0 ? [..._items, campaign] : (List.of(_items)..[i] = campaign);
  }

  void adminRemove(String id) {
    _items = _items.where((c) => c.id != id).toList();
  }

  /// Id baru berurutan per kategori, mis. m11, s6, q7.
  String adminNextId(ProgramCategory category) {
    final prefix = category.key.substring(0, 1);
    var max = 0;
    for (final c in _items) {
      if (c.id.startsWith(prefix)) {
        final n = int.tryParse(c.id.substring(1)) ?? 0;
        if (n > max) max = n;
      }
    }
    return '$prefix${max + 1}';
  }

  static CampaignModel _c(
    String id,
    ProgramCategory category,
    String title,
    String location,
    String image,
    int target,
    int collected,
    int days,
    String description, {
    String? sub,
    int? unitPrice,
    String? unitLabel,
    int? slotTotal,
    int? slotFilled,
  }) {
    return CampaignModel(
      id: id,
      title: title,
      description: description,
      category: category,
      targetAmount: target,
      collectedAmount: collected,
      deadline: DateTime.now().add(Duration(days: days)),
      location: location,
      imageAsset: image,
      subType: sub,
      unitPrice: unitPrice,
      unitLabel: unitLabel,
      slotTotal: slotTotal,
      slotFilled: slotFilled,
    );
  }

  static List<CampaignModel> _seed() {
    const masjid = ProgramCategory.masjid;
    const sosial = ProgramCategory.sosial;
    const zakat = ProgramCategory.zakat;
    const duafa = ProgramCategory.duafa;
    const qurban = ProgramCategory.qurban;

    return [
      // ===== MASJID (5) =====
      _c('m1', masjid, 'Pembangunan Masjid Al-Azzam', 'Surabaya, Jawa Timur',
          AppAssets.masjid('masjid_al_azzam.jpg'), 150000000, 112500000, 30,
          'Pembangunan ruang ibadah utama dan serambi agar jamaah dapat beribadah dengan nyaman, termasuk tempat wudhu dan fasilitas ramah lansia.',
          sub: 'Masjid'),
      _c('m2', masjid, 'Renovasi Masjid Al-Bayan', 'Bandung, Jawa Barat',
          AppAssets.masjid('masjid_al_bayan.jpg'), 80000000, 36000000, 25,
          'Renovasi atap, lantai, dan sistem pencahayaan masjid, serta penambahan ruang belajar mengaji untuk anak-anak.',
          sub: 'Masjid'),
      _c('m3', masjid, 'Perluasan Masjid Ar-Raihan', 'Medan, Sumatera Utara',
          AppAssets.masjid('masjid_ar_raihan.jpg'), 120000000, 54000000, 40,
          'Perluasan ruang salat dan perbaikan tempat wudhu agar mampu menampung jamaah pada salat Jumat dan hari besar.',
          sub: 'Masjid'),
      _c('m4', masjid, 'Perbaikan Fasilitas Masjid At-Tanwir', 'Makassar, Sulawesi Selatan',
          AppAssets.masjid('masjid_at_tanwir.jpg'), 60000000, 42000000, 20,
          'Pembangunan tempat wudhu baru, perbaikan sistem suara, dan penataan halaman masjid.',
          sub: 'Masjid'),
      _c('m5', masjid, 'Renovasi Masjid Az-Zahira', 'Yogyakarta, DI Yogyakarta',
          AppAssets.masjid('masjid_az_zahira.jpg'), 90000000, 27000000, 35,
          'Penataan taman, perbaikan kubah, dan penambahan perpustakaan masjid untuk kegiatan belajar warga.',
          sub: 'Masjid'),
      // ===== MUSHOLA (5) =====
      _c('m6', masjid, 'Pembangunan Mushola Al-Ihsan', 'Semarang, Jawa Tengah',
          AppAssets.masjid('mushola_al_ihsan.jpg'), 45000000, 30000000, 28,
          'Pembangunan mushola untuk warga perumahan: ruang salat, tempat wudhu, dan rak Al-Quran.',
          sub: 'Mushola'),
      _c('m7', masjid, 'Renovasi Mushola An-Nafis', 'Palembang, Sumatera Selatan',
          AppAssets.masjid('mushola_an_nafis.jpg'), 25000000, 9000000, 15,
          'Renovasi mushola lingkungan: perbaikan atap, penggantian karpet, dan penambahan kipas angin.',
          sub: 'Mushola'),
      _c('m8', masjid, 'Pembangunan Mushola Ar-Raudhah', 'Balikpapan, Kalimantan Timur',
          AppAssets.masjid('mushola_ar_raudhah.jpg'), 50000000, 12500000, 45,
          'Pembangunan mushola di kawasan perkantoran agar pekerja dan pengunjung mudah beribadah.',
          sub: 'Mushola'),
      _c('m9', masjid, 'Pengadaan Fasilitas Mushola As-Safa', 'Denpasar, Bali',
          AppAssets.masjid('mushola_as_safa.jpg'), 35000000, 21000000, 32,
          'Pengadaan perlengkapan salat, pengeras suara, dan tempat wudhu bagi komunitas muslim setempat.',
          sub: 'Mushola'),
      _c('m10', masjid, 'Perbaikan Mushola El-Qalbi', 'Padang, Sumatera Barat',
          AppAssets.masjid('mushola_el_qalbi.jpg'), 30000000, 16500000, 22,
          'Perbaikan mushola yang terdampak cuaca: atap, dinding, dan pengecatan ulang.',
          sub: 'Mushola'),

      // ===== BANTUAN SOSIAL / BENCANA (5) =====
      _c('s1', sosial, 'Bantuan Korban Banjir', 'Kalimantan Selatan',
          AppAssets.sosial('banjir.jpg'), 200000000, 64000000, 14,
          'Penyediaan makanan siap saji, air bersih, selimut, dan obat-obatan bagi warga terdampak banjir di pengungsian.',
          sub: 'Banjir'),
      _c('s2', sosial, 'Bantuan Korban Gempa Bumi', 'Nusa Tenggara Barat',
          AppAssets.sosial('gempa_bumi.jpg'), 250000000, 110000000, 21,
          'Pemenuhan kebutuhan darurat bagi korban gempa: tenda hunian sementara, logistik, dan layanan kesehatan.',
          sub: 'Gempa Bumi'),
      _c('s3', sosial, 'Penanganan Kebakaran Hutan dan Lahan', 'Riau',
          AppAssets.sosial('kebakaran_hutan.jpg'), 120000000, 33000000, 18,
          'Dukungan masker, layanan kesehatan bagi warga terdampak kabut asap, serta perlengkapan relawan pemadam.',
          sub: 'Kebakaran Hutan'),
      _c('s4', sosial, 'Bantuan Korban Tanah Longsor', 'Sumatera Barat',
          AppAssets.sosial('tanah_longsor.jpg'), 150000000, 72000000, 16,
          'Bantuan darurat dan pemulihan bagi keluarga yang kehilangan rumah akibat longsor, termasuk logistik dan perlengkapan sekolah anak.',
          sub: 'Tanah Longsor'),
      _c('s5', sosial, 'Bantuan Korban Tsunami', 'Sulawesi Tengah',
          AppAssets.sosial('tsunami.jpg'), 300000000, 135000000, 30,
          'Dukungan tanggap darurat dan pemulihan: dapur umum, air bersih, layanan kesehatan, dan hunian sementara.',
          sub: 'Tsunami'),

      // ===== ZAKAT (2) =====
      _c('z1', zakat, 'Zakat Fitrah (Beras)', 'Penyaluran melalui mitra, nasional',
          AppAssets.zakatFitrah, 200000000, 85000000, 365,
          'Tunaikan zakat fitrah dengan bantuan kalkulator: 2,5 kg beras per jiwa. Zakat fitrah disalurkan dalam bentuk beras kepada yang berhak.',
          sub: 'Fitrah'),
      _c('z2', zakat, 'Zakat Maal (Uang)', 'Penyaluran melalui mitra, nasional',
          AppAssets.zakatMaal, 500000000, 210000000, 365,
          'Hitung zakat penghasilan, tabungan dan harta, atau emas dengan kalkulator. Zakat maal disalurkan dalam bentuk uang kepada yang berhak.',
          sub: 'Maal'),

      // ===== KAUM DUAFA (4) =====
      _c('d1', duafa, 'Santunan Panti Asuhan Nurul Hidayah', 'Bogor, Jawa Barat',
          AppAssets.duafa('panti_asuhan.jpg'), 40000000, 26000000, 20,
          'Biaya sekolah, perlengkapan belajar, dan gizi bagi anak-anak panti asuhan.',
          sub: 'Panti Asuhan'),
      _c('d2', duafa, 'Perawatan Lansia Panti Jompo Husnul Khotimah', 'Surakarta, Jawa Tengah',
          AppAssets.duafa('panti_jompo.jpg'), 50000000, 19000000, 26,
          'Kebutuhan gizi, layanan kesehatan rutin, dan perlengkapan perawatan bagi lansia di panti jompo.',
          sub: 'Panti Jompo'),
      _c('d3', duafa, 'Bantuan Kebutuhan Pokok Fakir Miskin', 'Lampung',
          AppAssets.duafa('fakir_miskin.jpg'), 60000000, 15000000, 24,
          'Paket sembako dan kebutuhan dasar bagi keluarga fakir miskin yang belum menerima bantuan lain.',
          sub: 'Fakir Miskin'),
      _c('d4', duafa, 'Dukungan Alat Bantu Penyandang Disabilitas', 'Manado, Sulawesi Utara',
          AppAssets.duafa('disabilitas.jpg'), 45000000, 13500000, 30,
          'Pengadaan kursi roda, alat bantu dengar, dan pendampingan bagi penyandang disabilitas dari keluarga prasejahtera.',
          sub: 'Disabilitas'),

      // ===== QURBAN BERSAMA 1448 H (6) =====
      // Per orang: 1 orang = 1 hewan, harga tetap.
      _c('q1', qurban, 'Qurban Domba 1448 H', 'Malang, Jawa Timur',
          AppAssets.qurban('domba.jpg'), 50000000, 17500000, 180,
          'Qurban untuk satu orang: 1 ekor domba seharga Rp 2.500.000. Daging disalurkan kepada warga yang berhak di sekitar masjid mitra.',
          sub: 'Per Orang', unitPrice: 2500000, unitLabel: 'ekor'),
      _c('q2', qurban, 'Qurban Kambing 1448 H', 'Garut, Jawa Barat',
          AppAssets.qurban('kambing.jpg'), 60000000, 21000000, 180,
          'Qurban untuk satu orang: 1 ekor kambing seharga Rp 3.000.000. Daging disalurkan kepada warga yang berhak.',
          sub: 'Per Orang', unitPrice: 3000000, unitLabel: 'ekor'),
      _c('q3', qurban, 'Qurban Kerbau 1448 H', 'Brebes, Jawa Tengah',
          AppAssets.qurban('kerbau.jpg'), 70000000, 10500000, 180,
          'Qurban untuk satu orang: 1 ekor kerbau seharga Rp 3.500.000. Daging disalurkan kepada warga yang berhak.',
          sub: 'Per Orang', unitPrice: 3500000, unitLabel: 'ekor'),
      _c('q4', qurban, 'Qurban Sapi 1448 H', 'Boyolali, Jawa Tengah',
          AppAssets.qurban('sapi.jpg'), 70000000, 28000000, 180,
          'Qurban untuk satu orang: 1 ekor sapi seharga Rp 3.500.000. Daging disalurkan kepada warga yang berhak.',
          sub: 'Per Orang', unitPrice: 3500000, unitLabel: 'ekor'),
      // Kolektif: 7 slot, harga per slot. (Jika Rp 5 juta itu TOTAL, ubah unitPrice jadi 714286.)
      _c('q5', qurban, 'Qurban Kolektif 7 Orang 1448 H', 'Lamongan, Jawa Timur',
          AppAssets.qurban('qurban_kolektif.jpg'), 35000000, 20000000, 180,
          'Satu hewan untuk 7 orang. Setiap peserta mengambil satu slot atau lebih seharga Rp 5.000.000 per slot. Program ditutup otomatis saat 7 slot penuh.',
          sub: 'Kolektif', unitPrice: 5000000, unitLabel: 'slot', slotTotal: 7, slotFilled: 4),
      // Bersama: peserta tidak terbatas, nominal bebas sampai target dana.
      _c('q6', qurban, 'Qurban Bersama 1448 H', 'Beberapa wilayah mitra',
          AppAssets.qurban('qurban_bersama.jpg'), 100000000, 38000000, 180,
          'Qurban tanpa batas jumlah peserta. Berdonasi dengan nominal bebas sampai target dana tercapai, lalu dana dibelikan hewan qurban dan disalurkan kepada yang berhak.',
          sub: 'Bersama'),
    ];
  }
}