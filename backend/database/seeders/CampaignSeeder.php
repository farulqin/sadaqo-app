<?php

namespace Database\Seeders;

use App\Models\Asset;
use App\Models\Campaign;
use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;

/** 27 program contoh, diambil dari MockCampaignStore di Flutter (data/campaigns.json). */
class CampaignSeeder extends Seeder
{
    public function run(): void
    {
        $items = json_decode(
            File::get(database_path('seeders/data/campaigns.json')),
            true,
            512,
            JSON_THROW_ON_ERROR
        );

        $ownerId = User::where('role', User::ROLE_PENGELOLA)->value('id');
        $categories = Category::pluck('id', 'slug');

        foreach ($items as $i) {
            Campaign::updateOrCreate(['code' => $i['code']], [
                'category_id' => $categories[$i['category']],
                'owner_id' => $ownerId,
                'title' => $i['title'],
                'description' => $i['description'],
                'sub_type' => $i['sub_type'],
                'location' => $i['location'],
                'target_amount' => $i['target_amount'],
                'collected_amount' => $i['collected_amount'],
                'deadline' => now()->addDays($i['days']),
                'unit_price' => $i['unit_price'],
                'unit_label' => $i['unit_label'],
                'slot_total' => $i['slot_total'],
                'slot_filled' => $i['slot_filled'],
                'image_asset_id' => Asset::where('path', $i['image'])->value('id'),
                'status' => Campaign::STATUS_ACTIVE,
                'reviewed_by' => null,
                'reviewed_at' => now(),
            ]);
        }

        $this->command?->info(count($items) . ' program contoh dibuat.');
    }
}
