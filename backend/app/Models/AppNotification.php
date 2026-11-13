<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppNotification extends Model
{
    protected $fillable = ['user_id', 'title', 'body', 'is_read'];

    protected function casts(): array
    {
        return ['is_read' => 'boolean'];
    }
}
