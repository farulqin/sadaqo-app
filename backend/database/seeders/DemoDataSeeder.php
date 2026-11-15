<?php

namespace Database\Seeders;

use App\Models\Campaign;
use App\Models\Donation;
use App\Models\PaymentProvider;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/**
 * Data contoh untuk demo: donatur contoh dan riwayat donasi setahun terakhir.
 * Jalankan setelah seeder utama:  php artisan db:seed --class=DemoDataSeeder
 *
 * Untuk tiap program, donasi dibuat sampai total donasi sukses = dana terkumpul
 * program (angka dashboard cocok dengan progres program). Aman dijalankan ulang:
 * hanya menambah selisih yang masih kurang. Password donatur contoh =
 * SEED_DONATUR_PASSWORD di .env.
 */
class DemoDataSeeder extends Seeder
{
    private const DONORS = [
        ['Siti Rahma', 'siti.rahma@example.com', '081230001101', 210],
        ['Ahmad Fauzi', 'ahmad.fauzi@example.com', '081330001102', 185],
        ['Nur Aini', 'nur.aini@example.com', null, 140],
        ['Rizki Ramadhan', 'rizki.r@example.com', null, 120],
        ['Dewi Lestari', 'dewi.lestari@example.com', null, 98],
        ['Budi Santoso', 'budi.santoso@example.com', null, 75],
        ['Aisyah Putri', 'aisyah.putri@example.com', null, 60],
        ['Fajar Nugroho', 'fajar.n@example.com', null, 44],
        ['Laila Hidayati', 'laila.h@example.com', null, 30],
        ['Yusuf Hakim', 'yusuf.hakim@example.com', null, 17],
        ['Maya Anggraini', 'maya.a@example.com', null, 9],
    ];

    private const AMOUNTS = [
        25000, 50000, 100000, 100000, 250000, 250000, 500000, 500000, 1000000, 2500000,
    ];

    public function run(): void
    {
        $password = env('SEED_DONATUR_PASSWORD') ?: Str::random(16);

        $users = collect(self::DONORS)->map(function (array $d) use ($password) {
            [$name, $email, $phone, $daysAgo] = $d;
            $user = User::where('email', $email)->first() ?? new User();
            $user->forceFill([
                'name' => $name,
                'email' => $email,
                'phone' => $phone,
                'password' => $password,
                'role' => 'donatur',
                'email_verified_at' => now(),
            ])->save();
            $user->forceFill(['created_at' => now()->subDays($daysAgo)])->save();

            return $user;
        });

        $ewallets = PaymentProvider::where('type', 'ewallet')->where('is_active', true)->get();
        $banks = PaymentProvider::where('type', 'bank')->where('is_active', true)->get();
        $campaigns = Campaign::active()->get();

        if ($campaigns->isEmpty() || $ewallets->isEmpty() || $banks->isEmpty()) {
            $this->command?->warn('Program atau penyedia pembayaran belum ada. Jalankan seeder utama dulu.');
            return;
        }

        $rows = [];
        foreach ($campaigns as $campaign) {
            $already = (int) Donation::where('campaign_id', $campaign->id)
                ->where('status', 'success')
                ->sum('amount');
            $gap = (int) $campaign->collected_amount - $already;
            if ($gap <= 0) {
                continue;
            }
            foreach ($this->split($gap, $campaign->unit_price ? (int) $campaign->unit_price : null) as $amount) {
                $rows[] = $this->row($campaign->id, $users, $ewallets, $banks, $amount);
            }
        }

        foreach (array_chunk($rows, 500) as $chunk) {
            Donation::insert($chunk);
        }

        $this->command?->info('Data demo siap: ' . $users->count() . ' donatur, ' . count($rows) . ' donasi ditambahkan.');
    }

    /** Memecah dana menjadi beberapa donasi yang jumlahnya persis sama dengan $gap. */
    private function split(int $gap, ?int $unitPrice): array
    {
        if ($unitPrice) {
            $n = max(1, intdiv($gap, $unitPrice));
            $amounts = array_fill(0, $n, $unitPrice);
            $amounts[$n - 1] += $gap - $unitPrice * $n; // sisa pembulatan
            return $amounts;
        }

        $amounts = [];
        $left = $gap;
        while ($left > 0) {
            $a = self::AMOUNTS[array_rand(self::AMOUNTS)];
            if ($a >= $left || $left - $a < 5000) {
                $amounts[] = $left;
                break;
            }
            $amounts[] = $a;
            $left -= $a;
        }

        return $amounts;
    }

    private function row(int $campaignId, $users, $ewallets, $banks, int $amount): array
    {
        $user = $users->random();
        $anonymous = random_int(1, 100) <= 12;
        $method = ['qris', 'ewallet', 'ewallet', 'transfer'][random_int(0, 3)];
        $provider = match ($method) {
            'ewallet' => $ewallets->random(),
            'transfer' => $banks->random(),
            default => null,
        };

        // Lebih banyak donasi di hari-hari terakhir.
        $daysAgo = (int) floor(pow(mt_rand() / mt_getrandmax(), 1.8) * 364);
        $when = now()->subDays($daysAgo)->setTime(random_int(6, 22), random_int(0, 59), random_int(0, 59));
        if ($when->isFuture()) {
            $when = now()->subMinutes(random_int(5, 600));
        }
        $stamp = $when->toDateTimeString();

        return [
            'reference' => 'SDQ-' . $when->format('ymd') . '-' . Str::upper(Str::random(6)),
            'user_id' => $user->id,
            'campaign_id' => $campaignId,
            'amount' => $amount,
            'payment_method' => $method,
            'payment_provider_id' => $provider?->id,
            'status' => 'success',
            'donor_name' => $anonymous ? 'Hamba Allah' : $user->name,
            'is_anonymous' => $anonymous,
            'paid_at' => $stamp,
            'created_at' => $stamp,
            'updated_at' => $stamp,
        ];
    }
}