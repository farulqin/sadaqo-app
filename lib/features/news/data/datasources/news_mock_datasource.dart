import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/news/data/datasources/news_remote_datasource.dart';
import 'package:sadaqo/features/news/data/models/news_model.dart';

/// Berita contoh (edukatif, bukan klaim penyaluran). Isi dan urutannya SAMA
/// dengan seeder Laravel (database/seeders/data/news.json).
/// Batas isi berita: maksimal 1000 kata per artikel.
class NewsMockDataSource implements NewsRemoteDataSource {
  @override
  Future<List<NewsModel>> getNews() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      NewsModel(
        id: 'n1',
        title: 'Memakmurkan Masjid Dimulai dari Kepedulian Jamaah',
        summary:
            'Masjid yang terawat bukan hanya soal bangunan, tetapi tentang kebersamaan jamaah yang saling menopang.',
        content:
            'Masjid dan musala adalah pusat kegiatan warga. Di sana orang beribadah, belajar mengaji, bermusyawarah, hingga menyiapkan kegiatan sosial. Ketika bangunannya nyaman dan terawat, jamaah lebih mudah menjalankan ibadah dengan tenang, dan anak-anak pun betah belajar di dalamnya.\n\n'
            'Namun pembangunan dan perawatan masjid membutuhkan biaya yang tidak sedikit. Kebutuhan yang paling sering muncul antara lain ruang ibadah yang cukup luas, tempat wudhu yang bersih, penerangan dan sirkulasi udara yang baik, hingga perbaikan atap yang bocor. Di banyak lingkungan, pengurus masjid mengandalkan kotak infak dan swadaya warga untuk menutup semua kebutuhan itu.\n\n'
            'Di sinilah donasi patungan berperan. Nominal kecil yang diberikan banyak orang bisa menjadi kekuatan besar. Misalnya, Rp 25.000 dari seribu orang sudah terkumpul Rp 25 juta. Semangat inilah yang ingin dibawa SADAQO: kebaikan yang ringan bagi setiap orang, tetapi terasa besar bagi masjid yang membutuhkan.\n\n'
            'Sebelum berdonasi, ada baiknya kamu memeriksa beberapa hal. Baca tujuan dan rencana penggunaan dana dengan teliti. Perhatikan apakah program sudah berlabel terverifikasi. Lihat juga laporan perkembangan dan dokumentasinya, sehingga kamu tahu ke mana dana dialirkan dan seberapa jauh targetnya tercapai.\n\n'
            'Kamu juga bisa membantu tanpa uang. Membagikan informasi program kepada keluarga dan teman, ikut kerja bakti membersihkan masjid, atau menyumbangkan tenaga dan keahlian adalah bentuk kepedulian yang sama berharganya.\n\n'
            'Program "Pembangunan Masjid Al-Falah" di aplikasi ini adalah contoh program kategori Masjid dan Musala. Kamu dapat membuka detailnya, melihat progres dana, lalu mencoba alur donasi simulasi dari halaman ini.',
        category: ProgramCategory.masjid,
        campaignId: 'c1',
        author: 'Redaksi SADAQO',
        publishedAt: now.subtract(const Duration(days: 1)),
      ),
      NewsModel(
        id: 'n2',
        title: 'Sembako untuk Tetangga: Cara Sedekah yang Tepat Sasaran',
        summary:
            'Bantuan pangan paling bermanfaat jika sampai kepada keluarga yang benar-benar membutuhkan dan disalurkan dengan menjaga martabat penerima.',
        content:
            'Di sekitar kita, masih banyak keluarga yang kesulitan memenuhi kebutuhan pokok sehari-hari. Bagi mereka, sekantong beras, minyak goreng, gula, dan telur bukan sekadar bantuan, tetapi kelegaan untuk beberapa hari ke depan. Karena itu, paket sembako menjadi salah satu bentuk sedekah yang paling mudah dipahami dan dirasakan manfaatnya.\n\n'
            'Agar bantuan tepat sasaran, ada beberapa hal yang perlu diperhatikan. Pertama, libatkan pihak yang mengenal kondisi warga, misalnya pengurus RT, RW, atau takmir masjid setempat. Mereka biasanya lebih tahu keluarga mana yang paling membutuhkan. Kedua, hindari penumpukan bantuan pada satu keluarga yang sama, sementara keluarga lain belum tersentuh sama sekali.\n\n'
            'Hal yang tidak kalah penting adalah menjaga martabat penerima. Tidak semua orang nyaman jika kondisinya dipublikasikan. Dokumentasi penyaluran sebaiknya tidak menampilkan wajah atau alamat penerima tanpa izin. Fokuskan laporan pada jumlah paket, waktu, dan lokasi umum penyaluran.\n\n'
            'Transparansi juga membuat donatur lebih tenang. Pengelola program yang baik akan melaporkan berapa dana yang terkumpul, berapa paket yang disiapkan, dan kapan penyaluran dilakukan. Laporan seperti ini memudahkan donatur menilai apakah program dikelola dengan jujur.\n\n'
            'Jika kamu ingin ikut membantu, kamu bisa mencoba program contoh "Paket Sembako untuk Fakir Miskin" di aplikasi ini. Nominal donasi bebas dan dapat dimulai dari Rp 10.000. Ingat, donasi di versi demo ini hanya simulasi dan tidak memindahkan uang sungguhan.',
        category: ProgramCategory.sosial,
        campaignId: 'c2',
        author: 'Redaksi SADAQO',
        publishedAt: now.subtract(const Duration(days: 2)),
      ),
      NewsModel(
        id: 'n3',
        title: 'Menyantuni Anak Yatim: Kebaikan yang Terus Mengalir',
        summary:
            'Dukungan untuk anak yatim tidak berhenti pada uang. Pendidikan, gizi, dan perhatian membuat masa depan mereka lebih cerah.',
        content:
            'Dalam ajaran Islam, menyantuni anak yatim sangat dianjurkan. Anak yang kehilangan orang tua membutuhkan lebih dari sekadar bantuan sesaat. Mereka membutuhkan kepastian untuk tetap bersekolah, makan dengan gizi yang cukup, dan tumbuh di lingkungan yang peduli.\n\n'
            'Kebutuhan anak yatim biasanya mencakup biaya sekolah, seragam dan perlengkapan belajar, makanan bergizi, serta layanan kesehatan dasar. Jika kebutuhan itu terpenuhi secara berkelanjutan, anak-anak dapat fokus belajar dan mengembangkan potensinya, bukan khawatir tentang esok hari.\n\n'
            'Karena itu, santunan yang rutin sering kali lebih berdampak daripada bantuan yang besar tetapi hanya sekali. Donasi kecil yang diberikan setiap bulan membantu panti atau pengelola merencanakan kebutuhan anak dengan lebih baik.\n\n'
            'Selain dana, dukungan non-materi juga sangat berarti. Meluangkan waktu untuk mengajar, membimbing membaca, atau sekadar menemani anak-anak bermain memberi mereka rasa dihargai dan diperhatikan. Hal-hal sederhana ini sering kali membekas lebih lama.\n\n'
            'Satu hal yang perlu dijaga bersama adalah privasi anak. Foto wajah, nama lengkap, dan alamat anak sebaiknya tidak disebarkan tanpa izin pengasuh atau wali. Kepedulian yang baik tidak boleh mengorbankan rasa aman dan harga diri mereka.\n\n'
            'Di aplikasi ini tersedia program contoh "Santunan Anak Yatim Nurul Hidayah". Kamu bisa membaca detailnya, melihat progres dana, dan mencoba donasi simulasi langsung dari halaman berita ini.',
        category: ProgramCategory.yatim,
        campaignId: 'c3',
        author: 'Redaksi SADAQO',
        publishedAt: now.subtract(const Duration(days: 4)),
      ),
      NewsModel(
        id: 'n4',
        title: 'Panduan Qurban Patungan: Satu Sapi untuk Tujuh Orang',
        summary:
            'Qurban patungan memudahkan lebih banyak orang berqurban dengan biaya yang terbagi, dan di SADAQO kuota bagiannya dapat dipantau.',
        content:
            'Berqurban adalah ibadah yang dinantikan banyak orang setiap tahun. Namun harga hewan qurban, terutama sapi, sering terasa berat bagi satu orang. Qurban patungan hadir sebagai jalan tengah: satu ekor sapi diikuti oleh sampai tujuh orang, dan masing-masing mengambil satu bagian.\n\n'
            'Sebagai gambaran pada data demo di aplikasi ini, satu bagian dihargai Rp 2.000.000, sehingga satu ekor sapi senilai Rp 14.000.000. Dengan skema ini, peserta dapat berqurban tanpa harus menanggung seluruh harga hewan sendirian. Angka tersebut hanya contoh dan nilai sebenarnya mengikuti kebijakan pengelola.\n\n'
            'Alurnya sederhana. Pertama, pilih program qurban dan jenis hewan yang tersedia. Kedua, pilih jumlah bagian yang ingin diambil. Ketiga, selesaikan pembayaran sebelum tenggat. Keempat, pantau kuota: setiap bagian yang terisi akan mengurangi sisa kuota, dan program ditutup ketika seluruh bagian sudah penuh.\n\n'
            'Setelah pelaksanaan, pengelola yang baik akan melaporkan proses penyembelihan dan penyaluran daging, misalnya kepada warga sekitar masjid mitra, lengkap dengan dokumentasi yang menjaga privasi penerima.\n\n'
            'Satu catatan penting: ketentuan syarat hewan, usia, kondisi, waktu pelaksanaan, dan hal-hal fikih lainnya sebaiknya ditanyakan langsung kepada ustaz atau lembaga yang terpercaya. Informasi di halaman ini bersifat umum dan bukan fatwa.\n\n'
            'Kamu dapat melihat program contoh "Qurban Bersama 1447 H" melalui tombol donasi di bawah. Ingat, donasi pada versi demo ini hanya simulasi.',
        category: ProgramCategory.qurban,
        campaignId: 'c4',
        author: 'Redaksi SADAQO',
        publishedAt: now.subtract(const Duration(days: 6)),
      ),
      NewsModel(
        id: 'n5',
        title: 'Tips Berdonasi Online dengan Aman dan Terpercaya',
        summary:
            'Lima kebiasaan sederhana agar niat baikmu sampai kepada penerima yang tepat dan terhindar dari penggalangan dana palsu.',
        content:
            'Kemudahan berdonasi lewat ponsel membuat siapa pun bisa berbagi kapan saja. Sayangnya, kemudahan ini juga dimanfaatkan sebagian pihak untuk penggalangan dana yang tidak jelas. Dengan beberapa kebiasaan sederhana, kamu dapat berdonasi dengan lebih tenang.\n\n'
            'Pertama, kenali siapa pengelola program. Pastikan ada identitas yang jelas, lokasi umum kegiatan, dan cara menghubungi pengelola. Program tanpa identitas yang bisa ditelusuri patut diwaspadai.\n\n'
            'Kedua, perhatikan label verifikasi. Di SADAQO, label terverifikasi hanya muncul setelah admin memeriksa pengajuan program. Program yang belum diperiksa tidak ditampilkan sebagai program aktif.\n\n'
            'Ketiga, baca laporan penggunaan dana. Program yang transparan akan menyampaikan perkembangan dan penyaluran secara berkala. Keempat, waspadai tekanan berlebihan seperti ajakan yang mendesak untuk segera transfer atau cerita yang terlalu emosional tanpa data pendukung.\n\n'
            'Kelima, lindungi data pribadimu. Jangan pernah membagikan kata sandi, kode OTP, atau data kartu kepada siapa pun yang mengatasnamakan pengelola program. Simpan juga bukti donasi sebagai arsip pribadi.\n\n'
            'Perlu diketahui, aplikasi SADAQO pada versi demo ini menggunakan donasi simulasi. Tidak ada uang sungguhan yang berpindah dan tidak ada data kartu yang disimpan. Kamu bebas mencoba seluruh alurnya dengan aman.',
        category: ProgramCategory.sosial,
        campaignId: 'c2',
        author: 'Redaksi SADAQO',
        publishedAt: now.subtract(const Duration(days: 9)),
      ),
    ];
  }
}
