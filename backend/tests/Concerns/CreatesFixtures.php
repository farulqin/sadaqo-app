<?php

namespace Tests\Concerns;

use App\Models\Campaign;
use App\Models\Category;
use App\Models\PaymentProvider;
use Illuminate\Support\Facades\DB;

/** Data contoh yang dipakai bersama oleh beberapa tes. */
trait CreatesFixtures
{
    protected function category(string $slug = 'sosial'): Category
    {
        return Category::firstOrCreate(['slug' => $slug], [
            'label' => ucfirst($slug),
            'short_label' => ucfirst($slug),
            'color_start' => '#1F3D2B',
            'color_end' => '#7FB03A',
            'sort_order' => 1,
        ]);
    }

    protected function campaign(array $attrs = []): Campaign
    {
        return Campaign::create(array_merge([
            'category_id' => $this->category()->id,
            'title' => 'Bantuan Sembako Warga',
            'description' => 'Deskripsi program untuk pengujian otomatis.',
            'location' => 'Semarang',
            'target_amount' => 10_000_000,
            'collected_amount' => 0,
            'deadline' => now()->addDays(30),
            'status' => Campaign::STATUS_ACTIVE,
        ], $attrs));
    }

    protected function provider(string $type = 'ewallet', string $name = 'GoPay'): PaymentProvider
    {
        return PaymentProvider::create(['type' => $type, 'name' => $name, 'is_active' => true, 'sort_order' => 1]);
    }

    protected function makePost(int $userId, string $body = 'Halo semua anggota komunitas'): int
    {
        return DB::table('community_posts')->insertGetId([
            'user_id' => $userId,
            'category' => 'diskusi',
            'body' => $body,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}