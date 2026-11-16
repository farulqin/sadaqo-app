<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CommunityEvent;
use App\Support\CommunityGuard;
use App\Support\CommunityPresenter;
use App\Support\Notifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommunityEventController extends Controller
{
    private function base(Request $request)
    {
        $uid = $request->user()->id;

        return CommunityEvent::query()
            ->with(['creator', 'imageAsset'])
            ->withCount('interested')
            ->withExists(['interested as interested' => fn ($q) => $q->where('community_event_interests.user_id', $uid)]);
    }

    /** Agenda mendatang (dan yang baru lewat 1 hari), terdekat dulu. */
    public function index(Request $request): JsonResponse
    {
        $events = $this->base($request)
            ->where('starts_at', '>=', now()->subDay())
            ->orderBy('starts_at')
            ->limit(100)
            ->get();

        return response()->json([
            'data' => $events->map(fn ($e) => CommunityPresenter::event($e, $request->user()))->values(),
        ]);
    }

    /** Buat agenda (admin atau pengelola). Semua anggota diberi notifikasi. */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless(in_array($user->role, ['admin', 'pengelola'], true), 403, 'Hanya admin dan pengelola yang dapat membuat agenda.');

        $data = $this->validated($request, false);
        $event = CommunityEvent::create($data + ['created_by' => $user->id]);

        Notifier::toMany(
            array_values(array_diff(CommunityGuard::memberIds(), [$user->id])),
            'Agenda baru',
            $event->title,
            'activity', 'event', $event->id
        );

        return response()->json(['data' => CommunityPresenter::event($this->base($request)->findOrFail($event->id), $user)], 201);
    }

    public function update(Request $request, CommunityEvent $event): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'admin' || $event->created_by === $user->id, 403, 'Kamu tidak dapat mengubah agenda ini.');

        $event->update($this->validated($request, true));

        return response()->json(['data' => CommunityPresenter::event($this->base($request)->findOrFail($event->id), $user)]);
    }

    public function destroy(Request $request, CommunityEvent $event): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->role === 'admin' || $event->created_by === $user->id, 403, 'Kamu tidak dapat menghapus agenda ini.');
        $event->delete();

        return response()->json(['message' => 'Agenda dihapus']);
    }

    /** Tandai atau batalkan "Tertarik". */
    public function interest(Request $request, CommunityEvent $event): JsonResponse
    {
        $user = $request->user();
        CommunityGuard::assertCanParticipate($user);

        $changes = $event->interested()->toggle($user->id);

        return response()->json(['data' => [
            'interested' => count($changes['attached']) > 0,
            'interested_count' => $event->interested()->count(),
        ]]);
    }

    private function validated(Request $request, bool $partial): array
    {
        $req = $partial ? ['sometimes', 'required'] : ['required'];

        return $request->validate([
            'title' => [...$req, 'string', 'min:5', 'max:150'],
            'description' => ['sometimes', 'nullable', 'string', 'max:1000'],
            'location' => [...$req, 'string', 'max:150'],
            'is_online' => ['sometimes', 'boolean'],
            'starts_at' => [...$req, 'date'],
            'ends_at' => ['sometimes', 'nullable', 'date', 'after:starts_at'],
            'image_asset_id' => ['sometimes', 'nullable', 'integer', 'exists:assets,id'],
        ]);
    }
}