<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** Nama key mengikuti DonationModel.fromJson di Flutter. */
class DonationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'reference' => $this->reference,
            'campaign_id' => $this->campaign_id,
            'campaign_title' => $this->campaign?->title,
            'category' => $this->campaign?->category?->slug,
            'amount' => $this->amount,
            'payment_method' => $this->payment_method,
            'payment_provider' => $this->paymentProvider?->name,
            'status' => $this->status,
            'created_at' => $this->created_at?->toIso8601String(),
            'donor_name' => $this->donor_name,
            'user_id' => $this->user_id,
        ];
    }
}
