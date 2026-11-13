<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'gender' => $this->gender,
            'role' => $this->role,
            'is_admin' => $this->role === 'admin',
            'is_manager' => $this->role === 'pengelola',
            'avatar_asset_id' => $this->avatar_asset_id,
            'avatar' => $this->avatarAsset?->ref,
            'joined_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
