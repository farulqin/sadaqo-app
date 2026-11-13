<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('campaign_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('campaign_id')->constrained('campaigns')->cascadeOnDelete();
            $table->foreignId('manager_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('title');
            $table->text('summary');
            $table->unsignedBigInteger('distributed_amount')->default(0);
            $table->unsignedInteger('beneficiaries')->default(0);
            $table->date('activity_date');
            $table->enum('status', ['pending', 'approved', 'revision'])->default('pending')->index();
            $table->text('admin_note')->nullable();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
        });

        // Foto laporan: setiap foto adalah baris di tabel assets.
        Schema::create('report_photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('campaign_report_id')->constrained('campaign_reports')->cascadeOnDelete();
            $table->foreignId('asset_id')->constrained('assets')->restrictOnDelete();
            $table->enum('type', ['activity', 'proof']);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('report_photos');
        Schema::dropIfExists('campaign_reports');
    }
};
