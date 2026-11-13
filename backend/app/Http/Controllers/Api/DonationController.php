<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DonationResource;
use App\Models\ActivityLog;
use App\Models\Campaign;
use App\Models\Donation;
use App\Models\PaymentProvider;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class DonationController extends Controller
{
    private const MIN_AMOUNT = 5000; // zakat dikecualikan (nominal dari kalkulator)

    /** Riwayat donasi milik pengguna yang login. */
    public function index(Request $request): AnonymousResourceCollection
    {
        return DonationResource::collection(
            Donation::with(['campaign.category', 'paymentProvider'])
                ->where('user_id', $request->user()->id)
                ->latest()
                ->get()
        );
    }

    /** Admin: semua transaksi (50 per halaman). */
    public function adminIndex(): AnonymousResourceCollection
    {
        return DonationResource::collection(
            Donation::with(['campaign.category', 'paymentProvider'])
                ->latest()
                ->paginate(50)
        );
    }

    /**
     * Buat donasi. Pembayaran masih SIMULASI: status langsung "success".
     * (Integrasi payment gateway, mis. Midtrans, bisa ditambahkan nanti pada method ini.)
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'campaign_id' => ['required', 'integer', 'exists:campaigns,id'],
            'amount' => ['required', 'integer', 'min:1', 'max:1000000000'],
            'payment_method' => ['required', 'in:qris,ewallet,transfer'],
            'payment_provider' => ['nullable', 'string', 'max:50'],
            'donor_name' => ['nullable', 'string', 'max:100'],
            'is_anonymous' => ['sometimes', 'boolean'],
        ]);

        // E-wallet dan transfer wajib memilih penyedia yang terdaftar.
        $providerId = null;
        if ($data['payment_method'] !== 'qris') {
            $type = $data['payment_method'] === 'ewallet' ? 'ewallet' : 'bank';
            $provider = PaymentProvider::where('type', $type)
                ->where('name', $data['payment_provider'] ?? '')
                ->where('is_active', true)
                ->first();

            if (!$provider) {
                throw ValidationException::withMessages([
                    'payment_provider' => 'Penyedia pembayaran tidak valid.',
                ]);
            }
            $providerId = $provider->id;
        }

        $donorName = trim((string) ($data['donor_name'] ?? ''));
        $anonymous = (bool) ($data['is_anonymous'] ?? false);
        if ($anonymous || $donorName === '') {
            $donorName = 'Hamba Allah';
        }

        $user = $request->user();

        $donation = DB::transaction(function () use ($data, $providerId, $donorName, $anonymous, $user) {
            // Kunci baris program agar dua donasi bersamaan tidak merusak total dana dan slot.
            $campaign = Campaign::with('category')
                ->whereKey($data['campaign_id'])
                ->lockForUpdate()
                ->firstOrFail();

            if ($campaign->status !== Campaign::STATUS_ACTIVE) {
                abort(422, 'Program ini tidak sedang menerima donasi.');
            }
            if ($campaign->deadline->isPast()) {
                abort(422, 'Program ini sudah berakhir.');
            }

            $amount = (int) $data['amount'];
            $isZakat = $campaign->category?->slug === 'zakat';
            if (!$isZakat && $amount < self::MIN_AMOUNT) {
                abort(422, 'Minimal transaksi Rp ' . number_format(self::MIN_AMOUNT, 0, ',', '.'));
            }

            $units = 0;
            if ($campaign->unit_price) {
                if ($amount % $campaign->unit_price !== 0) {
                    abort(422, "Nominal harus kelipatan harga per {$campaign->unit_label}.");
                }
                $units = intdiv($amount, $campaign->unit_price);
            }

            if ($campaign->slot_total !== null) {
                $left = max(0, $campaign->slot_total - (int) $campaign->slot_filled);
                if ($units > $left) {
                    abort(422, $left === 0 ? 'Slot sudah penuh.' : "Sisa slot hanya {$left}.");
                }
                $campaign->slot_filled = (int) $campaign->slot_filled + $units;
            }

            $campaign->collected_amount += $amount;
            $campaign->save();

            return Donation::create([
                'reference' => 'SDQ-' . now()->format('ymd') . '-' . strtoupper(Str::random(6)),
                'user_id' => $user->id,
                'campaign_id' => $campaign->id,
                'amount' => $amount,
                'payment_method' => $data['payment_method'],
                'payment_provider_id' => $providerId,
                'status' => 'success',
                'donor_name' => $donorName,
                'is_anonymous' => $anonymous,
                'paid_at' => now(),
            ]);
        });

        $donation->load(['campaign.category', 'paymentProvider']);

        ActivityLog::record(
            'donation',
            "Donasi Rp " . number_format($donation->amount, 0, ',', '.') . " untuk {$donation->campaign->title}",
            $user
        );

        return (new DonationResource($donation))->response()->setStatusCode(201);
    }
}
