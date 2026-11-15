<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** Nama key mengikuti CampaignReport di Flutter. */
class ReportResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $photos = fn (string $type) => $this->photos
            ->where('type', $type)
            ->map(fn ($p) => $p->asset?->ref)
            ->filter()
            ->values();

        return [
            'id' => $this->id,
            'campaign_id' => $this->campaign_id,
            'campaign_title' => $this->campaign?->title,
            'category' => $this->campaign?->category?->slug,
            'manager_id' => $this->manager_id,
            'manager_name' => $this->manager?->name,
            'title' => $this->title,
            'summary' => $this->summary,
            'distributed_amount' => $this->distributed_amount,
            'beneficiaries' => $this->beneficiaries,
            'activity_date' => $this->activity_date?->toDateString(),
            'submitted_at' => $this->created_at?->toIso8601String(),
            'activity_photos' => $photos('activity'),
            'proof_photos' => $photos('proof'),
            'status' => $this->status,
            'admin_note' => $this->admin_note,
            'reviewed_at' => $this->reviewed_at?->toIso8601String(),
            'published_at' => $this->published_at?->toIso8601String(),
        ];
    }
}