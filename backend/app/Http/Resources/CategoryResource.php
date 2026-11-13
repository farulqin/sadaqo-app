<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'key' => $this->slug, // = ProgramCategory.key di Flutter
            'label' => $this->label,
            'short_label' => $this->short_label,
            'icon' => $this->iconAsset?->ref,
            'icon_asset_id' => $this->icon_asset_id,
            'color_start' => $this->color_start,
            'color_end' => $this->color_end,
            'sort_order' => $this->sort_order,
        ];
    }
}
