<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesFixtures;
use Tests\TestCase;

class ModerationTest extends TestCase
{
    use RefreshDatabase, CreatesFixtures;

    public function test_donatur_cannot_use_moderation_endpoints(): void
    {
        $target = User::factory()->create();
        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/admin/users/{$target->id}/warn")->assertForbidden();
        $this->postJson("/api/admin/users/{$target->id}/ban", ['days' => 7])->assertForbidden();
        $this->postJson("/api/admin/users/{$target->id}/lift")->assertForbidden();
    }

    public function test_second_warning_bans_user_for_thirty_days(): void
    {
        $target = User::factory()->create();
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->postJson("/api/admin/users/{$target->id}/warn", ['note' => 'Jaga ucapan'])->assertOk();
        $target->refresh();
        $this->assertSame(1, (int) $target->strikes);
        $this->assertNull($target->banned_until);

        $this->postJson("/api/admin/users/{$target->id}/warn")->assertOk();
        $target->refresh();
        $this->assertSame(2, (int) $target->strikes);
        $this->assertTrue($target->banned_until->isFuture());
    }

    public function test_banned_user_cannot_post_or_comment(): void
    {
        $banned = User::factory()->banned()->create();
        DB::table('community_members')->insert([
            'user_id' => $banned->id, 'created_at' => now(), 'updated_at' => now(),
        ]);
        $postId = $this->makePost($banned->id);
        Sanctum::actingAs($banned);

        $this->postJson('/api/community/posts', ['category' => 'diskusi', 'body' => 'Halo lagi'])
            ->assertForbidden();
        $this->postJson("/api/community/posts/{$postId}/comments", ['body' => 'Komentar'])
            ->assertForbidden();
    }

    public function test_admin_can_ban_with_custom_days_and_lift_it(): void
    {
        $target = User::factory()->create();
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->postJson("/api/admin/users/{$target->id}/ban", ['days' => 7, 'reason' => 'Spam'])->assertOk();
        $this->assertTrue($target->fresh()->banned_until->isFuture());

        $this->postJson("/api/admin/users/{$target->id}/lift")->assertOk();
        $target->refresh();
        $this->assertNull($target->banned_until);
        $this->assertSame(0, (int) $target->strikes);
    }

    public function test_admin_account_cannot_be_moderated(): void
    {
        $otherAdmin = User::factory()->admin()->create();
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->postJson("/api/admin/users/{$otherAdmin->id}/warn")->assertStatus(422);
        $this->postJson("/api/admin/users/{$otherAdmin->id}/ban", ['days' => 7])->assertStatus(422);
    }

    public function test_forbidden_content_is_rejected_and_counts_as_strike(): void
    {
        $member = User::factory()->create();
        DB::table('community_members')->insert([
            'user_id' => $member->id, 'created_at' => now(), 'updated_at' => now(),
        ]);
        Sanctum::actingAs($member);

        $this->postJson('/api/community/posts', ['category' => 'diskusi', 'body' => 'tolong kirim otp ke saya'])
            ->assertStatus(422);
        $this->assertSame(1, (int) $member->fresh()->strikes);

        $this->postJson('/api/community/posts', ['category' => 'diskusi', 'body' => 'kirim otp sekarang juga'])
            ->assertStatus(422);
        $member->refresh();
        $this->assertSame(2, (int) $member->strikes);
        $this->assertTrue($member->banned_until->isFuture());
    }

    public function test_valid_report_hides_post_and_penalizes_author(): void
    {
        $author = User::factory()->create();
        $reporter = User::factory()->create();
        $postId = $this->makePost($author->id, 'Berita bohong tentang donasi');
        $reportId = DB::table('community_post_reports')->insertGetId([
            'post_id' => $postId, 'reporter_id' => $reporter->id, 'reason' => 'Hoaks',
            'status' => 'pending', 'created_at' => now(), 'updated_at' => now(),
        ]);

        Sanctum::actingAs(User::factory()->admin()->create());
        $this->patchJson("/api/admin/community/reports/{$reportId}", [
            'decision' => 'valid', 'violation_type' => 'hoax',
        ])->assertOk();

        $this->assertDatabaseHas('community_posts', ['id' => $postId, 'is_hidden' => true]);
        $this->assertSame(1, (int) $author->fresh()->strikes);
        $this->assertDatabaseHas('community_post_reports', ['id' => $reportId, 'status' => 'valid']);
    }

    public function test_dismissed_report_leaves_post_visible(): void
    {
        $author = User::factory()->create();
        $reporter = User::factory()->create();
        $postId = $this->makePost($author->id);
        $reportId = DB::table('community_post_reports')->insertGetId([
            'post_id' => $postId, 'reporter_id' => $reporter->id, 'reason' => 'Salah paham',
            'status' => 'pending', 'created_at' => now(), 'updated_at' => now(),
        ]);

        Sanctum::actingAs(User::factory()->admin()->create());
        $this->patchJson("/api/admin/community/reports/{$reportId}", ['decision' => 'dismissed'])->assertOk();

        $this->assertDatabaseHas('community_posts', ['id' => $postId, 'is_hidden' => false]);
        $this->assertSame(0, (int) $author->fresh()->strikes);
    }
}