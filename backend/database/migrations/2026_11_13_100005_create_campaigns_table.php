<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('campaigns', function (Blueprint $table) {
            $table->id();
            $table->string('code', 20)->nullable()->unique(); // kode lama dari data contoh Flutter (m1, s1, q5, ...)
            $table->foreignId('category_id')->constrained('categories');
            $table->foreignId('owner_id')->nullable()->constrained('users')->nullOnDelete(); // pengelola pengaju
            $table->string('title');
            $table->text('description');
            $table->string('sub_type', 60)->nullable();
            $table->string('location');
            $table->unsignedBigInteger('target_amount');
            $table->unsignedBigInteger('collected_amount')->default(0);
            $table->dateTime('deadline');
            $table->unsignedBigInteger('unit_price')->nullable(); // harga tetap per unit (qurban)
            $table->string('unit_label', 20)->nullable();         // ekor / slot
            $table->unsignedInteger('slot_total')->nullable();
            $table->unsignedInteger('slot_filled')->nullable();
            $table->foreignId('image_asset_id')->nullable()->constrained('assets')->nullOnDelete();
            $table->text('supporting_info')->nullable();
            $table->enum('status', ['pending', 'active', 'rejected', 'closed'])->default('pending')->index();
            $table->text('review_note')->nullable();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();

            $table->index(['category_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('campaigns');
    }
};
