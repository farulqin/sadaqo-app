<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AdminUserResource;
use App\Models\ActivityLog;
use App\Models\AppNotification;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AdminUserController extends Controller
{
    /** Sama dengan CommunityPolicy di Flutter: pelanggaran ke-2 = banned 30 hari. */
    private const STRIKES_BEFORE_BAN = 2;
    private const AUTO_BAN_DAYS = 30;

    private function base()
    {
        $successful = fn ($q) => $q->where('status', 'success');

        return User::with('avatarAsset')
            ->withCount(['donations as donations_count' => $successful])
            ->withSum(['donations as donations_total' => $successful], 'amount');
    }

    private function respond(User $user): AdminUserResource
    {
        return new AdminUserResource($this->base()->findOrFail($user->id));
    }

    /** Daftar pengguna. Filter opsional: ?role=donatur&q=siti */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = $this->base()->orderByDesc('created_at');

        if ($role = $request->query('role')) {
            $query->where('role', $role);
        }
        $search = trim((string) $request->query('q', ''));
        if ($search !== '') {
            $query->where(function ($w) use ($search) {
                $w->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        return AdminUserResource::collection($query->get());
    }

    /** Admin menambah donatur baru. */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:100'],
            'email' => ['required', 'email', 'max:150', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:20'],
            'password' => ['required', 'string', 'min:8', 'max:100'],
            'avatar_asset_id' => ['nullable', 'integer', 'exists:assets,id'],
        ], [
            'email.unique' => 'Email sudah dipakai pengguna lain',
        ]);

        $user = new User();
        $user->forceFill([
            'name' => trim($data['name']),
            'email' => strtolower(trim($data['email'])),
            'phone' => $data['phone'] ?? null,
            'password' => $data['password'],
            'role' => 'donatur',
            'avatar_asset_id' => $data['avatar_asset_id'] ?? null,
            'email_verified_at' => now(),
            'is_active' => true,
        ])->save();

        ActivityLog::record('user', "Admin menambahkan pengguna: {$user->name}", $request->user());

        return $this->respond($user)->response()->setStatusCode(201);
    }

    public function update(Request $request, User $user): JsonResponse|AdminUserResource
    {
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'min:2', 'max:100'],
            'email' => [
                'sometimes', 'required', 'email', 'max:150',
                Rule::unique('users', 'email')->ignore($user->id),
            ],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'avatar_asset_id' => ['sometimes', 'nullable', 'integer', 'exists:assets,id'],
            'is_active' => ['sometimes', 'boolean'],
        ], [
            'email.unique' => 'Email sudah dipakai pengguna lain',
        ]);

        if (array_key_exists('is_active', $data) && !$data['is_active']) {
            if ($user->isAdmin()) {
                return response()->json(['message' => 'Akun admin tidak dapat dinonaktifkan.'], 422);
            }
        }
        if (isset($data['email'])) {
            $data['email'] = strtolower(trim($data['email']));
        }

        $user->forceFill($data)->save();

        if (array_key_exists('is_active', $data)) {
            ActivityLog::record(
                'user',
                ($data['is_active'] ? 'Akun diaktifkan: ' : 'Akun dinonaktifkan: ') . $user->name,
                $request->user()
            );
        }

        return $this->respond($user);
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        if ($user->id === $request->user()->id || $user->isAdmin()) {
            return response()->json(['message' => 'Akun admin tidak dapat dihapus.'], 422);
        }
        if ($user->donations()->exists()) {
            return response()->json([
                'message' => 'Pengguna sudah punya riwayat donasi dan tidak bisa dihapus. Nonaktifkan saja akunnya.',
            ], 409);
        }

        $name = $user->name;
        try {
            $user->tokens()->delete();
            $user->delete();
        } catch (QueryException) {
            return response()->json([
                'message' => 'Pengguna masih terkait dengan data lain. Nonaktifkan saja akunnya.',
            ], 409);
        }

        ActivityLog::record('user', "Admin menghapus pengguna: {$name}", $request->user());

        return response()->json(['message' => 'Pengguna dihapus']);
    }

    /** Peringatan. Pelanggaran ke-2 otomatis banned 30 hari dari Komunitas. */
    public function warn(Request $request, User $user): JsonResponse|AdminUserResource
    {
        if ($user->isAdmin()) {
            return response()->json(['message' => 'Akun admin tidak dapat dimoderasi.'], 422);
        }
        $data = $request->validate(['note' => ['nullable', 'string', 'max:500']]);

        $strikes = (int) $user->strikes + 1;
        $autoBan = $strikes >= self::STRIKES_BEFORE_BAN;

        $user->forceFill([
            'strikes' => $strikes,
            'banned_until' => $autoBan ? now()->addDays(self::AUTO_BAN_DAYS) : $user->banned_until,
        ])->save();

        AppNotification::create([
            'user_id' => $user->id,
            'title' => $autoBan ? 'Akunmu dibanned dari Komunitas' : 'Peringatan dari admin',
            'body' => $autoBan
                ? 'Pelanggaran kedua: kamu dibanned ' . self::AUTO_BAN_DAYS . ' hari dari Komunitas.'
                : ($data['note'] ?? 'Mohon patuhi ketentuan komunitas.'),
        ]);
        ActivityLog::record('user', "Peringatan untuk {$user->name} (ke-{$strikes})", $request->user());

        return $this->respond($user);
    }

    /** Banned dari Komunitas. Body: { days (kosong = permanen), reason }. */
    public function ban(Request $request, User $user): JsonResponse|AdminUserResource
    {
        if ($user->isAdmin()) {
            return response()->json(['message' => 'Akun admin tidak dapat dimoderasi.'], 422);
        }
        $data = $request->validate([
            'days' => ['nullable', 'integer', 'min:1', 'max:3650'],
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $permanent = empty($data['days']);
        $until = $permanent ? now()->addYears(50) : now()->addDays((int) $data['days']);
        $reason = trim((string) ($data['reason'] ?? ''));

        $user->forceFill([
            'strikes' => max((int) $user->strikes, self::STRIKES_BEFORE_BAN),
            'banned_until' => $until,
        ])->save();

        AppNotification::create([
            'user_id' => $user->id,
            'title' => 'Akunmu dibanned dari Komunitas',
            'body' => ($permanent
                ? 'Kamu dibanned permanen dari Komunitas.'
                : "Kamu dibanned {$data['days']} hari dari Komunitas.")
                . ($reason !== '' ? " Alasan: {$reason}" : ''),
        ]);
        ActivityLog::record('user', "{$user->name} dibanned dari Komunitas", $request->user());

        return $this->respond($user);
    }

    /** Bebaskan banned dan reset catatan pelanggaran. */
    public function lift(Request $request, User $user): JsonResponse|AdminUserResource
    {
        $user->forceFill(['strikes' => 0, 'banned_until' => null])->save();

        AppNotification::create([
            'user_id' => $user->id,
            'title' => 'Banned dibebaskan',
            'body' => 'Akunmu sudah bisa kembali berpartisipasi di Komunitas. Mohon patuhi ketentuan komunitas.',
        ]);
        ActivityLog::record('user', "Banned {$user->name} dibebaskan", $request->user());

        return $this->respond($user);
    }
}