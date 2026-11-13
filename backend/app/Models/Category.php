<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Category extends Model
{
    protected $fillable = [
        'slug',
        'label',
        'short_label',
        'icon_asset_id',
        'color_start',
        'color_end',
        'sort_order',
    ];

    public function iconAsset(): BelongsTo
    {
        return $this->belongsTo(Asset::class, 'icon_asset_id');
    }

    public function campaigns(): HasMany
    {
        return $this->hasMany(Campaign::class);
    }
}
