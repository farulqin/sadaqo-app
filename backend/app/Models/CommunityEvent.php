<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class CommunityEvent extends Model
{
    protected $fillable = [
        'created_by', 'title', 'description', 'location', 'is_online',
        'starts_at', 'ends_at', 'image_asset_id',
    ];

    protected function casts(): array
    {
        return [
            'is_online' => 'boolean',
            'starts_at' => 'datetime',
            'ends_at' => 'datetime',
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function imageAsset(): BelongsTo
    {
        return $this->belongsTo(Asset::class, 'image_asset_id');
    }

    public function interested(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'community_event_interests', 'event_id', 'user_id');
    }
}