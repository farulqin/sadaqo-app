import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/news/data/datasources/news_remote_datasource.dart';
import 'package:sadaqo/features/news/data/models/news_model.dart';

/// Berita contoh (edukatif, bukan klaim penyaluran). Satu berita per kategori.
/// Batas isi berita: maksimal 1000 kata per artikel.
class NewsMockDataSource implements NewsRemoteDataSource {
  @override
  Future<List<NewsModel>> getNews() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      NewsModel(
        id: 'n1',
        title: 'Memakmurkan Masjid dan Mushola, dari Bangunan hingga Kegiatan',
        summary:
            'Masjid dan mushola yang terawat adalah pusat kebersamaan warga, dan perawatannya bisa dibantu banyak orang.',
        content:
            'Masjid dan mushola adalah pusat kegiatan warga. Di sana orang beribadah, belajar mengaji, bermusyawarah, dan menyiapkan kegiatan sosial. Ketika bangunannya nyaman dan terawat, jamaah lebih tenang beribadah dan anak-anak betah belajar di dalamnya.\n\n'
            'Pembangunan dan perawatan membutuhkan biaya yang tidak sedikit: ruang salat yang cukup, tempat wudhu yang bersih, penerangan, sirkulasi udara, hingga atap yang bocor. Banyak pengurus mengandalkan kotak infak dan swadaya warga untuk menutup semua kebutuhan itu.\n\n'
            'Donasi patungan bisa menjadi jalan keluar. Nominal kecil yang diberikan banyak orang menjadi kekuatan besar: Rp 25.000 dari seribu orang sudah menjadi Rp 25 juta. Di SADAQO, setiap transaksi dapat dimulai dari Rp 5.000.\n\n'
            'Sebelum berdonasi, baca tujuan dan rencana penggunaan dana, perhatikan label verifikasi, serta lihat laporan perkembangan program.\n\n'
            'Kamu juga bisa membantu tanpa uang, misalnya ikut kerja bakti atau membagikan informasi program kepada keluarga dan teman. Di aplikasi ini tersedia 5 masjid dan 5 mushola contoh dari berbagai kota. Coba lihat Pembangunan Masjid Al-Azzam melalui tombol di bawah.',
        category: ProgramCategory.masjid,
        campaignId: 'm1',
        author: 'Redaksi SADAQO',
        publishedAt: now.subtract(const Duration(days: 1)),
      ),
      NewsModel(
        id: 'n2',
        title: 'Membantu Korban Bencana Alam: Cara Berdonasi yang Efektif',
        summary:
            'Banjir, gempa, longsor, dan bencana lain menuntut bantuan yang cepat dan tepat sasaran.',
        content:
            'Banjir, gempa bumi, kebakaran hutan, tanah longsor, dan tsunami datang tanpa aba-aba. Dalam hitungan jam, ribuan orang bisa kehilangan rumah, pekerjaan, dan rasa aman. Karena itu, bantuan yang cepat dan tepat sangat menentukan.\n\n'
            'Pada fase tanggap darurat, kebutuhan paling mendesak adalah makanan, air bersih, selimut, obat-obatan, dan tempat berlindung. Setelah itu, dukungan beralih ke pemulihan: memperbaiki rumah, fasilitas umum, dan mata pencaharian warga.\n\n'
            'Donasi uang umumnya lebih fleksibel dibanding mengirim barang, karena pengelola dapat membeli kebutuhan yang paling dibutuhkan di dekat lokasi bencana. Cara ini juga menghemat ongkos kirim dan mencegah penumpukan barang yang tidak terpakai.\n\n'
            'Pilih program yang jelas pengelolanya dan memiliki laporan penyaluran. Hindari ajakan yang meminta transfer ke rekening pribadi tanpa identitas yang bisa ditelusuri. Menjaga martabat korban juga penting: dokumentasi sebaiknya tidak menampilkan wajah atau kondisi pribadi tanpa izin.\n\n'
            'Di aplikasi ini tersedia lima program bantuan bencana contoh: banjir, gempa bumi, kebakaran hutan, tanah longsor, dan tsunami. Nama lokasi dan angkanya hanya contoh. Kamu bisa mencoba alur donasi simulasi lewat tombol di bawah.',
        category: ProgramCategory.sosial,
        campaignId: 's1',
        author: 'Redaksi SADAQO',
        publishedAt: now.subtract(const Duration(days: 2)),
      ),
      NewsModel(
        id: 'n3',
        title: 'Zakat Fitrah dan Zakat Maal: Apa Bedanya?',
        summary:
            'Dua jenis zakat dengan waktu dan cara hitung berbeda. Kalkulator di aplikasi membantumu memperkirakan nominalnya.',
        content:
            'Zakat fitrah dan zakat maal sama-sama kewajiban bagi muslim yang mampu, tetapi berbeda dalam waktu dan cara menghitungnya.\n\n'
            'Zakat fitrah ditunaikan menjelang akhir Ramadan untuk setiap jiwa. Ukurannya 2,5 kilogram beras per orang, atau setara 3,5 liter makanan pokok. Di SADAQO, zakat fitrah disalurkan dalam bentuk beras, dan kalkulator membantu menghitung jumlah jiwa serta nilainya.\n\n'
            'Zakat maal adalah zakat atas harta, seperti penghasilan, tabungan, dan emas. Harta wajib dizakati bila mencapai nisab setara 85 gram emas dan telah dimiliki satu tahun (haul), dengan kadar 2,5 persen. Zakat maal di SADAQO disalurkan dalam bentuk uang.\n\n'
            'Untuk zakat penghasilan, BAZNAS menetapkan nisab tahun 2026 sebesar Rp 7.640.144 per bulan atau Rp 91.681.728 per tahun, dengan kadar 2,5 persen dari penghasilan bruto.\n\n'
            'Hasil kalkulator bersifat perkiraan. Ketentuan lengkap sebaiknya dikonsultasikan dengan lembaga amil zakat atau ustaz, dan informasi ini bukan fatwa. Coba kalkulatornya melalui tombol di bawah. Perlu diingat, pembayaran di versi demo ini hanya simulasi.',
        category: ProgramCategory.zakat,
        campaignId: 'z2',
        author: 'Redaksi SADAQO',
        publishedAt: now.subtract(const Duration(days: 4)),
      ),
      NewsModel(
        id: 'n4',
        title: 'Peduli Kaum Duafa: dari Panti Asuhan hingga Panti Jompo',
        summary:
            'Kaum duafa membutuhkan dukungan yang berkelanjutan, bukan sekadar bantuan sesaat.',
        content:
            'Kaum duafa adalah sesama yang lemah secara ekonomi atau sosial, termasuk fakir miskin, anak-anak panti asuhan, lansia di panti jompo, dan penyandang disabilitas. Mereka membutuhkan lebih dari sekadar bantuan sesaat.\n\n'
            'Anak-anak panti asuhan membutuhkan biaya sekolah, perlengkapan belajar, dan gizi yang cukup agar dapat tumbuh dan meraih cita-cita. Lansia di panti jompo membutuhkan perawatan kesehatan rutin, makanan bergizi, dan perhatian.\n\n'
            'Bagi fakir miskin, paket kebutuhan pokok meringankan beban harian. Bagi penyandang disabilitas, alat bantu seperti kursi roda membuka akses untuk bergerak, belajar, dan bekerja.\n\n'
            'Dukungan yang rutin sering lebih berdampak daripada bantuan besar yang hanya sekali. Selain dana, waktu dan perhatian, seperti mengajar, menemani, atau sekadar berkunjung, juga sangat berarti.\n\n'
            'Jaga privasi mereka. Foto wajah, nama lengkap, dan alamat sebaiknya tidak disebarkan tanpa izin pengasuh atau wali. Di aplikasi ini tersedia empat program contoh Kaum Duafa. Kamu bisa membuka Santunan Panti Asuhan lewat tombol di bawah dan mencoba donasi simulasi.',
        category: ProgramCategory.duafa,
        campaignId: 'd1',
        author: 'Redaksi SADAQO',
        publishedAt: now.subtract(const Duration(days: 6)),
      ),
      NewsModel(
        id: 'n5',
        title: 'Memilih Paket Qurban: Per Orang, Kolektif, atau Bersama',
        summary:
            'Tiga pilihan qurban agar lebih banyak orang bisa berqurban sesuai kemampuannya.',
        content:
            'Qurban dapat ditunaikan dengan beberapa cara, tergantung kemampuan dan kebutuhan. SADAQO menyediakan tiga pilihan agar lebih banyak orang bisa berqurban.\n\n'
            'Pertama, Qurban Per Orang: satu hewan untuk satu orang. Pilihan hewannya domba, kambing, kerbau, atau sapi, dan harga tiap hewan tertera jelas di setiap program.\n\n'
            'Kedua, Qurban Kolektif: satu hewan dipatungi oleh tujuh orang. Setiap peserta mengambil satu slot atau lebih, dan sisa slot terlihat langsung. Ketika ketujuh slot terisi, program ditutup.\n\n'
            'Ketiga, Qurban Bersama: jumlah peserta tidak dibatasi. Siapa pun dapat berdonasi dengan nominal bebas, minimal Rp 5.000, sampai target dana tercapai. Setelah itu dana dibelikan hewan qurban dan disalurkan.\n\n'
            'Satu catatan penting: syarat hewan, usia, kondisi, dan waktu pelaksanaan sebaiknya ditanyakan kepada ustaz atau lembaga terpercaya. Informasi di sini bersifat umum dan bukan fatwa. Program contoh Qurban Bersama 1448 H dapat dicoba lewat tombol di bawah. Ingat, donasi pada versi demo ini hanya simulasi.',
        category: ProgramCategory.qurban,
        campaignId: 'q6',
        author: 'Redaksi SADAQO',
        publishedAt: now.subtract(const Duration(days: 9)),
      ),
    ];
  }
}