<?php

namespace App\Support;

use App\Models\CommunityComment;
use App\Models\CommunityEvent;
use App\Models\CommunityPoll;
use App\Models\CommunityPost;
use App\Models\User;

/** Bentuk JSON komunitas. Nama key mengikuti model di Flutter. */
class CommunityPresenter
{
    public static function handle(User $u): string
    {
        $slug = strtolower(preg_replace('/[^A-Za-z0-9]/', '', $u->name) ?? '');

        return '@' . ($slug !== '' ? $slug : 'user' . $u->id);
    }

    public static function author(User $u, array $badges): array
    {
        return [
            'id' => $u->id,
            'name' => $u->name,
            'handle' => self::handle($u),
            'avatar' => $u->avatarAsset?->ref,
            'role' => $u->role,
            'badges' => $badges,
        ];
    }

    public static function poll(CommunityPoll $poll, ?int $myVote): array
    {
        $total = (int) $poll->options->sum('voters_count');

        return [
            'id' => $poll->id,
            'question' => $poll->question,
            'ends_at' => $poll->ends_at->toIso8601String(),
            'is_closed' => $poll->ends_at->isPast(),
            'total_votes' => $total,
            'my_vote' => $myVote,
            'options' => $poll->options->map(fn ($o) => [
                'id' => $o->id,
                'label' => $o->label,
                'votes' => (int) $o->voters_count,
                'percent' => $total > 0 ? (int) round($o->voters_count * 100 / $total) : 0,
            ])->values(),
        ];
    }

    public static function post(CommunityPost $p, User $viewer, array $badges, array $myVotes): array
    {
        return [
            'id' => $p->id,
            'category' => $p->category,
            'body' => $p->body,
            'image' => $p->imageAsset?->ref,
            'is_pinned' => (bool) $p->is_pinned,
            'created_at' => $p->created_at->toIso8601String(),
            'author' => self::author($p->user, $badges[$p->user_id] ?? []),
            'like_count' => (int) $p->likes_count,
            'comment_count' => (int) $p->comments_count,
            'liked' => (bool) $p->liked,
            'poll' => $p->poll ? self::poll($p->poll, $myVotes[$p->poll->id] ?? null) : null,
            'can_delete' => $viewer->role === 'admin' || $viewer->id === $p->user_id,
        ];
    }

    public static function comment(CommunityComment $c, User $viewer, array $badges): array
    {
        return [
            'id' => $c->id,
            'post_id' => $c->post_id,
            'parent_id' => $c->parent_id,
            'body' => $c->body,
            'created_at' => $c->created_at->toIso8601String(),
            'author' => self::author($c->user, $badges[$c->user_id] ?? []),
            'can_delete' => $viewer->role === 'admin' || $viewer->id === $c->user_id,
            'replies' => $c->relationLoaded('replies')
                ? $c->replies->map(fn ($r) => self::comment($r, $viewer, $badges))->values()
                : [],
        ];
    }

    public static function event(CommunityEvent $e, User $viewer): array
    {
        return [
            'id' => $e->id,
            'title' => $e->title,
            'description' => $e->description,
            'location' => $e->location,
            'is_online' => (bool) $e->is_online,
            'starts_at' => $e->starts_at->toIso8601String(),
            'ends_at' => $e->ends_at?->toIso8601String(),
            'image' => $e->imageAsset?->ref,
            'interested_count' => (int) $e->interested_count,
            'interested' => (bool) $e->interested,
            'creator' => $e->creator?->name,
            'can_manage' => $viewer->role === 'admin' || $viewer->id === $e->created_by,
        ];
    }
}