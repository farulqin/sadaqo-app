<?php

namespace Database\Seeders;

use App\Models\Asset;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

/**
 * Mendaftarkan SEMUA gambar di folder assets/ milik Flutter ke tabel assets
 * (source = bundled). Aman dijalankan berulang kali (updateOrCreate per path).
 */
class AssetSeeder extends Seeder
{
    public function run(): void
    {
        // backend/ berada di dalam repo, jadi folder assets Flutter ada satu tingkat di atasnya.
        $root = realpath(base_path('../assets'));

        if ($root === false) {
            $this->command?->warn('Folder ../assets (Flutter) tidak ditemukan. Aset bawaan tidak didaftarkan.');

            return;
        }

        $count = 0;

        foreach (File::allFiles($root) as $file) {
            $ext = strtolower($file->getExtension());
            if (!in_array($ext, ['png', 'jpg', 'jpeg', 'webp'], true)) {
                continue;
            }

            $path = 'assets/' . str_replace('\\', '/', $file->getRelativePathname());
            $folder = basename(dirname($path));
            $group = $folder === 'images' ? 'logo' : $folder; // assets/images/logo_*.png -> grup "logo"

            $info = @getimagesize($file->getPathname());

            Asset::updateOrCreate(
                ['path' => $path],
                [
                    'file_name' => $file->getFilename(),
                    'group' => $group,
                    'source' => Asset::SOURCE_BUNDLED,
                    'mime_type' => mime_content_type($file->getPathname()) ?: null,
                    'size_bytes' => $file->getSize(),
                    'width' => $info[0] ?? null,
                    'height' => $info[1] ?? null,
                    'checksum' => hash_file('sha256', $file->getPathname()),
                    'alt_text' => Str::of($file->getFilenameWithoutExtension())->replace('_', ' ')->title()->toString(),
                    'uploaded_by' => null,
                ]
            );

            $count++;
        }

        $this->command?->info("{$count} aset bawaan Flutter terdaftar di tabel assets.");
    }
}
