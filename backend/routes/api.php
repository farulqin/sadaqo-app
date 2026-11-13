<?php

use App\Http\Controllers\Api\AssetController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CampaignController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DonationController;
use App\Http\Controllers\Api\NewsController;
use App\Http\Controllers\Api\PaymentProviderController;
use App\Http\Middleware\RoleMiddleware;
use Illuminate\Support\Facades\Route;

// Semua rute di sini otomatis berawalan /api

Route::get('/ping', fn () => ['status' => 'ok', 'app' => 'SADAQO']);

// ===== Publik =====
Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/payment-providers', [PaymentProviderController::class, 'index']);

Route::get('/campaigns', [CampaignController::class, 'index']);
Route::get('/campaigns/{campaign}', [CampaignController::class, 'show'])->whereNumber('campaign');

Route::get('/news', [NewsController::class, 'index']);
Route::get('/news/{news}', [NewsController::class, 'show'])->whereNumber('news');

// ===== Harus login (Bearer token) =====
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/me', [AuthController::class, 'updateProfile']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/donations', [DonationController::class, 'index']);
    Route::post('/donations', [DonationController::class, 'store']);

    Route::get('/assets', [AssetController::class, 'index']);
    Route::get('/assets/{asset}', [AssetController::class, 'show'])->whereNumber('asset');

    // ----- Admin & Pengelola -----
    Route::middleware(RoleMiddleware::class . ':admin,pengelola')->group(function () {
        Route::post('/assets', [AssetController::class, 'store']);

        Route::get('/campaigns/mine', [CampaignController::class, 'mine']);
        Route::post('/campaigns', [CampaignController::class, 'store']);
        Route::put('/campaigns/{campaign}', [CampaignController::class, 'update'])->whereNumber('campaign');
    });

    // ----- Admin saja -----
    Route::middleware(RoleMiddleware::class . ':admin')->group(function () {
        Route::get('/admin/campaigns', [CampaignController::class, 'adminIndex']);
        Route::get('/admin/donations', [DonationController::class, 'adminIndex']);

        Route::patch('/campaigns/{campaign}/review', [CampaignController::class, 'review'])->whereNumber('campaign');
        Route::delete('/campaigns/{campaign}', [CampaignController::class, 'destroy'])->whereNumber('campaign');

        Route::post('/news', [NewsController::class, 'store']);
        Route::put('/news/{news}', [NewsController::class, 'update'])->whereNumber('news');
        Route::delete('/news/{news}', [NewsController::class, 'destroy'])->whereNumber('news');

        Route::delete('/assets/{asset}', [AssetController::class, 'destroy'])->whereNumber('asset');
        Route::put('/categories/{category}', [CategoryController::class, 'update'])->whereNumber('category');
    });
});
