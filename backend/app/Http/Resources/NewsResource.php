<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** Nama key mengikuti NewsModel.fromJson di Flutter. */
class NewsResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'summary' => $this->summary,
            'content' => $this->content,
            'category' => $this->category?->slug,
            'author' => $this->author,
            'published_at' => $this->published_at?->toIso8601String(),
            'campaign_id' => $this->campaign_id,
            'image' => $this->imageAsset?->ref,
            'image_asset_id' => $this->image_asset_id,
        ];
    }
}
