<?php

namespace Database\Seeders;

use App\Models\CommunityComment;
use App\Models\CommunityEvent;
use App\Models\CommunityPost;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/** Isi contoh Komunitas. Jalankan: php artisan db:seed --class=CommunitySeeder setelah DemoDataSeeder. */
class CommunityDemoSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::where('role', 'admin')->first();
        $pengelola = User::where('role', 'pengelola')->first();
        $demo = User::where('email', 'like', '%@example.com')->get();
        $donatur = User::where('email', 'donatur.demo@sadaqo.test')->first();

        if (!$admin || $demo->isEmpty()) {
            $this->command?->warn('Jalankan seeder utama dan DemoDataSeeder dulu.');
            return;
        }

        // Semua donatur contoh otomatis bergabung.
        foreach ($demo->concat($donatur ? [$donatur] : []) as $u) {
            DB::table('community_members')->updateOrInsert(
                ['user_id' => $u->id],
                ['created_at' => now(), 'updated_at' => now()]
            );
        }
        // Status online: sebagian anggota terlihat aktif.
        foreach ($demo->take(5) as $u) {
            DB::table('users')->where('id', $u->id)->update(['last_seen_at' => now()->subMinutes(random_int(0, 4))]);
        }

        if (DB::table('community_posts')->exists()) {
            $this->command?->info('Isi komunitas sudah ada, dilewati.');
            return;
        }

        $by = fn (string $name) => $demo->firstWhere('name', $name) ?? $demo->first();
        $siti = $by('Siti Rahma');
        $ahmad = $by('Ahmad Fauzi');
        $nur = $by('Nur Aini');
        $rizki = $by('Rizki Ramadhan');
        $dewi = $by('Dewi Lestari');

        CommunityPost::unguard();
        CommunityComment::unguard();

        $make = function (User $u, string $category, string $body, int $minutesAgo, bool $pinned = false): CommunityPost {
            $p = CommunityPost::create(['user_id' => $u->id, 'category' => $category, 'body' => $body, 'is_pinned' => $pinned]);
            $p->forceFill(['created_at' => now()->subMinutes($minutesAgo), 'updated_at' => now()->subMinutes($minutesAgo)])->save();

            return $p;
        };
        $comment = function (CommunityPost $p, User $u, string $body, int $minutesAgo, ?CommunityComment $parent = null) {
            $c = CommunityComment::create(['post_id' => $p->id, 'user_id' => $u->id, 'parent_id' => $parent?->id, 'body' => $body]);
            $c->forceFill(['created_at' => now()->subMinutes($minutesAgo), 'updated_at' => now()->subMinutes($minutesAgo)])->save();

            return $c;
        };

        $welcome = $make($admin, 'info', 'Selamat datang di Komunitas SADAQO! Ruang ini untuk berbagi cerita kebaikan, berdiskusi, dan bergerak bersama. Mari saling menjaga adab: tanpa hoaks, ujaran kebencian, dan penipuan.', 60 * 24 * 3, true);

        $post1 = $make($siti, 'diskusi', 'Menurut teman-teman, apakah kita juga perlu adakan program kurban patungan tahun ini? 😊', 180);
        $c1 = $comment($post1, $nur, 'Setuju banget! Semoga bisa segera terealisasi 🙏', 60);
        $comment($post1, $siti, 'Aamiin, nanti kita bahas detailnya di agenda ya.', 45, $c1);
        $comment($post1, $rizki, 'Boleh juga dibuat kolektif 7 orang supaya terjangkau.', 30);

        $post2 = $make($ahmad, 'diskusi', 'Alhamdulillah, kegiatan bakti sosial kemarin berjalan lancar! Terima kasih semua yang sudah ikut membantu 🙏', 120);
        $comment($post2, $dewi, 'MasyaAllah, semoga berkah ya!', 100);

        // Polling dengan suara dari anggota contoh.
        $pollPost = $make($admin, 'diskusi', 'Ayo tentukan arah kegiatan komunitas kita bulan depan. Suaramu sangat berarti!', 90);
        $poll = $pollPost->poll()->create(['question' => 'Program apa yang ingin kita adakan berikutnya di komunitas?', 'ends_at' => now()->addDays(2)]);
        $options = collect(['Kajian Islam Online', 'Bakti Sosial', 'Donasi Pendidikan'])
            ->map(fn ($label, $i) => $poll->options()->create(['label' => $label, 'sort_order' => $i]));
        foreach ($demo->values() as $i => $u) {
            DB::table('community_poll_votes')->insert([
                'poll_id' => $poll->id,
                'option_id' => $options[[0, 0, 1, 1, 0, 2, 1, 0, 2, 1, 0][$i % 11]]->id,
                'user_id' => $u->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        $post3 = $make($nur, 'diskusi', 'Ada yang punya tips mengajak keluarga berdonasi rutin tiap Jumat? Saya ingin membiasakannya di rumah.', 300);
        $comment($post3, $ahmad, 'Coba sediakan celengan khusus, Kak. Anak-anak jadi semangat ikut memasukkan uang.', 250);

        if ($pengelola) {
            $make($pengelola, 'info', 'Laporan penyaluran program sudah bisa dilihat donatur di Riwayat > Laporan & Dokumentasi. Terima kasih atas kepercayaan Anda.', 60 * 8);
        }

        // Apresiasi acak dari anggota contoh.
        foreach (CommunityPost::all() as $p) {
            $likers = $demo->shuffle()->take(random_int(2, 9));
            foreach ($likers as $u) {
                DB::table('community_post_likes')->insertOrIgnore([
                    'post_id' => $p->id, 'user_id' => $u->id, 'created_at' => now(), 'updated_at' => now(),
                ]);
            }
        }

        // Agenda: tanggal relatif terhadap hari ini supaya selalu "mendatang".
        $events = [
            ['Kajian Islam: Menyebar Kebaikan di Era Digital', 'Kajian umum bersama ustaz tamu, dilanjutkan tanya jawab.', 'Masjid Al-Falah, Surabaya', false, now()->addDays(3)->setTime(19, 0), now()->addDays(3)->setTime(21, 0)],
            ['Donasi untuk Pendidikan Anak', 'Pengumpulan donasi buku dan perlengkapan sekolah untuk anak panti asuhan.', 'Online via Zoom', true, now()->addDays(9)->setTime(8, 0), now()->addDays(9)->setTime(10, 0)],
            ['Bakti Sosial Bersama SADAQO', 'Pembagian paket sembako dan kerja bakti lingkungan.', 'Balai Warga Wonokromo, Surabaya', false, now()->addDays(14)->setTime(7, 30), now()->addDays(14)->setTime(11, 0)],
        ];
        foreach ($events as [$title, $desc, $loc, $online, $start, $end]) {
            $e = CommunityEvent::create([
                'created_by' => ($pengelola ?? $admin)->id, 'title' => $title, 'description' => $desc,
                'location' => $loc, 'is_online' => $online, 'starts_at' => $start, 'ends_at' => $end,
            ]);
            foreach ($demo->shuffle()->take(random_int(3, 9)) as $u) {
                DB::table('community_event_interests')->insertOrIgnore([
                    'event_id' => $e->id, 'user_id' => $u->id, 'created_at' => now(), 'updated_at' => now(),
                ]);
            }
        }

        $this->command?->info('Isi Komunitas contoh dibuat.');
    }
}