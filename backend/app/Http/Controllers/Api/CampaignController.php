<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CampaignResource;
use App\Models\ActivityLog;
use App\Models\AppNotification;
use App\Models\Campaign;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Carbon;
use Illuminate\Validation\ValidationException;

class CampaignController extends Controller
{
    private const WITH = ['category', 'imageAsset'];

    /** Publik: hanya program aktif. Filter opsional: ?category=masjid&q=banjir */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Campaign::active()->with(self::WITH)->orderBy('id');

        if ($slug = $request->query('category')) {
            $query->whereHas('category', fn ($c) => $c->where('slug', $slug));
        }

        $search = trim((string) $request->query('q', ''));
        if ($search !== '') {
            $query->where(function ($w) use ($search) {
                $w->where('title', 'like', "%{$search}%")
                    ->orWhere('location', 'like', "%{$search}%");
            });
        }

        return CampaignResource::collection($query->get());
    }

    public function show(Request $request, Campaign $campaign): CampaignResource
    {
        if ($campaign->status !== Campaign::STATUS_ACTIVE) {
            $user = $request->user('sanctum');
            $allowed = $user && ($user->isAdmin() || $campaign->owner_id === $user->id);
            abort_unless($allowed, 404, 'Program tidak ditemukan.');
        }

        return new CampaignResource($campaign->load(self::WITH));
    }

    /** Pengelola: program miliknya (semua status). */
    public function mine(Request $request): AnonymousResourceCollection
    {
        return CampaignResource::collection(
            Campaign::with(self::WITH)
                ->where('owner_id', $request->user()->id)
                ->latest()
                ->get()
        );
    }

    /** Admin: semua program, filter ?status=pending. */
    public function adminIndex(Request $request): AnonymousResourceCollection
    {
        $query = Campaign::with(self::WITH)->latest();

        if ($status = $request->query('status')) {
            $query->where('status', $status);
        }

        return CampaignResource::collection($query->get());
    }

    /**
     * Admin langsung aktif; pengelola masuk antrean verifikasi (status pending).
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = $request->validate([
            'title' => ['required', 'string', 'min:5', 'max:150'],
            'category' => ['required', 'string', 'exists:categories,slug'],
            'description' => ['required', 'string', 'min:20', 'max:5000'],
            'location' => ['required', 'string', 'max:150'],
            'sub_type' => ['nullable', 'string', 'max:60'],
            'target_amount' => ['required', 'integer', 'min:100000', 'max:10000000000'],
            'deadline' => ['nullable', 'date', 'after:now'],
            'duration_days' => ['nullable', 'integer', 'min:1', 'max:730'],
            'unit_price' => ['nullable', 'integer', 'min:1000'],
            'unit_label' => ['nullable', 'string', 'max:20'],
            'slot_total' => ['nullable', 'integer', 'min:1', 'max:1000'],
            'image_asset_id' => ['nullable', 'integer', 'exists:assets,id'],
            'supporting_info' => ['nullable', 'string', 'max:2000'],
        ]);

        if (empty($data['deadline']) && empty($data['duration_days'])) {
            throw ValidationException::withMessages([
                'deadline' => 'Isi tanggal berakhir atau durasi program (hari).',
            ]);
        }

        $deadline = !empty($data['deadline'])
            ? Carbon::parse($data['deadline'])
            : now()->addDays((int) $data['duration_days']);

        $isAdmin = $user->isAdmin();

        $campaign = Campaign::create([
            'category_id' => Category::where('slug', $data['category'])->value('id'),
            'owner_id' => $user->id,
            'title' => trim($data['title']),
            'description' => trim($data['description']),
            'sub_type' => $data['sub_type'] ?? null,
            'location' => trim($data['location']),
            'target_amount' => $data['target_amount'],
            'collected_amount' => 0,
            'deadline' => $deadline,
            'unit_price' => $data['unit_price'] ?? null,
            'unit_label' => $data['unit_label'] ?? null,
            'slot_total' => $data['slot_total'] ?? null,
            'slot_filled' => isset($data['slot_total']) ? 0 : null,
            'image_asset_id' => $data['image_asset_id'] ?? null,
            'supporting_info' => $data['supporting_info'] ?? null,
            'status' => $isAdmin ? Campaign::STATUS_ACTIVE : Campaign::STATUS_PENDING,
            'reviewed_by' => $isAdmin ? $user->id : null,
            'reviewed_at' => $isAdmin ? now() : null,
        ]);

        ActivityLog::record(
            $isAdmin ? 'content' : 'verified',
            $isAdmin
                ? "Admin menambahkan program: {$campaign->title}"
                : "Pengajuan program baru dari {$user->name}: {$campaign->title}",
            $user
        );

        return (new CampaignResource($campaign->load(self::WITH)))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Admin: ubah apa saja (termasuk status active/closed).
     * Pengelola: hanya program miliknya yang masih pending atau ditolak.
     */
    public function update(Request $request, Campaign $campaign): JsonResponse|CampaignResource
    {
        $user = $request->user();

        if (!$user->isAdmin()) {
            $editable = $campaign->owner_id === $user->id
                && in_array($campaign->status, [Campaign::STATUS_PENDING, Campaign::STATUS_REJECTED], true);

            if (!$editable) {
                return response()->json(['message' => 'Program ini tidak dapat diubah.'], 403);
            }
        }

        $rules = [
            'title' => ['sometimes', 'required', 'string', 'min:5', 'max:150'],
            'category' => ['sometimes', 'required', 'string', 'exists:categories,slug'],
            'description' => ['sometimes', 'required', 'string', 'min:20', 'max:5000'],
            'location' => ['sometimes', 'required', 'string', 'max:150'],
            'sub_type' => ['sometimes', 'nullable', 'string', 'max:60'],
            'target_amount' => ['sometimes', 'required', 'integer', 'min:100000', 'max:10000000000'],
            'deadline' => ['sometimes', 'required', 'date'],
            'unit_price' => ['sometimes', 'nullable', 'integer', 'min:1000'],
            'unit_label' => ['sometimes', 'nullable', 'string', 'max:20'],
            'slot_total' => ['sometimes', 'nullable', 'integer', 'min:1', 'max:1000'],
            'image_asset_id' => ['sometimes', 'nullable', 'integer', 'exists:assets,id'],
            'supporting_info' => ['sometimes', 'nullable', 'string', 'max:2000'],
        ];
        if ($user->isAdmin()) {
            $rules['status'] = ['sometimes', 'in:active,closed'];
        }

        $data = $request->validate($rules);

        if (isset($data['category'])) {
            $data['category_id'] = Category::where('slug', $data['category'])->value('id');
            unset($data['category']);
        }

        // Pengelola memperbaiki program yang ditolak -> diajukan ulang.
        if (!$user->isAdmin() && $campaign->status === Campaign::STATUS_REJECTED) {
            $data['status'] = Campaign::STATUS_PENDING;
            $data['review_note'] = null;
        }

        $campaign->update($data);
        ActivityLog::record('content', "{$user->name} mengubah program: {$campaign->title}", $user);

        return new CampaignResource($campaign->load(self::WITH));
    }

    /** Admin: setujui atau tolak pengajuan. Body: { decision: approve|reject, note } */
    public function review(Request $request, Campaign $campaign): CampaignResource
    {
        $data = $request->validate([
            'decision' => ['required', 'in:approve,reject'],
            'note' => ['nullable', 'string', 'max:1000', 'required_if:decision,reject'],
        ], [
            'note.required_if' => 'Alasan penolakan wajib diisi',
        ]);

        $approve = $data['decision'] === 'approve';

        $campaign->update([
            'status' => $approve ? Campaign::STATUS_ACTIVE : Campaign::STATUS_REJECTED,
            'review_note' => $data['note'] ?? null,
            'reviewed_by' => $request->user()->id,
            'reviewed_at' => now(),
        ]);

        ActivityLog::record(
            'verified',
            ($approve ? 'Program disetujui: ' : 'Program ditolak: ') . $campaign->title,
            $request->user()
        );

        if ($campaign->owner_id) {
            AppNotification::create([
                'user_id' => $campaign->owner_id,
                'title' => $approve ? 'Program disetujui' : 'Program ditolak',
                'body' => $approve
                    ? "Program \"{$campaign->title}\" sudah tampil di aplikasi."
                    : "Program \"{$campaign->title}\" ditolak. Alasan: " . ($data['note'] ?? '-'),
            ]);
        }

        return new CampaignResource($campaign->load(self::WITH));
    }

    public function destroy(Request $request, Campaign $campaign): JsonResponse
    {
        if ($campaign->donations()->exists()) {
            return response()->json([
                'message' => 'Program sudah memiliki donasi dan tidak bisa dihapus. Tutup program saja.',
            ], 409);
        }

        $title = $campaign->title;
        $campaign->delete();
        ActivityLog::record('content', "Admin menghapus program: {$title}", $request->user());

        return response()->json(['message' => 'Program dihapus']);
    }
}
