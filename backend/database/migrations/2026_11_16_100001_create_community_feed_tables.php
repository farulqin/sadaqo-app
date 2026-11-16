<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Keanggotaan komunitas (admin dan pengelola otomatis anggota, tidak perlu baris).
        Schema::create('community_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->timestamps();
        });

        Schema::create('community_posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('category', ['diskusi', 'info'])->default('diskusi')->index();
            $table->text('body');
            $table->foreignId('image_asset_id')->nullable()->constrained('assets')->nullOnDelete();
            $table->boolean('is_pinned')->default(false);
            $table->boolean('is_hidden')->default(false);
            $table->timestamps();

            $table->index(['is_hidden', 'created_at']);
        });

        // Apresiasi (suka) pada post.
        Schema::create('community_post_likes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('post_id')->constrained('community_posts')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['post_id', 'user_id']);
        });

        // Komentar; parent_id terisi bila berupa balasan.
        Schema::create('community_comments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('post_id')->constrained('community_posts')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('parent_id')->nullable()->constrained('community_comments')->cascadeOnDelete();
            $table->string('body', 500);
            $table->boolean('is_hidden')->default(false);
            $table->timestamps();

            $table->index(['post_id', 'created_at']);
        });

        // Polling (satu per post).
        Schema::create('community_polls', function (Blueprint $table) {
            $table->id();
            $table->foreignId('post_id')->unique()->constrained('community_posts')->cascadeOnDelete();
            $table->string('question', 200);
            $table->dateTime('ends_at');
            $table->timestamps();
        });

        Schema::create('community_poll_options', function (Blueprint $table) {
            $table->id();
            $table->foreignId('poll_id')->constrained('community_polls')->cascadeOnDelete();
            $table->string('label', 100);
            $table->unsignedTinyInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('community_poll_votes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('poll_id')->constrained('community_polls')->cascadeOnDelete();
            $table->foreignId('option_id')->constrained('community_poll_options')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['poll_id', 'user_id']); // satu suara per pengguna
        });

        // Agenda kegiatan komunitas.
        Schema::create('community_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->string('title', 150);
            $table->text('description')->nullable();
            $table->string('location', 150);
            $table->boolean('is_online')->default(false);
            $table->dateTime('starts_at')->index();
            $table->dateTime('ends_at')->nullable();
            $table->foreignId('image_asset_id')->nullable()->constrained('assets')->nullOnDelete();
            $table->timestamps();
        });

        Schema::create('community_event_interests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('event_id')->constrained('community_events')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['event_id', 'user_id']);
        });

        // Laporan pengguna terhadap post atau komentar (ditinjau admin).
        Schema::create('community_post_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('post_id')->nullable()->constrained('community_posts')->cascadeOnDelete();
            $table->foreignId('comment_id')->nullable()->constrained('community_comments')->cascadeOnDelete();
            $table->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->string('reason', 255)->nullable();
            $table->enum('status', ['pending', 'valid', 'dismissed'])->default('pending')->index();
            $table->timestamps();
        });

        // Notifikasi: tipe (untuk tab Aktivitas/Sistem) dan tujuan buka.
        Schema::table('app_notifications', function (Blueprint $table) {
            $table->string('type', 20)->default('system')->index();
            $table->string('ref_type', 30)->nullable();
            $table->unsignedBigInteger('ref_id')->nullable();
        });

        // Status online anggota.
        Schema::table('users', function (Blueprint $table) {
            $table->timestamp('last_seen_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('last_seen_at');
        });
        Schema::table('app_notifications', function (Blueprint $table) {
            $table->dropColumn(['type', 'ref_type', 'ref_id']);
        });
        Schema::dropIfExists('community_post_reports');
        Schema::dropIfExists('community_event_interests');
        Schema::dropIfExists('community_events');
        Schema::dropIfExists('community_poll_votes');
        Schema::dropIfExists('community_poll_options');
        Schema::dropIfExists('community_polls');
        Schema::dropIfExists('community_comments');
        Schema::dropIfExists('community_post_likes');
        Schema::dropIfExists('community_posts');
        Schema::dropIfExists('community_members');
    }
};