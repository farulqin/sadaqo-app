<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('community_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('body', 300);
            $table->boolean('is_hidden')->default(false);
            $table->timestamps();

            $table->index('created_at');
        });

        Schema::create('message_reactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('community_message_id')->constrained('community_messages')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('emoji', 16);
            $table->timestamps();

            $table->unique(['community_message_id', 'user_id', 'emoji']);
        });

        // Laporan pengguna terhadap sebuah pesan (ditinjau admin).
        Schema::create('community_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('community_message_id')->constrained('community_messages')->cascadeOnDelete();
            $table->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->string('reason', 255)->nullable();
            $table->enum('status', ['pending', 'valid', 'dismissed'])->default('pending')->index();
            $table->timestamps();
        });

        // Pelanggaran terdeteksi (hoaks, scam, dll); dasar perhitungan strike dan banned.
        Schema::create('community_violations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('community_message_id')->nullable()->constrained('community_messages')->nullOnDelete();
            $table->enum('type', ['hoax', 'hate', 'scam', 'porn', 'blasphemy', 'profanity']);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('community_violations');
        Schema::dropIfExists('community_reports');
        Schema::dropIfExists('message_reactions');
        Schema::dropIfExists('community_messages');
    }
};
