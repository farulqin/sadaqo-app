<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->string('slug', 30)->unique(); // masjid, sosial, zakat, duafa, qurban (= ProgramCategory.key di Flutter)
            $table->string('label', 60);
            $table->string('short_label', 30);
            $table->foreignId('icon_asset_id')->nullable()->constrained('assets')->nullOnDelete();
            $table->string('color_start', 7);
            $table->string('color_end', 7);
            $table->unsignedTinyInteger('sort_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
