<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesFixtures;
use Tests\TestCase;

class CommunityTest extends TestCase
{
    use RefreshDatabase, CreatesFixtures;

    public function test_non_member_cannot_post_until_joining(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/community/posts', ['category' => 'diskusi', 'body' => 'Halo semuanya'])
            ->assertForbidden();

        $this->postJson('/api/community/join')->assertOk();

        $this->postJson('/api/community/posts', ['category' => 'diskusi', 'body' => 'Halo semuanya'])
            ->assertCreated();
    }

    public function test_info_category_is_for_admin_and_pengelola_only(): void
    {
        $donatur = User::factory()->create();
        Sanctum::actingAs($donatur);
        $this->postJson('/api/community/join')->assertOk();
        $this->postJson('/api/community/posts', ['category' => 'info', 'body' => 'Pengumuman palsu'])
            ->assertForbidden();

        $this->app['auth']->forgetGuards();
        Sanctum::actingAs(User::factory()->admin()->create());
        $this->postJson('/api/community/posts', ['category' => 'info', 'body' => 'Pengumuman resmi'])
            ->assertCreated();
    }

    public function test_admin_can_create_poll_and_member_votes_only_once(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create());
        $this->postJson('/api/community/posts', [
            'category' => 'diskusi',
            'body' => 'Mari berpendapat',
            'poll' => ['question' => 'Program favoritmu apa?', 'options' => ['Masjid', 'Qurban'], 'days' => 3],
        ])->assertCreated();

        $pollId = DB::table('community_polls')->value('id');
        $optionId = DB::table('community_poll_options')->where('poll_id', $pollId)->value('id');

        $this->app['auth']->forgetGuards();
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/community/join')->assertOk();

        $this->postJson("/api/community/polls/{$pollId}/vote", ['option_id' => $optionId])->assertOk();
        $this->postJson("/api/community/polls/{$pollId}/vote", ['option_id' => $optionId])->assertStatus(409);
    }

    public function test_poll_requires_at_least_two_options(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->postJson('/api/community/posts', [
            'category' => 'diskusi',
            'body' => 'Polling tidak valid',
            'poll' => ['question' => 'Pilih satu saja?', 'options' => ['Satu']],
        ])->assertStatus(422);
    }

    public function test_only_admin_can_pin_posts(): void
    {
        $author = User::factory()->create();
        $postId = $this->makePost($author->id);

        Sanctum::actingAs($author);
        $this->postJson("/api/community/posts/{$postId}/pin")->assertForbidden();

        $this->app['auth']->forgetGuards();
        Sanctum::actingAs(User::factory()->admin()->create());
        $this->postJson("/api/community/posts/{$postId}/pin")->assertOk();
        $this->assertDatabaseHas('community_posts', ['id' => $postId, 'is_pinned' => true]);
    }

    public function test_admin_can_delete_any_post_but_members_only_their_own(): void
    {
        $author = User::factory()->create();
        $other = User::factory()->create();
        $postId = $this->makePost($author->id);

        Sanctum::actingAs($other);
        $this->deleteJson("/api/community/posts/{$postId}")->assertForbidden();

        $this->app['auth']->forgetGuards();
        Sanctum::actingAs(User::factory()->admin()->create());
        $this->deleteJson("/api/community/posts/{$postId}")->assertOk();
        $this->assertDatabaseMissing('community_posts', ['id' => $postId]);
    }

    public function test_admin_can_comment_and_delete_user_comment(): void
    {
        $author = User::factory()->create();
        $postId = $this->makePost($author->id);
        $commentId = DB::table('community_comments')->insertGetId([
            'post_id' => $postId, 'user_id' => $author->id, 'body' => 'Komentar anggota',
            'created_at' => now(), 'updated_at' => now(),
        ]);

        Sanctum::actingAs(User::factory()->admin()->create());
        $this->postJson("/api/community/posts/{$postId}/comments", ['body' => 'Balasan admin'])->assertSuccessful();
        $this->deleteJson("/api/community/comments/{$commentId}")->assertOk();
        $this->assertDatabaseMissing('community_comments', ['id' => $commentId]);
    }
}