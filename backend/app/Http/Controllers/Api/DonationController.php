<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DonationResource;
use App\Models\ActivityLog;
use App\Models\AppNotification;
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

    /** Admin: transaksi sukses untuk statistik (default 365 hari terakhir, maksimal 5000). */
    public function adminTransactions(Request $request): AnonymousResourceCollection
    {
        $days = min(max((int) $request->query('days', 365), 1), 1100);

        return DonationResource::collection(
            Donation::with(['campaign.category', 'paymentProvider'])
                ->where('status', 'success')
                ->where('created_at', '>=', now()->subDays($days))
                ->latest()
                ->limit(5000)
                ->get()
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
        $closedCampaign = null;

        $donation = DB::transaction(function () use ($data, $providerId, $donorName, $anonymous, $user, &$closedCampaign) {
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

            // Program ditutup otomatis saat target tercapai (kecuali zakat, yang berjalan
            // terus) atau saat semua slot terisi. Donasi yang melewati target tetap diterima.
            $reachedTarget = !$isZakat && $campaign->collected_amount >= $campaign->target_amount;
            $slotsFull = $campaign->slot_total !== null
                && (int) $campaign->slot_filled >= (int) $campaign->slot_total;
            if ($reachedTarget || $slotsFull) {
                $campaign->status = Campaign::STATUS_CLOSED;
                $closedCampaign = $campaign;
            }
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

        if ($closedCampaign) {
            ActivityLog::record(
                'content',
                "Program otomatis ditutup (target/slot tercapai): {$closedCampaign->title}",
                $user
            );
            if ($closedCampaign->owner_id) {
                AppNotification::create([
                    'user_id' => $closedCampaign->owner_id,
                    'title' => 'Program mencapai target',
                    'body' => "Program \"{$closedCampaign->title}\" sudah mencapai target dan ditutup otomatis. Segera susun laporan penyalurannya.",
                ]);
            }
        }

        $rupiah = 'Rp ' . number_format($donation->amount, 0, ',', '.');

        AppNotification::create([
            'user_id' => $user->id,
            'title' => 'Alhamdulillah, donasimu berhasil',
            'body' => "Benih kebaikanmu sudah tertanam. Pembayaran {$rupiah} untuk \"{$donation->campaign->title}\" tercatat atas nama {$donation->donor_name}.",
            'type' => 'activity',
        ]);

        // Kabari pengelola program (bila donaturnya orang lain).
        $ownerId = $donation->campaign->owner_id;
        if ($ownerId && $ownerId !== $user->id) {
            AppNotification::create([
                'user_id' => $ownerId,
                'title' => 'Donasi baru masuk',
                'body' => "{$rupiah} untuk \"{$donation->campaign->title}\" dari {$donation->donor_name}.",
                'type' => 'activity',
            ]);
        }

        return (new DonationResource($donation))->response()->setStatusCode(201);
    }
}