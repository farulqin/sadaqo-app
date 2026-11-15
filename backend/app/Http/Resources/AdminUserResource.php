<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Carbon;

/** Data pengguna untuk dashboard admin (termasuk status moderasi dan total donasi). */
class AdminUserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'role' => $this->role,
            'avatar' => $this->avatarAsset?->ref,
            'avatar_asset_id' => $this->avatar_asset_id,
            'joined_at' => $this->created_at?->toIso8601String(),
            'strikes' => (int) $this->strikes,
            'banned_until' => $this->banned_until
                ? Carbon::parse($this->banned_until)->toIso8601String()
                : null,
            'is_active' => (bool) $this->is_active,
            'donations_total' => (int) ($this->donations_total ?? 0),
            'donations_count' => (int) ($this->donations_count ?? 0),
        ];
    }
}