<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class CommunityPost extends Model
{
    protected $fillable = ['user_id', 'category', 'body', 'image_asset_id', 'is_pinned', 'is_hidden'];

    protected function casts(): array
    {
        return ['is_pinned' => 'boolean', 'is_hidden' => 'boolean'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function imageAsset(): BelongsTo
    {
        return $this->belongsTo(Asset::class, 'image_asset_id');
    }

    public function poll(): HasOne
    {
        return $this->hasOne(CommunityPoll::class, 'post_id');
    }

    public function comments(): HasMany
    {
        return $this->hasMany(CommunityComment::class, 'post_id');
    }

    public function likes(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'community_post_likes', 'post_id', 'user_id')->withTimestamps();
    }
}