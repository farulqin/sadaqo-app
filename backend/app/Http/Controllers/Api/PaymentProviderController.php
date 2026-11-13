<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PaymentProvider;
use Illuminate\Http\JsonResponse;

class PaymentProviderController extends Controller
{
    /** Daftar penyedia pembayaran: { ewallets: [...], banks: [...] }. */
    public function index(): JsonResponse
    {
        $providers = PaymentProvider::where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        return response()->json([
            'data' => [
                'ewallets' => $providers->where('type', 'ewallet')->pluck('name')->values(),
                'banks' => $providers->where('type', 'bank')->pluck('name')->values(),
            ],
        ]);
    }
}
