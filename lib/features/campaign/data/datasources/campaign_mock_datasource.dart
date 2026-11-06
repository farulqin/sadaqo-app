import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_remote_datasource.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';

/// Data dummy (nama dan lokasi fiktif) selama backend belum siap.
/// Untuk memakai foto: taruh file di assets/images/programs/ lalu isi
/// imageAsset, contoh: imageAsset: '${AppAssets.programs}/masjid.jpg'
class CampaignMockDataSource implements CampaignRemoteDataSource {
  @override
  Future<List<CampaignModel>> getCampaigns() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    return [
      CampaignModel(
        id: 'c1',
        title: 'Pembangunan Masjid Al-Falah',
        description:
            'Mari bersama wujudkan masjid yang nyaman untuk masyarakat sekitar. '
            'Dana digunakan untuk pembangunan ruang ibadah, tempat wudhu, dan '
            'fasilitas pendukung agar jamaah dapat beribadah dengan tenang.',
        category: ProgramCategory.masjid,
        targetAmount: 100000000,
        collectedAmount: 75000000,
        deadline: now.add(const Duration(days: 12)),
        location: 'Surabaya, Jawa Timur',
      ),
      CampaignModel(
        id: 'c2',
        title: 'Paket Sembako untuk Fakir Miskin',
        description:
            'Bantu penuhi kebutuhan pokok keluarga prasejahtera di sekitar kita. '
            'Setiap donasi disalurkan dalam bentuk paket sembako lengkap.',
        category: ProgramCategory.sosial,
        targetAmount: 50000000,
        collectedAmount: 18500000,
        deadline: now.add(const Duration(days: 25)),
        location: 'Sidoarjo, Jawa Timur',
      ),
      CampaignModel(
        id: 'c3',
        title: 'Santunan Anak Yatim Nurul Hidayah',
        description:
            'Santunan pendidikan dan kebutuhan harian bagi anak yatim piatu. '
            'Dana mencakup biaya sekolah, perlengkapan belajar, dan gizi.',
        category: ProgramCategory.yatim,
        targetAmount: 30000000,
        collectedAmount: 21000000,
        deadline: now.add(const Duration(days: 18)),
        location: 'Gresik, Jawa Timur',
      ),
      CampaignModel(
        id: 'c4',
        title: 'Kurban Bersama 1447 H',
        description:
            'Berkurban patungan: satu sapi untuk 7 orang. Daging disalurkan '
            'kepada warga yang membutuhkan di sekitar masjid mitra.',
        category: ProgramCategory.kurban,
        targetAmount: 70000000,
        collectedAmount: 49000000,
        deadline: now.add(const Duration(days: 40)),
        location: 'Mojokerto, Jawa Timur',
      ),
    ];
  }
}
