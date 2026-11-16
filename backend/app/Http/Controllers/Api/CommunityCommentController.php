<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CommunityComment;
use App\Models\CommunityPost;
use App\Support\BadgeService;
use App\Support\CommunityGuard;
use App\Support\CommunityPresenter;
use App\Support\Notifier;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CommunityCommentController extends Controller
{
    /** Komentar utama beserta balasannya (satu tingkat). */
    public function index(Request $request, CommunityPost $post): JsonResponse
    {
        abort_if($post->is_hidden, 404, 'Post tidak ditemukan.');

        $comments = CommunityComment::query()
            ->where('post_id', $post->id)->whereNull('parent_id')->where('is_hidden', false)
            ->with([
                'user.avatarAsset',
                'replies' => fn ($q) => $q->where('is_hidden', false)->orderBy('id')->with('user.avatarAsset'),
            ])
            ->orderBy('id')
            ->limit(200)
            ->get();

        $userIds = $comments->pluck('user_id')
            ->merge($comments->flatMap(fn ($c) => $c->replies->pluck('user_id')))
            ->all();
        $badges = BadgeService::forUsers($userIds);

        return response()->json([
            'data' => $comments->map(fn ($c) => CommunityPresenter::comment($c, $request->user(), $badges))->values(),
        ]);
    }

    /** Tulis komentar atau balasan. Balasan atas balasan dijadikan balasan komentar utama. */
    public function store(Request $request, CommunityPost $post): JsonResponse
    {
        $user = $request->user();
        abort_if($post->is_hidden, 404, 'Post tidak ditemukan.');

        $data = $request->validate([
            'body' => ['required', 'string', 'min:1', 'max:500'],
            'parent_id' => ['nullable', 'integer'],
        ]);

        CommunityGuard::assertCanParticipate($user);
        CommunityGuard::screen($user, [$data['body']]);

        $parent = null;
        if (!empty($data['parent_id'])) {
            $parent = CommunityComment::where('post_id', $post->id)->where('is_hidden', false)->find($data['parent_id']);
            if (!$parent) {
                return response()->json(['message' => 'Komentar yang dibalas tidak ditemukan.'], 422);
            }
            if ($parent->parent_id) {
                $parent = CommunityComment::find($parent->parent_id) ?? $parent;
            }
        }

        $comment = CommunityComment::create([
            'post_id' => $post->id,
            'user_id' => $user->id,
            'parent_id' => $parent?->id,
            'body' => trim($data['body']),
        ]);

        $excerpt = mb_strimwidth($comment->body, 0, 100, '…');
        if ($post->user_id !== $user->id) {
            Notifier::to($post->user_id, 'Komentar baru', "{$user->name}: {$excerpt}", 'activity', 'post', $post->id);
        }
        if ($parent && $parent->user_id !== $user->id && $parent->user_id !== $post->user_id) {
            Notifier::to($parent->user_id, 'Balasan untuk komentarmu', "{$user->name}: {$excerpt}", 'activity', 'post', $post->id);
        }

        $comment->load('user.avatarAsset');
        $badges = BadgeService::forUsers([$user->id]);

        return response()->json(['data' => CommunityPresenter::comment($comment, $user, $badges)], 201);
    }

    public function destroy(Request $request, CommunityComment $comment): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'admin' && $comment->user_id !== $user->id) {
            return response()->json(['message' => 'Kamu hanya bisa menghapus komentarmu sendiri.'], 403);
        }
        $comment->delete();

        return response()->json(['message' => 'Komentar dihapus']);
    }

    public function report(Request $request, CommunityComment $comment): JsonResponse
    {
        $data = $request->validate(['reason' => ['nullable', 'string', 'max:255']]);

        $exists = DB::table('community_post_reports')
            ->where('comment_id', $comment->id)->where('reporter_id', $request->user()->id)
            ->where('status', 'pending')->exists();
        if (!$exists) {
            DB::table('community_post_reports')->insert([
                'comment_id' => $comment->id,
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