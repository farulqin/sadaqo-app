<?php

namespace Tests\Feature;

use App\Models\Campaign;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesFixtures;
use Tests\TestCase;

class CampaignReviewTest extends TestCase
{
    use RefreshDatabase, CreatesFixtures;

    private function payload(): array
    {
        return [
            'title' => 'Renovasi Mushola Desa',
            'category' => 'sosial',
            'description' => 'Renovasi mushola desa agar nyaman dipakai warga.',
            'location' => 'Demak',
            'target_amount' => 5_000_000,
            'duration_days' => 30,
        ];
    }

    public function test_pengelola_submission_starts_as_pending(): void
    {
        $this->category('sosial');
        Sanctum::actingAs(User::factory()->pengelola()->create());

        $this->postJson('/api/campaigns', $this->payload())->assertCreated();

        $this->assertDatabaseHas('campaigns', ['title' => 'Renovasi Mushola Desa', 'status' => 'pending']);
    }

    public function test_admin_created_campaign_is_active_immediately(): void
    {
        $this->category('sosial');
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->postJson('/api/campaigns', $this->payload())->assertCreated();

        $this->assertDatabaseHas('campaigns', ['title' => 'Renovasi Mushola Desa', 'status' => 'active']);
    }

    public function test_donatur_cannot_create_or_review_campaigns(): void
    {
        $this->category('sosial');
        $c = $this->campaign(['status' => Campaign::STATUS_PENDING]);
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/campaigns', $this->payload())->assertForbidden();
        $this->patchJson("/api/campaigns/{$c->id}/review", ['decision' => 'approve'])->assertForbidden();
    }

    public function test_admin_can_approve_pending_campaign(): void
    {
        $c = $this->campaign(['status' => Campaign::STATUS_PENDING]);
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->patchJson("/api/campaigns/{$c->id}/review", ['decision' => 'approve'])->assertOk();

        $this->assertSame(Campaign::STATUS_ACTIVE, $c->fresh()->status);
    }

    public function test_rejection_requires_a_note(): void
    {
        $c = $this->campaign(['status' => Campaign::STATUS_PENDING]);
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->patchJson("/api/campaigns/{$c->id}/review", ['decision' => 'reject'])
            ->assertStatus(422)->assertJsonValidationErrors(['note']);

        $this->patchJson("/api/campaigns/{$c->id}/review", ['decision' => 'reject', 'note' => 'Data belum lengkap'])
            ->assertOk();

        $this->assertSame(Campaign::STATUS_REJECTED, $c->fresh()->status);
    }
}