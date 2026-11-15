<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Campaign;
use App\Models\Favorite;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    /** Id program favorit milik pengguna. */
    public function index(Request $request): JsonResponse
    {
        return response()->json(['data' => $this->ids($request)]);
    }

    /** Tambah jika belum favorit, hapus jika sudah. Mengembalikan daftar terbaru. */
    public function toggle(Request $request, Campaign $campaign): JsonResponse
    {
        $userId = $request->user()->id;
        $existing = Favorite::where('user_id', $userId)->where('campaign_id', $campaign->id);

        if ($existing->exists()) {
            $existing->delete();
        } else {
            Favorite::create(['user_id' => $userId, 'campaign_id' => $campaign->id]);
        }

        return response()->json(['data' => $this->ids($request)]);
    }

    private function ids(Request $request): array
    {
        return Favorite::where('user_id', $request->user()->id)
            ->pluck('campaign_id')
            ->values()
            ->all();
    }
}