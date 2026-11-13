<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $request->merge(['email' => strtolower(trim((string) $request->input('email')))]);

        $data = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:100'],
            'email' => ['required', 'email', 'max:150', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6', 'max:100'],
        ], [
            'name.required' => 'Nama wajib diisi',
            'email.required' => 'Email wajib diisi',
            'email.email' => 'Format email tidak valid',
            'email.unique' => 'Email sudah terdaftar, silakan masuk',
            'password.required' => 'Password wajib diisi',
            'password.min' => 'Password minimal 6 karakter',
        ]);

        // Pendaftaran publik selalu menjadi donatur. Admin dan pengelola hanya dibuat lewat seeder/admin.
        $user = User::create([
            'name' => trim($data['name']),
            'email' => $data['email'],
            'password' => $data['password'],
            'role' => User::ROLE_DONATUR,
        ]);

        ActivityLog::record('user', "Pengguna baru mendaftar: {$user->name}", $user);

        return response()->json([
            'message' => 'Pendaftaran berhasil',
            'token' => $user->createToken('mobile')->plainTextToken,
            'user' => (new UserResource($user))->resolve(),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'string'],
            'password' => ['required', 'string'],
        ], [
            'email.required' => 'Email wajib diisi',
            'password.required' => 'Password wajib diisi',
        ]);

        $user = User::with('avatarAsset')
            ->where('email', strtolower(trim($data['email'])))
            ->first();

        if (!$user || !Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Email atau password salah'], 401);
        }

        if (!$user->is_active) {
            return response()->json(['message' => 'Akun Anda dinonaktifkan. Hubungi admin SADAQO.'], 403);
        }

        return response()->json([
            'message' => 'Berhasil masuk',
            'token' => $user->createToken('mobile')->plainTextToken,
            'user' => (new UserResource($user))->resolve(),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load('avatarAsset');

        return response()->json(['user' => (new UserResource($user))->resolve()]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($request->has('phone') && $request->input('phone') !== null) {
            // Spasi dan tanda hubung diabaikan, seperti validasi di Flutter.
            $request->merge(['phone' => preg_replace('/[\s\-]/', '', (string) $request->input('phone'))]);
        }

        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'min:3', 'max:100'],
            // Pengelola wajib punya nomor HP supaya bisa dihubungi admin.
            'phone' => [$user->isPengelola() ? 'required' : 'nullable', 'regex:/^(\+62|62|0)8\d{8,11}$/'],
            'gender' => ['sometimes', 'nullable', 'in:male,female'],
            'avatar_asset_id' => [
                'sometimes',
                'nullable',
                Rule::exists('assets', 'id')->where('group', 'avatar'),
            ],
        ], [
            'name.min' => 'Nama minimal 3 karakter',
            'phone.required' => 'Nomor telepon wajib diisi',
            'phone.regex' => 'Gunakan nomor HP Indonesia, contoh 0812-3456-7890',
            'avatar_asset_id.exists' => 'Avatar tidak valid',
        ]);

        $user->update($data);

        return response()->json([
            'message' => 'Profil diperbarui',
            'user' => (new UserResource($user->load('avatarAsset')))->resolve(),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Berhasil keluar']);
    }
}
