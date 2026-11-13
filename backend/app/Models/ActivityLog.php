<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ActivityLog extends Model
{
    protected $fillable = ['user_id', 'kind', 'text'];

    /** Pintasan untuk mencatat aksi: ActivityLog::record('content', 'Admin menambah program ...', $user) */
    public static function record(string $kind, string $text, ?User $user = null): self
    {
        return static::create([
            'user_id' => $user?->id,
            'kind' => $kind,
            'text' => $text,
        ]);
    }
}
