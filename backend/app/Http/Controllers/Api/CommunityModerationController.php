<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\User;
use App\Support\CommunityGuard;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CommunityModerationController extends Controller
{
    /** Daftar laporan. Filter: ?status=pending|valid|dismissed */
    public function index(Request $request): JsonResponse
    {
        $rows = DB::table('community_post_reports AS r')
            ->leftJoin('community_posts AS p', 'p.id', '=', 'r.post_id')
            ->leftJoin('community_comments AS c', 'c.id', '=', 'r.comment_id')
            ->join('users AS rep', 'rep.id', '=', 'r.reporter_id')
            ->leftJoin('users AS au', 'au.id', '=', DB::raw('COALESCE(p.user_id, c.user_id)'))
            ->when($request->query('status'), fn ($q, $s) => $q->where('r.status', $s))
            ->orderByDesc('r.id')
            ->limit(100)
            ->get([
                'r.id', 'r.status', 'r.reason', 'r.created_at', 'r.post_id', 'r.comment_id',
                'rep.name AS reporter_name',
                'au.id AS author_id', 'au.name AS author_name',
                DB::raw('COALESCE(p.body, c.body) AS content'),
                DB::raw('COALESCE(p.is_hidden, c.is_hidden) AS hidden'),
            ]);

        return response()->json(['data' => $rows->map(fn ($r) => [
            'id' => $r->id,
            'status' => $r->status,
            'reason' => $r->reason,
            'kind' => $r->comment_id ? 'comment' : 'post',
            'post_id' => $r->post_id,
            'comment_id' => $r->comment_id,
            'content' => $r->content,
            'is_hidden' => (bool) $r->hidden,
            'reporter_name' => $r->reporter_name,
            'author_id' => $r->author_id,
            'author_name' => $r->author_name,
            'created_at' => \Illuminate\Support\Carbon::parse($r->created_at)->toIso8601String(),
        ])->values()]);
    }

    /**
     * Tinjau laporan. valid = konten disembunyikan dan penulis kena sanksi
     * (peringatan, lalu banned). dismissed = laporan ditolak.
     * Body: { decision: valid|dismissed, violation_type }
     */
    public function review(Request $request, int $id): JsonResponse
    {
        $data = $request->validate([
            'decision' => ['required', 'in:valid,dismissed'],
            'violation_type' => ['nullable', 'in:hoax,hate,scam,porn,blasphemy,profanity'],
        ]);

        $report = DB::table('community_post_reports')->find($id);
        abort_unless($report, 404, 'Laporan tidak ditemukan.');

        if ($data['decision'] === 'valid') {
            $authorId = null;
            if ($report->comment_id) {
                $authorId = DB::table('community_comments')->where('id', $report->comment_id)->value('user_id');
                DB::table('community_comments')->where('id', $report->comment_id)->update(['is_hidden' => true]);
            } elseif ($report->post_id) {
                $authorId = DB::table('community_posts')->where('id', $report->post_id)->value('user_id');
                DB::table('community_posts')->where('id', $report->post_id)->update(['is_hidden' => true]);
            }

            $author = $authorId ? User::find($authorId) : null;
            if ($author && $author->role !== 'admin') {
                CommunityGuard::registerViolation($author, $data['violation_type'] ?? 'hoax');
            }
        }

        DB::table('community_post_reports')->where('id', $id)->update([
            'status' => $data['decision'],
            'updated_at' => now(),
        ]);
        ActivityLog::record('verified', 'Laporan komunitas ditinjau: ' . $data['decision'], $request->user());

        return response()->json(['message' => 'Laporan ditinjau']);
    }
}