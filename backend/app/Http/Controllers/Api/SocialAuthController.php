<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

/**
 * Masuk / daftar lewat Google dan Apple.
 * Token diverifikasi ke server penyedia, lalu dibuatkan token Sanctum seperti login biasa.
 */
class SocialAuthController extends Controller
{
    /** Body: { id_token?, access_token? } (salah satu cukup). */
    public function google(Request $request): JsonResponse
    {
        $data = $request->validate([
            'id_token' => ['nullable', 'string'],
            'access_token' => ['nullable', 'string'],
        ]);
        abort_if(empty($data['id_token']) && empty($data['access_token']), 422, 'Token Google tidak ada.');

        $allowed = array_values(array_filter((array) config('services.google.client_ids')));
        abort_if(!$allowed, 503, 'Login Google belum dikonfigurasi di server (isi GOOGLE_CLIENT_ID di .env).');

        $query = !empty($data['id_token'])
            ? ['id_token' => $data['id_token']]
            : ['access_token' => $data['access_token']];

        $res = Http::timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', $query);
        abort_unless($res->ok(), 401, 'Token Google tidak valid atau sudah kedaluwarsa.');
        $info = $res->json();

        // Token harus dibuat untuk aplikasi kita, bukan aplikasi lain.
        $aud = $info['aud'] ?? '';
        $azp = $info['azp'] ?? '';
        abort_unless(in_array($aud, $allowed, true) || in_array($azp, $allowed, true), 401, 'Token Google bukan untuk aplikasi ini.');

        $email = strtolower(trim((string) ($info['email'] ?? '')));
        $verified = in_array($info['email_verified'] ?? false, [true, 'true', 1, '1'], true);
        abort_if($email === '' || !$verified, 401, 'Email Google belum terverifikasi.');

        $user = $this->findOrCreate('google_id', (string) ($info['sub'] ?? ''), $email, (string) ($info['name'] ?? ''));

        return $this->respond($user);
    }

    /** Body: { identity_token, given_name?, family_name? } */
    public function apple(Request $request): JsonResponse
    {
        $data = $request->validate([
            'identity_token' => ['required', 'string'],
            'given_name' => ['nullable', 'string', 'max:60'],
            'family_name' => ['nullable', 'string', 'max:60'],
        ]);

        $allowed = array_values(array_filter((array) config('services.apple.client_ids')));
        abort_if(!$allowed, 503, 'Login Apple belum dikonfigurasi di server (isi APPLE_CLIENT_ID di .env).');
        abort_unless(class_exists(\Firebase\JWT\JWT::class), 503, 'Jalankan "composer require firebase/php-jwt" di folder backend untuk mengaktifkan login Apple.');

        $jwks = Cache::remember('apple_jwks', 3600, function () {
            $r = Http::timeout(10)->get('https://appleid.apple.com/auth/keys');
            abort_unless($r->ok(), 503, 'Gagal mengambil kunci verifikasi Apple.');

            return $r->json();
        });

        try {
            \Firebase\JWT\JWT::$leeway = 60;
            $claims = (array) \Firebase\JWT\JWT::decode(
                $data['identity_token'],
                \Firebase\JWT\JWK::parseKeySet($jwks)
            );
        } catch (\Throwable $e) {
            abort(401, 'Token Apple tidak valid atau sudah kedaluwarsa.');
        }

        abort_unless(($claims['iss'] ?? '') === 'https://appleid.apple.com', 401, 'Token Apple tidak valid.');
        abort_unless(in_array($claims['aud'] ?? '', $allowed, true), 401, 'Token Apple bukan untuk aplikasi ini.');

        $sub = (string) ($claims['sub'] ?? '');
        abort_if($sub === '', 401, 'Token Apple tidak valid.');

        // Apple hanya mengirim email saat pertama kali; selanjutnya cukup dikenali lewat sub.
        $email = strtolower(trim((string) ($claims['email'] ?? '')));
        $name = trim(($data['given_name'] ?? '') . ' ' . ($data['family_name'] ?? ''));

        $user = $this->findOrCreate('apple_id', $sub, $email, $name);

        return $this->respond($user);
    }

    private function findOrCreate(string $column, string $providerId, string $email, string $name): User
    {
        abort_if($providerId === '', 401, 'Akun penyedia tidak dikenali.');

        $user = User::where($column, $providerId)->first();

        if (!$user && $email !== '') {
            $user = User::where('email', $email)->first();
            if ($user) {
                $user->forceFill([$column => $providerId])->save();
            }
        }

        if (!$user) {
            abort_if($email === '', 422, 'Email tidak tersedia dari akun ini. Daftar dengan email biasa.');

            $user = User::create([
                'name' => $name !== '' ? Str::limit($name, 100, '') : Str::before($email, '@'),
                'email' => $email,
                'password' => Str::random(40),
                'role' => User::ROLE_DONATUR,
                $column => $providerId,
            ]);
            ActivityLog::record('user', "Pengguna baru mendaftar: {$user->name}", $user);
        }

        abort_unless($user->is_active, 403, 'Akun Anda dinonaktifkan. Hubungi admin SADAQO.');

        return $user;
    }

    private function respond(User $user): JsonResponse
    {
        return response()->json([
            'message' => 'Berhasil masuk',
            'token' => $user->createToken('mobile')->plainTextToken,
            'user' => (new UserResource($user->load('avatarAsset')))->resolve(),
        ]);
    }
}
