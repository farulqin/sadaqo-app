<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CommunityPoll extends Model
{
    protected $fillable = ['post_id', 'question', 'ends_at'];

    protected function casts(): array
    {
        return ['ends_at' => 'datetime'];
    }

    public function post(): BelongsTo
    {
        return $this->belongsTo(CommunityPost::class, 'post_id');
    }

    public function options(): HasMany
    {
        return $this->hasMany(CommunityPollOption::class, 'poll_id')->orderBy('sort_order');
    }
}