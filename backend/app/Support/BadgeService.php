<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;

/** Badge kebaikan: dihitung dari donasi dan aktivitas komunitas (tanpa tabel tambahan). */
class BadgeService
{
    public const CATALOG = [
        'admin' => ['Admin SADAQO', '🛡️', 'Pengelola platform SADAQO'],
        'pengelola' => ['Pengelola Terpercaya', '🤝', 'Pengelola program kebaikan'],
        'donatur_pertama' => ['Donatur Pertama', '🌱', 'Sudah berdonasi di SADAQO'],
        'rutin_berbagi' => ['Rutin Berbagi', '🔁', 'Berdonasi 5 kali atau lebih'],
        'dermawan' => ['Dermawan', '💛', 'Total donasi minimal Rp 1 juta'],
        'dermawan_emas' => ['Dermawan Emas', '🏅', 'Total donasi minimal Rp 10 juta'],
        'penggerak' => ['Penggerak Kebaikan', '🔥', 'Menulis 10 post atau komentar'],
        'inspirator' => ['Inspirator', '✨', 'Postinganmu mendapat 10 apresiasi'],
    ];

    /** @return array{key:string,label:string,icon:string,description:string}[] */
    public static function catalog(): array
    {
        $out = [];
        foreach (self::CATALOG as $key => [$label, $icon, $desc]) {
            $out[] = ['key' => $key, 'label' => $label, 'icon' => $icon, 'description' => $desc];
        }

        return $out;
    }

    /**
     * @param array<int> $userIds
     * @return array<int, array<int, array{key:string,label:string,icon:string,description:string}>>
     */
    public static function forUsers(array $userIds): array
    {
        $ids = array_values(array_unique(array_map('intval', $userIds)));
        if (!$ids) {
            return [];
        }

        $donations = DB::table('donations')
            ->where('status', 'success')->whereIn('user_id', $ids)
            ->groupBy('user_id')
            ->selectRaw('user_id, COUNT(*) AS c, COALESCE(SUM(amount), 0) AS s')
            ->get()->keyBy('user_id');
        $posts = DB::table('community_posts')
            ->where('is_hidden', false)->whereIn('user_id', $ids)
            ->groupBy('user_id')->selectRaw('user_id, COUNT(*) AS c')->pluck('c', 'user_id');
        $comments = DB::table('community_comments')
            ->where('is_hidden', false)->whereIn('user_id', $ids)
            ->groupBy('user_id')->selectRaw('user_id, COUNT(*) AS c')->pluck('c', 'user_id');
        $likes = DB::table('community_post_likes AS l')
            ->join('community_posts AS p', 'p.id', '=', 'l.post_id')
            ->whereIn('p.user_id', $ids)
            ->groupBy('p.user_id')->selectRaw('p.user_id AS user_id, COUNT(*) AS c')->pluck('c', 'user_id');
        $roles = DB::table('users')->whereIn('id', $ids)->pluck('role', 'id');

        $result = [];
        foreach ($ids as $id) {
            $keys = [];
            $role = $roles[$id] ?? 'donatur';
            if ($role === 'admin') {
                $keys[] = 'admin';
            }
            if ($role === 'pengelola') {
                $keys[] = 'pengelola';
            }
            $count = (int) ($donations[$id]->c ?? 0);
            $sum = (int) ($donations[$id]->s ?? 0);
            if ($count >= 1) {
                $keys[] = 'donatur_pertama';
            }
            if ($count >= 5) {
                $keys[] = 'rutin_berbagi';
            }
            if ($sum >= 1_000_000) {
                $keys[] = 'dermawan';
            }
            if ($sum >= 10_000_000) {
                $keys[] = 'dermawan_emas';
            }
            if ((int) ($posts[$id] ?? 0) + (int) ($comments[$id] ?? 0) >= 10) {
                $keys[] = 'penggerak';
            }
            if ((int) ($likes[$id] ?? 0) >= 10) {
                $keys[] = 'inspirator';
            }

            $result[$id] = array_map(function ($key) {
                [$label, $icon, $desc] = self::CATALOG[$key];

                return ['key' => $key, 'label' => $label, 'icon' => $icon, 'description' => $desc];
            }, $keys);
        }

        return $result;
    }
}