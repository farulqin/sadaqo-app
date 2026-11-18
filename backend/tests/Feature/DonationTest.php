<?php

namespace Tests\Feature;

use App\Models\Campaign;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesFixtures;
use Tests\TestCase;

class DonationTest extends TestCase
{
    use RefreshDatabase, CreatesFixtures;

    public function test_guest_cannot_donate(): void
    {
        $c = $this->campaign();

        $this->postJson('/api/donations', [
            'campaign_id' => $c->id, 'amount' => 50000, 'payment_method' => 'qris',
        ])->assertUnauthorized();
    }

    public function test_donation_via_qris_updates_campaign_total(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $c = $this->campaign();

        $this->postJson('/api/donations', [
            'campaign_id' => $c->id, 'amount' => 50000, 'payment_method' => 'qris',
        ])->assertCreated();

        $this->assertDatabaseHas('donations', ['campaign_id' => $c->id, 'amount' => 50000, 'status' => 'success']);
        $this->assertSame(50000, (int) $c->fresh()->collected_amount);
    }

    public function test_amount_below_minimum_is_rejected(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $c = $this->campaign();

        $this->postJson('/api/donations', [
            'campaign_id' => $c->id, 'amount' => 1000, 'payment_method' => 'qris',
        ])->assertStatus(422);

        $this->assertDatabaseCount('donations', 0);
    }

    public function test_ewallet_requires_registered_provider(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $c = $this->campaign();

        $this->postJson('/api/donations', [
            'campaign_id' => $c->id, 'amount' => 50000, 'payment_method' => 'ewallet',
        ])->assertStatus(422)->assertJsonValidationErrors(['payment_provider']);

        $this->provider('ewallet', 'GoPay');

        $this->postJson('/api/donations', [
            'campaign_id' => $c->id, 'amount' => 50000, 'payment_method' => 'ewallet', 'payment_provider' => 'GoPay',
        ])->assertCreated();
    }

    public function test_pending_campaign_does_not_accept_donations(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $c = $this->campaign(['status' => Campaign::STATUS_PENDING]);

        $this->postJson('/api/donations', [
            'campaign_id' => $c->id, 'amount' => 50000, 'payment_method' => 'qris',
        ])->assertStatus(422);
    }

    public function test_campaign_closes_automatically_when_target_reached(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $c = $this->campaign(['target_amount' => 100000]);

        $this->postJson('/api/donations', [
            'campaign_id' => $c->id, 'amount' => 100000, 'payment_method' => 'qris',
        ])->assertCreated();

        $this->assertSame(Campaign::STATUS_CLOSED, $c->fresh()->status);
    }

    public function test_qurban_amount_must_be_multiple_of_unit_price_and_fills_slots(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $c = $this->campaign([
            'target_amount' => 50_000_000,
            'unit_price' => 2_000_000,
            'unit_label' => 'ekor',
            'slot_total' => 5,
            'slot_filled' => 0,
        ]);

        $this->postJson('/api/donations', [
            'campaign_id' => $c->id, 'amount' => 3_500_000, 'payment_method' => 'qris',
        ])->assertStatus(422);

        $this->postJson('/api/donations', [
            'campaign_id' => $c->id, 'amount' => 4_000_000, 'payment_method' => 'qris',
        ])->assertCreated();

        $this->assertSame(2, (int) $c->fresh()->slot_filled);
    }

    public function test_history_only_shows_own_donations(): void
    {
        $a = User::factory()->create();
        $b = User::factory()->create();
        $c = $this->campaign();

        Sanctum::actingAs($a);
        $this->postJson('/api/donations', [
            'campaign_id' => $c->id, 'amount' => 50000, 'payment_method' => 'qris',
        ])->assertCreated();
        $this->getJson('/api/donations')->assertOk()->assertJsonCount(1, 'data');

        $this->app['auth']->forgetGuards();
        Sanctum::actingAs($b);
        $this->getJson('/api/donations')->assertOk()->assertJsonCount(0, 'data');
    }
}