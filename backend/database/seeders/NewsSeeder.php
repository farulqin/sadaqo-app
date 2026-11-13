<?php

namespace Database\Seeders;

use App\Models\Asset;
use App\Models\Campaign;
use App\Models\Category;
use App\Models\News;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;

/** 5 berita contoh, diambil dari NewsMockDataSource di Flutter (data/news.json). */
class NewsSeeder extends Seeder
{
    public function run(): void
    {
        $items = json_decode(
            File::get(database_path('seeders/data/news.json')),
            true,
            512,
            JSON_THROW_ON_ERROR
        );

        $categories = Category::pluck('id', 'slug');

        foreach ($items as $i) {
            News::updateOrCreate(['title' => $i['title']], [
                'category_id' => $categories[$i['category']],
                'campaign_id' => Campaign::where('code', $i['campaign_code'])->value('id'),
                'author' => $i['author'],
                'summary' => $i['summary'],
                'content' => $i['content'],
                'image_asset_id' => Asset::where('path', $i['image'])->value('id'),
                'published_at' => now()->subDays($i['days_ago']),
            ]);
        }

        $this->command?->info(count($items) . ' berita contoh dibuat.');
    }
}
