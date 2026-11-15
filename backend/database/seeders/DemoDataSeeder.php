<?php

namespace Database\Seeders;

use App\Models\Campaign;
use App\Models\Donation;
use App\Models\PaymentProvider;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/**
 * Data contoh untuk demo (donatur dan donasi 30 hari terakhir).
 * Jalankan setelah seeder utama:  php artisan db:seed --class=DemoDataSeeder
 * Aman dijalankan ulang: bila data demo sudah ada, tidak membuat duplikat.
 * Password donatur contoh = SEED_DONATUR_PASSWORD di .env.
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

    private const AMOUNTS = [5000, 10000, 20000, 25000, 50000, 100000, 100000, 250000, 500000];

    public function run(): void
    {
        if (User::where('email', 'siti.rahma@example.com')->exists() && Donation::count() >= 50) {
            $this->command?->info('Data demo sudah ada, dilewati.');
            return;
        }

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

        $campaigns = Campaign::active()->whereNull('unit_price')->get();
        $ewallets = PaymentProvider::where('type', 'ewallet')->where('is_active', true)->get();
        $banks = PaymentProvider::where('type', 'bank')->where('is_active', true)->get();

        if ($campaigns->isEmpty()) {
            $this->command?->warn('Belum ada program aktif. Jalankan seeder utama dulu.');
            return;
        }

        Donation::unguard();
        for ($i = 0; $i < 110; $i++) {
            $campaign = $campaigns->random();
            $user = $users->random();
            $anonymous = random_int(1, 100) <= 12;

            $method = ['qris', 'ewallet', 'ewallet', 'transfer'][random_int(0, 3)];
            $provider = match ($method) {
                'ewallet' => $ewallets->random(),
                'transfer' => $banks->random(),
                default => null,
            };

            // Lebih banyak donasi di hari-hari terakhir.
            $daysAgo = (int) floor(pow(mt_rand() / mt_getrandmax(), 1.6) * 30);
            $when = now()->subDays($daysAgo)->setTime(random_int(6, 22), random_int(0, 59), random_int(0, 59));

            Donation::create([
                'reference' => 'SDQ-' . $when->format('ymd') . '-' . Str::upper(Str::random(6)),
                'user_id' => $user->id,
                'campaign_id' => $campaign->id,
                'amount' => self::AMOUNTS[array_rand(self::AMOUNTS)],
                'payment_method' => $method,
                'payment_provider_id' => $provider?->id,
                'status' => 'success',
                'donor_name' => $anonymous ? 'Hamba Allah' : $user->name,
                'is_anonymous' => $anonymous,
                'paid_at' => $when,
                'created_at' => $when,
                'updated_at' => $when,
            ]);
        }
        Donation::reguard();

        $this->command?->info('Data demo dibuat: ' . $users->count() . ' donatur dan 110 donasi.');
    }
}