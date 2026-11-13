<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Asset extends Model
{
    public const SOURCE_BUNDLED = 'bundled';
    public const SOURCE_UPLOADED = 'uploaded';

    protected $fillable = [
        'path',
        'file_name',
        'group',
        'source',
        'mime_type',
        'size_bytes',
        'width',
        'height',
        'checksum',
        'alt_text',
        'uploaded_by',
    ];

    public function uploader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    /** URL penuh untuk gambar hasil unggahan; null untuk aset bawaan aplikasi. */
    public function getUrlAttribute(): ?string
    {
        return $this->source === self::SOURCE_UPLOADED ? asset('storage/' . $this->path) : null;
    }

    /**
     * Nilai yang dipakai Flutter pada field "image":
     * - aset bawaan  -> path 'assets/images/...' (dibaca Image.asset)
     * - hasil unggah -> URL penuh http://... (dibaca Image.network)
     */
    public function getRefAttribute(): string
    {
        return $this->url ?? $this->path;
    }

    /** Apakah gambar ini masih dipakai oleh tabel lain. */
    public function isInUse(): bool
    {
        return Campaign::where('image_asset_id', $this->id)->exists()
            || News::where('image_asset_id', $this->id)->exists()
            || Category::where('icon_asset_id', $this->id)->exists()
            || User::where('avatar_asset_id', $this->id)->exists()
            || ReportPhoto::where('asset_id', $this->id)->exists();
    }
}
