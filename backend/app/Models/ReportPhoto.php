<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReportPhoto extends Model
{
    protected $fillable = ['campaign_report_id', 'asset_id', 'type'];

    public function report(): BelongsTo
    {
        return $this->belongsTo(CampaignReport::class, 'campaign_report_id');
    }

    public function asset(): BelongsTo
    {
        return $this->belongsTo(Asset::class);
    }
}
