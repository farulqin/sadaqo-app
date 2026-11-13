<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone', 20)->nullable()->after('email');
            $table->enum('gender', ['male', 'female'])->nullable()->after('phone');
            $table->enum('role', ['donatur', 'pengelola', 'admin'])->default('donatur')->index()->after('gender');
            $table->foreignId('avatar_asset_id')->nullable()->after('role')->constrained('assets')->nullOnDelete();
            $table->unsignedTinyInteger('strikes')->default(0);
            $table->timestamp('banned_until')->nullable();
            $table->boolean('is_active')->default(true);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('avatar_asset_id');
            $table->dropColumn(['phone', 'gender', 'role', 'strikes', 'banned_until', 'is_active']);
        });
    }
};
