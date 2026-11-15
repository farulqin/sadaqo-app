<?php

namespace App\Console\Commands;

use App\Models\ActivityLog;
use App\Models\AppNotification;
use App\Models\Campaign;
use Illuminate\Console\Command;

class CloseExpiredCampaigns extends Command
{
    protected $signature = 'campaigns:close-expired';

    protected $description = 'Menutup program aktif yang sudah melewati batas waktu';

    public function handle(): int
    {
        $expired = Campaign::active()->where('deadline', '<', now())->get();

        foreach ($expired as $campaign) {
            $campaign->update(['status' => Campaign::STATUS_CLOSED]);

            ActivityLog::record('content', "Program otomatis ditutup (batas waktu berakhir): {$campaign->title}");

            if ($campaign->owner_id) {
                AppNotification::create([
                    'user_id' => $campaign->owner_id,
                    'title' => 'Program berakhir',
                    'body' => "Batas waktu program \"{$campaign->title}\" sudah lewat dan program ditutup. Segera susun laporan penyalurannya.",
                ]);
            }
        }

        $this->info("{$expired->count()} program ditutup.");

        return self::SUCCESS;
    }
}