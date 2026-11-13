<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Registri SEMUA gambar SADAQO.
 * - source = bundled  : file ada di folder assets/ milik Flutter (path = 'assets/images/...')
 * - source = uploaded : file diunggah admin/pengelola lewat API (path = 'uploads/{group}/{nama-acak}.jpg')
 * Tabel lain (campaigns, news, categories, users, report_photos) hanya boleh menunjuk
 * gambar lewat foreign key ke tabel ini.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('assets', function (Blueprint $table) {
            $table->id();
            $table->string('path')->unique();
            $table->string('file_name');
            $table->string('group', 40)->index();
            $table->enum('source', ['bundled', 'uploaded'])->default('uploaded')->index();
            $table->string('mime_type', 80)->nullable();
            $table->unsignedBigInteger('size_bytes')->default(0);
            $table->unsignedInteger('width')->nullable();
            $table->unsignedInteger('height')->nullable();
            $table->string('checksum', 64)->nullable()->index();
            $table->string('alt_text')->nullable();
            $table->foreignId('uploaded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('assets');
    }
};
