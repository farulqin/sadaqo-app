<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_ping_endpoint_responds_ok(): void
    {
        $this->getJson('/api/ping')->assertOk()->assertJson(['status' => 'ok', 'app' => 'SADAQO']);
    }

    public function test_user_can_register_as_donatur_and_gets_token(): void
    {
        $res = $this->postJson('/api/register', [
            'name' => 'Farid Ulil',
            'email' => 'Farid@Example.com',
            'password' => 'rahasia123',
        ]);

        $res->assertCreated()->assertJsonStructure(['message', 'token', 'user']);
        $this->assertDatabaseHas('users', ['email' => 'farid@example.com', 'role' => 'donatur']);
    }

    public function test_register_cannot_self_assign_admin_role(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Penyusup',
            'email' => 'penyusup@example.com',
            'password' => 'rahasia123',
            'role' => 'admin',
        ])->assertCreated();

        $this->assertDatabaseHas('users', ['email' => 'penyusup@example.com', 'role' => 'donatur']);
    }

    public function test_register_rejects_duplicate_email_and_short_password(): void
    {
        User::factory()->create(['email' => 'ada@example.com']);

        $this->postJson('/api/register', [
            'name' => 'Dobel',
            'email' => 'ada@example.com',
            'password' => '123',
        ])->assertStatus(422)->assertJsonValidationErrors(['email', 'password']);
    }

    public function test_login_success_and_wrong_password(): void
    {
        User::factory()->create(['email' => 'budi@example.com']); // password: "password"

        $this->postJson('/api/login', ['email' => 'budi@example.com', 'password' => 'password'])
            ->assertOk()
            ->assertJsonStructure(['token', 'user']);

        $this->postJson('/api/login', ['email' => 'budi@example.com', 'password' => 'salah'])
            ->assertStatus(401);
    }

    public function test_inactive_account_cannot_login(): void
    {
        User::factory()->inactive()->create(['email' => 'nonaktif@example.com']);

        $this->postJson('/api/login', ['email' => 'nonaktif@example.com', 'password' => 'password'])
            ->assertStatus(403);
    }

    public function test_me_requires_token_and_returns_profile(): void
    {
        $this->getJson('/api/me')->assertUnauthorized();

        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('user.email', $user->email);
    }

    public function test_logout_revokes_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/logout')->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }
}