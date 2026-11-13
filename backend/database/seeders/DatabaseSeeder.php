<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /** Urutan penting: aset dulu, karena tabel lain menunjuk ke assets. */
    public function run(): void
    {
        $this->call([
            AssetSeeder::class,
            CategorySeeder::class,
            PaymentProviderSeeder::class,
            UserSeeder::class,
            CampaignSeeder::class,
            NewsSeeder::class,
        ]);
    }
}
