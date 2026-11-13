<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('donations', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 30)->unique(); // contoh: SDQ-261113-A1B2C3
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('campaign_id')->constrained('campaigns')->restrictOnDelete();
            $table->unsignedBigInteger('amount');
            $table->enum('payment_method', ['qris', 'ewallet', 'transfer']);
            $table->foreignId('payment_provider_id')->nullable()->constrained('payment_providers')->nullOnDelete();
            $table->enum('status', ['success', 'pending', 'failed'])->default('pending');
            $table->string('donor_name', 100)->default('Hamba Allah');
            $table->boolean('is_anonymous')->default(false);
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();

            $table->index(['campaign_id', 'status']);
            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('donations');
    }
};
