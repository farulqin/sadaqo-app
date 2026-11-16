<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\BadgeService;
use App\Support\CommunityGuard;
use App\Support\CommunityPresenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class CommunityController extends Controller
{
    /** Tandai pengguna sedang online (dibatasi satu tulis per 2 menit). */
    public static function touch(User $user): void
    {
        if (!$user->last_seen_at || Carbon::parse($user->last_seen_at)->lt(now()->subMinutes(2))) {
            DB::table('users')->where('id', $user->id)->update(['last_seen_at' => now()]);
        }
    }

    private function members()
    {
        return User::query()
            ->where('is_active', true)
            ->where(function ($q) {
                $q->whereIn('role', ['admin', 'pengelola'])
                    ->orWhereIn('id', DB::table('community_members')->select('user_id'));
            });
    }

    /** Ringkasan untuk halaman utama Komunitas: anggota, online, status gabung, badge saya. */
    public function overview(Request $request): JsonResponse
    {
        $user = $request->user();
        self::touch($user);

        $earned = BadgeService::forUsers([$user->id])[$user->id] ?? [];
        $earnedKeys = array_column($earned, 'key');

        return response()->json(['data' => [
            'member_count' => $this->members()->count(),
            'online_count' => $this->members()->where('last_seen_at', '>=', now()->subMinutes(5))->count(),
            'joined' => CommunityGuard::isMember($user),
            'active_polls' => DB::table('community_polls AS po')
                ->join('community_posts AS p', 'p.id', '=', 'po.post_id')
                ->where('p.is_hidden', false)->where('po.ends_at', '>', now())->count(),
            'my_badges' => $earned,
            'badge_catalog' => array_map(
                fn ($b) => $b + ['earned' => in_array($b['key'], $earnedKeys, true)],
                BadgeService::catalog()
            ),
            'my_stats' => [
                'posts' => DB::table('community_posts')->where('user_id', $user->id)->where('is_hidden', false)->count(),
                'comments' => DB::table('community_comments')->where('user_id', $user->id)->where('is_hidden', false)->count(),
                'appreciations' => DB::table('community_post_likes AS l')
                    ->join('community_posts AS p', 'p.id', '=', 'l.post_id')
                    ->where('p.user_id', $user->id)->count(),
            ],
        ]]);
    }

    public function join(Request $request): JsonResponse
    {
        $user = $request->user();
        DB::table('community_members')->updateOrInsert(
            ['user_id' => $user->id],
            ['created_at' => now(), 'updated_at' => now()]
        );

        return response()->json(['message' => 'Kamu sudah bergabung di Komunitas', 'joined' => true]);
    }

    public function leave(Request $request): JsonResponse
    {
        $user = $request->user();
        if (in_array($user->role, ['admin', 'pengelola'], true)) {
            return response()->json(['message' => 'Admin dan pengelola otomatis menjadi anggota Komunitas.'], 422);
        }
        DB::table('community_members')->where('user_id', $user->id)->delete();

        return response()->json(['message' => 'Kamu keluar dari Komunitas', 'joined' => false]);
    }

    /** Daftar anggota. Filter: ?filter=semua|online|admin&q=nama */
    public function members(Request $request): JsonResponse
    {
        self::touch($request->user());

        $query = $this->members()->with('avatarAsset');
        $filter = $request->query('filter', 'semua');
        if ($filter === 'online') {
            $query->where('last_seen_at', '>=', now()->subMinutes(5));
        } elseif ($filter === 'admin') {
            $query->where('role', 'admin');
        }
        $search = trim((string) $request->query('q', ''));
        if ($search !== '') {
            $query->where('name', 'like', "%{$search}%");
        }

        $page = $query
            ->orderByRaw("FIELD(role, 'admin', 'pengelola', 'donatur')")
            ->orderBy('name')
            ->paginate(30);

        $items = collect($page->items());
        $badges = BadgeService::forUsers($items->pluck('id')->all());
        $onlineSince = now()->subMinutes(5);

        return response()->json([
            'data' => $items->map(fn (User $u) => CommunityPresenter::author($u, $badges[$u->id] ?? []) + [
                'is_online' => $u->last_seen_at && Carbon::parse($u->last_seen_at)->gte($onlineSince),
                'joined_at' => $u->created_at?->toIso8601String(),
            ])->values(),
            'meta' => ['page' => $page->currentPage(), 'last_page' => $page->lastPage(), 'total' => $page->total()],
        ]);
    }
}