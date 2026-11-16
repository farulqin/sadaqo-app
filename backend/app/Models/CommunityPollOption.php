<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class CommunityPollOption extends Model
{
    protected $fillable = ['poll_id', 'label', 'sort_order'];

    public function voters(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'community_poll_votes', 'option_id', 'user_id');
    }
}