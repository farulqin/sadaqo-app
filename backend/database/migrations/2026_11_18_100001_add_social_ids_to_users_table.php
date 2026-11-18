<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // ID akun dari penyedia login (sub). Kosong untuk akun email biasa.
            $table->string('google_id', 64)->nullable()->unique()->after('email');
            $table->string('apple_id', 128)->nullable()->unique()->after('google_id');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['google_id']);
            $table->dropUnique(['apple_id']);
            $table->dropColumn(['google_id', 'apple_id']);
        });
    }
};
