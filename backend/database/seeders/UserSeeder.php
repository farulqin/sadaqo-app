<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/**
 * Akun admin dan pengelola dibuat di sini (bukan lagi di kode Flutter).
 * Password dibaca dari backend/.env; jika kosong dibuat acak dan ditampilkan SEKALI di terminal.
 *
 *   SEED_ADMIN_PASSWORD=...
 *   SEED_PENGELOLA_PASSWORD=...
 *   SEED_DONATUR_PASSWORD=...
 */
class UserSeeder extends Seeder
{
    public function run(): void
    {
        $adminPassword = $this->password('SEED_ADMIN_PASSWORD', 'admin');
        $pengelolaPassword = $this->password('SEED_PENGELOLA_PASSWORD', 'pengelola');
        $donaturPassword = $this->password('SEED_DONATUR_PASSWORD', 'donatur demo');

        foreach (['sadaqo.admin@gmail.com', 'admin.amanahsdq@gmail.com'] as $email) {
            User::updateOrCreate(['email' => $email], [
                'name' => 'Admin SADAQO',
                'password' => $adminPassword,
                'role' => User::ROLE_ADMIN,
                'email_verified_at' => now(),
            ]);
        }

        User::updateOrCreate(['email' => 'sadaqo.pengelola@gmail.com'], [
            'name' => 'Pengelola SADAQO',
            'password' => $pengelolaPassword,
            'role' => User::ROLE_PENGELOLA,
            'email_verified_at' => now(),
        ]);

        User::updateOrCreate(['email' => 'donatur.demo@sadaqo.test'], [
            'name' => 'Farid Ulil Yaqin',
            'password' => $donaturPassword,
            'role' => User::ROLE_DONATUR,
            'email_verified_at' => now(),
        ]);
    }

    private function password(string $envKey, string $label): string
    {
        $value = env($envKey);

        if (!$value) {
            $value = Str::random(14);
            $this->command?->warn("{$envKey} belum diisi di .env. Password {$label} dibuat acak: {$value}");
        }

        return $value;
    }
}
