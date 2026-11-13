<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AssetResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'path' => $this->path,
            'file_name' => $this->file_name,
            'group' => $this->group,
            'source' => $this->source,
            'url' => $this->url,   // null untuk aset bawaan aplikasi
            'ref' => $this->ref,   // nilai yang dipakai Flutter (path asset atau URL)
            'mime_type' => $this->mime_type,
            'size_bytes' => $this->size_bytes,
            'width' => $this->width,
            'height' => $this->height,
            'alt_text' => $this->alt_text,
            'uploaded_by' => $this->uploaded_by,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
