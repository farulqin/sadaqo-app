<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Campaign extends Model
{
    public const STATUS_PENDING = 'pending';
    public const STATUS_ACTIVE = 'active';
    public const STATUS_REJECTED = 'rejected';
    public const STATUS_CLOSED = 'closed';

    protected $fillable = [
        'code',
        'category_id',
        'owner_id',
        'title',
        'description',
        'sub_type',
        'location',
        'target_amount',
        'collected_amount',
        'deadline',
        'unit_price',
        'unit_label',
        'slot_total',
        'slot_filled',
        'image_asset_id',
        'supporting_info',
        'status',
        'review_note',
        'reviewed_by',
        'reviewed_at',
    ];

    protected function casts(): array
    {
        return [
            'deadline' => 'datetime',
            'reviewed_at' => 'datetime',
            'target_amount' => 'integer',
            'collected_amount' => 'integer',
            'unit_price' => 'integer',
            'slot_total' => 'integer',
            'slot_filled' => 'integer',
        ];
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_ACTIVE);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function imageAsset(): BelongsTo
    {
        return $this->belongsTo(Asset::class, 'image_asset_id');
    }

    public function donations(): HasMany
    {
        return $this->hasMany(Donation::class);
    }
}
