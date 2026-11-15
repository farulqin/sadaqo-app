<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ReportResource;
use App\Models\ActivityLog;
use App\Models\AppNotification;
use App\Models\Campaign;
use App\Models\CampaignReport;
use App\Models\Donation;
use App\Models\ReportPhoto;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class ReportController extends Controller
{
    private const WITH = ['campaign.category', 'manager', 'photos.asset'];

    /** Publik: hanya laporan yang sudah disetujui. Filter opsional: ?campaign_id=1 */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = CampaignReport::with(self::WITH)
            ->where('status', 'approved')
            ->orderByDesc('published_at');

        if ($campaignId = $request->query('campaign_id')) {
            $query->where('campaign_id', $campaignId);
        }

        return ReportResource::collection($query->get());
    }

    public function show(Request $request, CampaignReport $report): ReportResource
    {
        if ($report->status !== 'approved') {
            $user = $request->user('sanctum');
            $allowed = $user && ($user->isAdmin() || $report->manager_id === $user->id);
            abort_unless($allowed, 404, 'Laporan tidak ditemukan.');
        }

        return new ReportResource($report->load(self::WITH));
    }

    /** Pengelola: laporan miliknya (semua status). */
    public function mine(Request $request): AnonymousResourceCollection
    {
        return ReportResource::collection(
            CampaignReport::with(self::WITH)
                ->where('manager_id', $request->user()->id)
                ->latest()
                ->get()
        );
    }

    /** Admin: semua laporan, filter ?status=pending. */
    public function adminIndex(Request $request): AnonymousResourceCollection
    {
        $query = CampaignReport::with(self::WITH)->latest();

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        return ReportResource::collection($query->get());
    }

    /** Pengelola (programnya sendiri) atau admin membuat laporan. Status awal: pending. */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = $request->validate([
            'campaign_id' => ['required', 'integer', 'exists:campaigns,id'],
            'title' => ['required', 'string', 'min:5', 'max:150'],
            'summary' => ['required', 'string', 'min:20', 'max:3000'],
            'distributed_amount' => ['required', 'integer', 'min:0', 'max:10000000000'],
            'beneficiaries' => ['required', 'integer', 'min:0', 'max:10000000'],
            'activity_date' => ['required', 'date', 'before_or_equal:today'],
            'activity_photo_ids' => ['required', 'array', 'min:1', 'max:10'],
            'activity_photo_ids.*' => ['integer', 'exists:assets,id'],
            'proof_photo_ids' => ['nullable', 'array', 'max:10'],
            'proof_photo_ids.*' => ['integer', 'exists:assets,id'],
        ], [
            'activity_photo_ids.required' => 'Tambahkan minimal satu foto kegiatan.',
            'activity_date.before_or_equal' => 'Tanggal kegiatan tidak boleh di masa depan.',
        ]);

        $campaign = Campaign::findOrFail($data['campaign_id']);

        if (!$user->isAdmin() && $campaign->owner_id !== $user->id) {
            return response()->json(['message' => 'Kamu hanya bisa melapor untuk programmu sendiri.'], 403);
        }
        if (!in_array($campaign->status, [Campaign::STATUS_ACTIVE, Campaign::STATUS_CLOSED], true)) {
            return response()->json(['message' => 'Program belum aktif, belum bisa dibuatkan laporan.'], 422);
        }

        $this->assertWithinCollected($campaign, (int) $data['distributed_amount'], null);

        $report = DB::transaction(function () use ($data, $campaign, $user) {
            $report = CampaignReport::create([
                'campaign_id' => $campaign->id,
                'manager_id' => $user->id,
                'title' => trim($data['title']),
                'summary' => trim($data['summary']),
                'distributed_amount' => $data['distributed_amount'],
                'beneficiaries' => $data['beneficiaries'],
                'activity_date' => $data['activity_date'],
                'status' => 'pending',
            ]);
            $this->attachPhotos($report, 'activity', $data['activity_photo_ids']);
            $this->attachPhotos($report, 'proof', $data['proof_photo_ids'] ?? []);

            return $report;
        });

        ActivityLog::record('verified', "Laporan penyaluran baru dari {$user->name}: {$report->title}", $user);

        return (new ReportResource($report->load(self::WITH)))->response()->setStatusCode(201);
    }

    /**
     * Pengelola memperbaiki laporannya (hanya saat pending atau perlu revisi) dan
     * mengajukan ulang. Admin boleh mengubah apa saja.
     */
    public function update(Request $request, CampaignReport $report): JsonResponse|ReportResource
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            $editable = $report->manager_id === $user->id
                && in_array($report->status, ['pending', 'revision'], true);
            if (!$editable) {
                return response()->json(['message' => 'Laporan ini tidak dapat diubah.'], 403);
            }
        }

        $data = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'min:5', 'max:150'],
            'summary' => ['sometimes', 'required', 'string', 'min:20', 'max:3000'],
            'distributed_amount' => ['sometimes', 'required', 'integer', 'min:0', 'max:10000000000'],
            'beneficiaries' => ['sometimes', 'required', 'integer', 'min:0', 'max:10000000'],
            'activity_date' => ['sometimes', 'required', 'date', 'before_or_equal:today'],
            'activity_photo_ids' => ['sometimes', 'array', 'min:1', 'max:10'],
            'activity_photo_ids.*' => ['integer', 'exists:assets,id'],
            'proof_photo_ids' => ['sometimes', 'nullable', 'array', 'max:10'],
            'proof_photo_ids.*' => ['integer', 'exists:assets,id'],
        ]);

        if (isset($data['distributed_amount'])) {
            $this->assertWithinCollected($report->campaign, (int) $data['distributed_amount'], $report->id);
        }

        DB::transaction(function () use ($report, $data, $user) {
            $fields = collect($data)
                ->except(['activity_photo_ids', 'proof_photo_ids'])
                ->all();

            // Diperbaiki pengelola -> diajukan ulang untuk diperiksa admin.
            if (!$user->isAdmin()) {
                $fields += [
                    'status' => 'pending',
                    'admin_note' => null,
                    'reviewed_by' => null,
                    'reviewed_at' => null,
                    'published_at' => null,
                ];
            }
            $report->update($fields);

            if (array_key_exists('activity_photo_ids', $data)) {
                $report->photos()->where('type', 'activity')->delete();
                $this->attachPhotos($report, 'activity', $data['activity_photo_ids']);
            }
            if (array_key_exists('proof_photo_ids', $data)) {
                $report->photos()->where('type', 'proof')->delete();
                $this->attachPhotos($report, 'proof', $data['proof_photo_ids'] ?? []);
            }
        });

        ActivityLog::record('verified', "{$user->name} memperbaiki laporan: {$report->title}", $user);

        return new ReportResource($report->load(self::WITH));
    }

    /**
     * Admin: setujui atau minta revisi. Body: { decision: approve|revision, note }.
     * Disetujui -> terbit dan semua donatur program itu diberi notifikasi.
     */
    public function review(Request $request, CampaignReport $report): ReportResource
    {
        $data = $request->validate([
            'decision' => ['required', 'in:approve,revision'],
            'note' => ['nullable', 'string', 'max:1000', 'required_if:decision,revision'],
        ], [
            'note.required_if' => 'Catatan revisi wajib diisi',
        ]);

        $approve = $data['decision'] === 'approve';

        $report->update([
            'status' => $approve ? 'approved' : 'revision',
            'admin_note' => $approve ? null : $data['note'],
            'reviewed_by' => $request->user()->id,
            'reviewed_at' => now(),
            'published_at' => $approve ? now() : null,
        ]);
        $report->load(self::WITH);

        ActivityLog::record(
            'verified',
            ($approve ? 'Laporan disetujui: ' : 'Laporan diminta revisi: ') . $report->title,
            $request->user()
        );

        $programTitle = $report->campaign?->title ?? 'program';

        if ($approve) {
            $donorIds = Donation::where('campaign_id', $report->campaign_id)
                ->where('status', 'success')
                ->whereNotNull('user_id')
                ->distinct()
                ->pluck('user_id');

            $now = now();
            $rows = $donorIds->map(fn ($id) => [
                'user_id' => $id,
                'title' => 'Laporan penyaluran baru',
                'body' => "Dana program \"{$programTitle}\" sudah disalurkan. Lihat laporannya di Riwayat.",
                'is_read' => false,
                'created_at' => $now,
                'updated_at' => $now,
            ])->all();
            foreach (array_chunk($rows, 500) as $chunk) {
                AppNotification::insert($chunk);
            }
        }

        if ($report->manager_id) {
            AppNotification::create([
                'user_id' => $report->manager_id,
                'title' => $approve ? 'Laporan disetujui' : 'Laporan perlu revisi',
                'body' => $approve
                    ? "Laporan \"{$report->title}\" sudah terbit dan dilihat donatur."
                    : "Laporan \"{$report->title}\" perlu revisi. Catatan: " . ($data['note'] ?? '-'),
            ]);
        }

        return new ReportResource($report);
    }

    private function attachPhotos(CampaignReport $report, string $type, array $assetIds): void
    {
        $now = now();
        $rows = collect($assetIds)->unique()->map(fn ($id) => [
            'campaign_report_id' => $report->id,
            'asset_id' => $id,
            'type' => $type,
            'created_at' => $now,
            'updated_at' => $now,
        ])->values()->all();

        if ($rows) {
            ReportPhoto::insert($rows);
        }
    }

    /** Total dana yang dilaporkan (selain yang diminta revisi) tidak boleh melebihi dana terkumpul. */
    private function assertWithinCollected(Campaign $campaign, int $amount, ?int $exceptReportId): void
    {
        $already = (int) CampaignReport::where('campaign_id', $campaign->id)
            ->where('status', '!=', 'revision')
            ->when($exceptReportId, fn ($q) => $q->where('id', '!=', $exceptReportId))
            ->sum('distributed_amount');

        if ($already + $amount > (int) $campaign->collected_amount) {
            $left = max(0, (int) $campaign->collected_amount - $already);
            throw ValidationException::withMessages([
                'distributed_amount' => 'Dana yang dilaporkan melebihi dana terkumpul. Sisa yang bisa dilaporkan: Rp ' . number_format($left, 0, ',', '.'),
            ]);
        }
    }
}