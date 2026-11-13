<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AssetResource;
use App\Models\Asset;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Storage;

/**
 * Registri gambar. Semua gambar (bawaan app maupun unggahan admin/pengelola)
 * tercatat di tabel assets.
 */
class AssetController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Asset::query()->orderBy('group')->orderBy('file_name');

        if ($group = $request->query('group')) {
            $query->where('group', $group);
        }
        if ($source = $request->query('source')) {
            $query->where('source', $source);
        }

        return AssetResource::collection($query->get());
    }

    public function show(Asset $asset): AssetResource
    {
        return new AssetResource($asset);
    }

    /** Unggah gambar (admin & pengelola). Multipart: file, group, alt_text(opsional). */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'file' => ['required', 'file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:3072'],
            'group' => ['required', 'in:program,news,report,avatar,other'],
            'alt_text' => ['nullable', 'string', 'max:255'],
        ], [
            'file.required' => 'Pilih gambar terlebih dahulu',
            'file.image' => 'File harus berupa gambar',
            'file.mimes' => 'Format gambar harus JPG, PNG, atau WebP',
            'file.max' => 'Ukuran gambar maksimal 3 MB',
        ]);

        $file = $request->file('file');
        $realPath = $file->getRealPath();
        $checksum = hash_file('sha256', $realPath);

        // Gambar yang sama persis tidak disimpan dua kali; pakai baris yang sudah terdaftar.
        $existing = Asset::where('checksum', $checksum)->first();
        if ($existing) {
            return response()->json([
                'message' => 'Gambar yang sama sudah terdaftar.',
                'duplicate' => true,
                'data' => (new AssetResource($existing))->resolve(),
            ]);
        }

        $size = @getimagesize($realPath);
        $width = $size[0] ?? null;
        $height = $size[1] ?? null;
        $mime = $file->getMimeType();
        $bytes = $file->getSize();
        $originalName = basename((string) $file->getClientOriginalName());

        $group = $request->input('group');
        $path = $file->store("uploads/{$group}", 'public'); // nama file diacak oleh Laravel

        $asset = Asset::create([
            'path' => $path,
            'file_name' => $originalName !== '' ? $originalName : basename($path),
            'group' => $group,
            'source' => Asset::SOURCE_UPLOADED,
            'mime_type' => $mime,
            'size_bytes' => $bytes,
            'width' => $width,
            'height' => $height,
            'checksum' => $checksum,
            'alt_text' => $request->input('alt_text'),
            'uploaded_by' => $request->user()->id,
        ]);

        return response()->json([
            'message' => 'Gambar berhasil diunggah',
            'duplicate' => false,
            'data' => (new AssetResource($asset))->resolve(),
        ], 201);
    }

    public function destroy(Asset $asset): JsonResponse
    {
        if ($asset->source !== Asset::SOURCE_UPLOADED) {
            return response()->json(['message' => 'Aset bawaan aplikasi tidak dapat dihapus.'], 422);
        }

        if ($asset->isInUse()) {
            return response()->json(['message' => 'Gambar masih dipakai oleh program, berita, atau laporan.'], 409);
        }

        Storage::disk('public')->delete($asset->path);
        $asset->delete();

        return response()->json(['message' => 'Gambar dihapus']);
    }
}
