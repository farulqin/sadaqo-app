<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;

/** Pembuat notifikasi (satu atau banyak penerima). */
class Notifier
{
    public static function to(
        int $userId,
        string $title,
        string $body,
        string $type = 'activity',
        ?string $refType = null,
        ?int $refId = null,
    ): void {
        self::toMany([$userId], $title, $body, $type, $refType, $refId);
    }

    /** @param array<int> $userIds */
    public static function toMany(
        array $userIds,
        string $title,
        string $body,
        string $type = 'activity',
        ?string $refType = null,
        ?int $refId = null,
    ): void {
        $now = now();
        $rows = array_map(fn ($id) => [
            'user_id' => $id,
            'title' => $title,
            'body' => $body,
            'is_read' => false,
            'type' => $type,
            'ref_type' => $refType,
            'ref_id' => $refId,
            'created_at' => $now,
            'updated_at' => $now,
        ], array_values(array_unique($userIds)));

        foreach (array_chunk($rows, 500) as $chunk) {
            DB::table('app_notifications')->insert($chunk);
        }
    }
}