<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** Nama key mengikuti CampaignModel.fromJson di Flutter. */
class CampaignResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'code' => $this->code,
            'title' => $this->title,
            'description' => $this->description,
            'category' => $this->category?->slug,
            'category_label' => $this->category?->label,
            'target_amount' => $this->target_amount,
            'collected_amount' => $this->collected_amount,
            'deadline' => $this->deadline?->toIso8601String(),
            'location' => $this->location,
            'image' => $this->imageAsset?->ref,
            'image_asset_id' => $this->image_asset_id,
            'sub_type' => $this->sub_type,
            'unit_price' => $this->unit_price,
            'unit_label' => $this->unit_label,
            'slot_total' => $this->slot_total,
            'slot_filled' => $this->slot_filled,
            'status' => $this->status,
            'review_note' => $this->review_note,
            'supporting_info' => $this->supporting_info,
            'owner_id' => $this->owner_id,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
