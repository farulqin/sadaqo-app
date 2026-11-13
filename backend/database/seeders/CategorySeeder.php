<?php

namespace Database\Seeders;

use App\Models\Asset;
use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        // Sama dengan enum ProgramCategory di Flutter (urutan = urutan tampil di beranda).
        $items = [
            ['masjid', 'Masjid & Mushola', 'Masjid', '#1F3D2B', '#4E7D5B', 'ikon_masjid.png'],
            ['sosial', 'Bantuan Sosial', 'Sosial', '#2E5E3E', '#7FB08A', 'ikon_sosial.png'],
            ['zakat', 'Zakat', 'Zakat', '#8A6D1F', '#D9B84A', 'ikon_zakat.png'],
            ['duafa', 'Kaum Duafa', 'Duafa', '#3A6B47', '#A3D65C', 'ikon_duafa.png'],
            ['qurban', 'Qurban Bersama', 'Qurban', '#6B5B3A', '#C9B98A', 'ikon_qurban.png'],
        ];

        foreach ($items as $i => [$slug, $label, $short, $start, $end, $icon]) {
            Category::updateOrCreate(['slug' => $slug], [
                'label' => $label,
                'short_label' => $short,
                'icon_asset_id' => Asset::where('path', "assets/icons/{$icon}")->value('id'),
                'color_start' => $start,
                'color_end' => $end,
                'sort_order' => $i + 1,
            ]);
        }
    }
}
