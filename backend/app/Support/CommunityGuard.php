<?php

namespace App\Support;

use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/** Aturan partisipasi Komunitas: anggota, banned, dan penyaringan konten. */
class CommunityGuard
{
    /** Sama dengan CommunityPolicy di Flutter. */
    public const STRIKES_BEFORE_BAN = 2;
    public const BAN_DAYS = 30;

    public static function isMember(User $user): bool
    {
        return in_array($user->role, ['admin', 'pengelola'], true)
            || DB::table('community_members')->where('user_id', $user->id)->exists();
    }

    /** ID semua anggota aktif (termasuk admin dan pengelola). */
    public static function memberIds(): array
    {
        return DB::table('users')
            ->where('is_active', true)
            ->where(function ($q) {
                $q->whereIn('role', ['admin', 'pengelola'])
                    ->orWhereIn('id', DB::table('community_members')->select('user_id'));
            })
            ->pluck('id')
            ->all();
    }

    /** Menolak (403) bila banned atau belum bergabung. */
    public static function assertCanParticipate(User $user): void
    {
        if ($user->banned_until && Carbon::parse($user->banned_until)->isFuture()) {
            $until = Carbon::parse($user->banned_until)->timezone('Asia/Jakarta')->format('d/m/Y H:i');
            abort(403, "Kamu sedang dibanned dari Komunitas sampai {$until} WIB.");
        }
        if (!self::isMember($user)) {
            abort(403, 'Gabung dulu ke Komunitas untuk berpartisipasi.');
        }
    }

    /** Menolak (422) dan mencatat pelanggaran bila teks mengandung konten terlarang. */
    public static function screen(User $user, array $texts): void
    {
        $type = null;
        foreach ($texts as $text) {
            $type = ContentFilter::check((string) $text);
            if ($type) {
                break;
            }
        }
        if (!$type) {
            return;
        }

        $label = ContentFilter::LABELS[$type];
        if ($user->role === 'admin') {
            abort(422, "Pesan ditolak: mengandung {$label}.");
        }

        $strikes = self::registerViolation($user, $type);
        if ($strikes >= self::STRIKES_BEFORE_BAN) {
            abort(422, "Pesan ditolak: mengandung {$label}. Akunmu dibanned " . self::BAN_DAYS . ' hari dari Komunitas.');
        }
        abort(422, "Pesan ditolak: mengandung {$label}. Ini peringatan ke-{$strikes}; pelanggaran berikutnya membuat akunmu dibanned " . self::BAN_DAYS . ' hari.');
    }

    /** Mencatat pelanggaran, menambah strike, banned bila melewati batas. Mengembalikan jumlah strike. */
    public static function registerViolation(User $user, string $type): int
    {
        DB::table('community_violations')->insert([
            'user_id' => $user->id,
            'type' => $type,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $strikes = (int) $user->strikes + 1;
        $banned = $strikes >= self::STRIKES_BEFORE_BAN;
        $user->forceFill([
            'strikes' => $strikes,
            'banned_until' => $banned ? now()->addDays(self::BAN_DAYS) : $user->banned_until,
        ])->save();

        $label = ContentFilter::LABELS[$type] ?? $type;
        Notifier::to(
            $user->id,
            $banned ? 'Akunmu dibanned dari Komunitas' : 'Peringatan dari Komunitas',
            $banned
                ? "Pelanggaran ({$label}) membuat akunmu dibanned " . self::BAN_DAYS . ' hari dari Komunitas.'
                : "Kontenmu melanggar ketentuan ({$label}). Pelanggaran berikutnya membuat akunmu dibanned.",
            'system',
        );

        return $strikes;
    }
}