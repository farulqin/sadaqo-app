<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CommunityPoll;
use App\Models\CommunityPost;
use App\Support\BadgeService;
use App\Support\CommunityGuard;
use App\Support\CommunityPresenter;
use App\Support\Notifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CommunityPostController extends Controller
{
    private function base(Request $request)
    {
        $uid = $request->user()->id;

        return CommunityPost::query()
            ->where('is_hidden', false)
            ->with([
                'user.avatarAsset',
                'imageAsset',
                'poll.options' => fn ($q) => $q->withCount('voters'),
            ])
            ->withCount(['likes', 'comments' => fn ($q) => $q->where('is_hidden', false)])
            ->withExists(['likes as liked' => fn ($q) => $q->where('community_post_likes.user_id', $uid)]);
    }

    /** @param \Illuminate\Support\Collection<int, CommunityPost> $posts */
    private function presentMany(Request $request, $posts): array
    {
        $viewer = $request->user();
        $badges = BadgeService::forUsers($posts->pluck('user_id')->all());
        $pollIds = $posts->map(fn ($p) => $p->poll?->id)->filter()->values()->all();
        $myVotes = $pollIds
            ? DB::table('community_poll_votes')->where('user_id', $viewer->id)
                ->whereIn('poll_id', $pollIds)->pluck('option_id', 'poll_id')->all()
            : [];

        return $posts->map(fn ($p) => CommunityPresenter::post($p, $viewer, $badges, $myVotes))->values()->all();
    }

    /** Feed. Filter: ?filter=all|diskusi|polling|info&page=1 */
    public function index(Request $request): JsonResponse
    {
        CommunityController::touch($request->user());

        $query = $this->base($request);
        $filter = $request->query('filter', 'all');
        if (in_array($filter, ['diskusi', 'info'], true)) {
            $query->where('category', $filter);
        } elseif ($filter === 'polling') {
            $query->whereHas('poll');
        }

        $page = $query->orderByDesc('is_pinned')->orderByDesc('created_at')->orderByDesc('id')->paginate(15);

        return response()->json([
            'data' => $this->presentMany($request, collect($page->items())),
            'meta' => ['page' => $page->currentPage(), 'last_page' => $page->lastPage(), 'total' => $page->total()],
        ]);
    }

    public function show(Request $request, CommunityPost $post): JsonResponse
    {
        $found = $this->base($request)->findOrFail($post->id);

        return response()->json(['data' => $this->presentMany($request, collect([$found]))[0]]);
    }

    /** Buat post (diskusi/info), dengan foto dan polling opsional. */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = $request->validate([
            'category' => ['required', 'in:diskusi,info'],
            'body' => ['required', 'string', 'min:3', 'max:1000'],
            'image_asset_id' => ['nullable', 'integer', 'exists:assets,id'],
            'poll' => ['nullable', 'array'],
            'poll.question' => ['required_with:poll', 'string', 'min:5', 'max:200'],
            'poll.options' => ['required_with:poll', 'array', 'min:2', 'max:6'],
            'poll.options.*' => ['required', 'string', 'min:1', 'max:100'],
            'poll.days' => ['nullable', 'integer', 'min:1', 'max:30'],
        ], [
            'poll.options.min' => 'Polling minimal punya 2 pilihan.',
        ]);

        CommunityGuard::assertCanParticipate($user);

        if ($data['category'] === 'info' && !in_array($user->role, ['admin', 'pengelola'], true)) {
            return response()->json(['message' => 'Kategori Info hanya untuk admin dan pengelola.'], 403);
        }

        $texts = [$data['body']];
        if (!empty($data['poll'])) {
            $texts[] = $data['poll']['question'];
            array_push($texts, ...$data['poll']['options']);
        }
        CommunityGuard::screen($user, $texts);

        $post = DB::transaction(function () use ($data, $user) {
            $post = CommunityPost::create([
                'user_id' => $user->id,
                'category' => $data['category'],
                'body' => trim($data['body']),
                'image_asset_id' => $data['image_asset_id'] ?? null,
            ]);

            if (!empty($data['poll'])) {
                $poll = $post->poll()->create([
                    'question' => trim($data['poll']['question']),
                    'ends_at' => now()->addDays((int) ($data['poll']['days'] ?? 3)),
                ]);
                foreach (array_values($data['poll']['options']) as $i => $label) {
                    $poll->options()->create(['label' => trim($label), 'sort_order' => $i]);
                }
            }

            return $post;
        });

        $others = array_values(array_diff(CommunityGuard::memberIds(), [$user->id]));
        if ($data['category'] === 'info') {
            Notifier::toMany($others, 'Pengumuman baru', mb_strimwidth($post->body, 0, 120, '…'), 'system', 'post', $post->id);
        } elseif (!empty($data['poll'])) {
            Notifier::toMany($others, 'Polling baru', $data['poll']['question'], 'activity', 'post', $post->id);
        }

        return response()->json(['data' => $this->presentMany($request, collect([$this->base($request)->findOrFail($post->id)]))[0]], 201);
    }

    public function destroy(Request $request, CommunityPost $post): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'admin' && $post->user_id !== $user->id) {
            return response()->json(['message' => 'Kamu hanya bisa menghapus postinganmu sendiri.'], 403);
        }
        $post->delete();

        return response()->json(['message' => 'Post dihapus']);
    }

    /** Beri atau cabut apresiasi. Penulis diberi tahu pada jumlah 1, 5, 10, 25, 50, 100. */
    public function like(Request $request, CommunityPost $post): JsonResponse
    {
        $user = $request->user();
        CommunityGuard::assertCanParticipate($user);
        abort_if($post->is_hidden, 404, 'Post tidak ditemukan.');

        $changes = $post->likes()->toggle($user->id);
        $liked = count($changes['attached']) > 0;
        $count = $post->likes()->count();

        if ($liked && $post->user_id !== $user->id && in_array($count, [1, 5, 10, 25, 50, 100], true)) {
            Notifier::to(
                $post->user_id,
                'Apresiasi untuk postinganmu',
                $count === 1
                    ? "{$user->name} memberi apresiasi pada postinganmu."
                    : "Postinganmu sudah mendapat {$count} apresiasi.",
                'activity', 'post', $post->id
            );
        }

        return response()->json(['data' => ['liked' => $liked, 'like_count' => $count]]);
    }

    /** Sematkan atau lepas sematan (admin). */
    public function pin(Request $request, CommunityPost $post): JsonResponse
    {
        abort_unless($request->user()->role === 'admin', 403, 'Hanya admin yang dapat menyematkan post.');
        $post->update(['is_pinned' => !$post->is_pinned]);

        return response()->json(['data' => ['is_pinned' => (bool) $post->is_pinned]]);
    }

    /** Pilih satu opsi polling (satu suara per pengguna, tidak bisa diubah). */
    public function vote(Request $request, CommunityPoll $poll): JsonResponse
    {
        $user = $request->user();
        CommunityGuard::assertCanParticipate($user);

        $data = $request->validate(['option_id' => ['required', 'integer']]);

        if ($poll->ends_at->isPast()) {
            return response()->json(['message' => 'Polling ini sudah berakhir.'], 422);
        }
        if (!$poll->options()->whereKey($data['option_id'])->exists()) {
            return response()->json(['message' => 'Pilihan tidak valid.'], 422);
        }
        if (DB::table('community_poll_votes')->where('poll_id', $poll->id)->where('user_id', $user->id)->exists()) {
            return response()->json(['message' => 'Kamu sudah memberikan suara pada polling ini.'], 409);
        }

        DB::table('community_poll_votes')->insert([
            'poll_id' => $poll->id,
            'option_id' => $data['option_id'],
            'user_id' => $user->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $fresh = CommunityPoll::with(['options' => fn ($q) => $q->withCount('voters')])->findOrFail($poll->id);

        return response()->json(['data' => CommunityPresenter::poll($fresh, (int) $data['option_id'])]);
    }

    /** Laporkan post untuk ditinjau admin. */
    public function report(Request $request, CommunityPost $post): JsonResponse
    {
        $data = $request->validate(['reason' => ['nullable', 'string', 'max:255']]);

        $exists = DB::table('community_post_reports')
            ->where('post_id', $post->id)->where('reporter_id', $request->user()->id)
            ->where('status', 'pending')->exists();
        if (!$exists) {
            DB::table('community_post_reports')->insert([
                'post_id' => $post->id,
                'reporter_id' => $request->user()->id,
                'reason' => $data['reason'] ?? null,
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        return response()->json(['message' => 'Terima kasih, laporanmu akan ditinjau admin.']);
    }
}