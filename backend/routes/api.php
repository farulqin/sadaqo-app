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
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\SocialAuthController;
use App\Http\Controllers\Api\FavoriteController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\AdminUserController;
use App\Http\Controllers\Api\CommunityCommentController;
use App\Http\Controllers\Api\CommunityController;
use App\Http\Controllers\Api\CommunityEventController;
use App\Http\Controllers\Api\CommunityModerationController;
use App\Http\Controllers\Api\CommunityPostController;

// Semua rute di sini otomatis berawalan /api

Route::get('/ping', fn () => ['status' => 'ok', 'app' => 'SADAQO']);

// ===== Publik =====
Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
Route::post('/auth/google', [SocialAuthController::class, 'google'])->middleware('throttle:20,1');
Route::post('/auth/apple', [SocialAuthController::class, 'apple'])->middleware('throttle:20,1');

Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/payment-providers', [PaymentProviderController::class, 'index']);

Route::get('/campaigns', [CampaignController::class, 'index']);
Route::get('/campaigns/{campaign}', [CampaignController::class, 'show'])->whereNumber('campaign');

Route::get('/news', [NewsController::class, 'index']);
Route::get('/news/{news}', [NewsController::class, 'show'])->whereNumber('news');

Route::get('/reports', [ReportController::class, 'index']);
Route::get('/reports/{report}', [ReportController::class, 'show'])->whereNumber('report');

// ===== semua peran / Harus login (Bearer token) =====
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/me', [AuthController::class, 'updateProfile']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/donations', [DonationController::class, 'index']);
    Route::post('/donations', [DonationController::class, 'store']);

    Route::get('/assets', [AssetController::class, 'index']);
    Route::get('/assets/{asset}', [AssetController::class, 'show'])->whereNumber('asset');

    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications', [NotificationController::class, 'store'])->middleware('throttle:30,1');
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllRead']);

    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites/{campaign}', [FavoriteController::class, 'toggle'])->whereNumber('campaign');

    Route::get('/community/overview', [CommunityController::class, 'overview']);
    Route::post('/community/join', [CommunityController::class, 'join']);
    Route::delete('/community/join', [CommunityController::class, 'leave']);
    Route::get('/community/members', [CommunityController::class, 'members']);

    Route::get('/community/posts', [CommunityPostController::class, 'index']);
    Route::post('/community/posts', [CommunityPostController::class, 'store'])->middleware('throttle:20,1');
    Route::get('/community/posts/{post}', [CommunityPostController::class, 'show'])->whereNumber('post');
    Route::delete('/community/posts/{post}', [CommunityPostController::class, 'destroy'])->whereNumber('post');
    Route::post('/community/posts/{post}/like', [CommunityPostController::class, 'like'])->whereNumber('post');
    Route::post('/community/posts/{post}/report', [CommunityPostController::class, 'report'])->whereNumber('post');
    Route::post('/community/polls/{poll}/vote', [CommunityPostController::class, 'vote'])->whereNumber('poll');

    Route::get('/community/posts/{post}/comments', [CommunityCommentController::class, 'index'])->whereNumber('post');
    Route::post('/community/posts/{post}/comments', [CommunityCommentController::class, 'store'])->whereNumber('post')->middleware('throttle:30,1');
    Route::delete('/community/comments/{comment}', [CommunityCommentController::class, 'destroy'])->whereNumber('comment');
    Route::post('/community/comments/{comment}/report', [CommunityCommentController::class, 'report'])->whereNumber('comment');

    Route::get('/community/events', [CommunityEventController::class, 'index']);
    Route::post('/community/events', [CommunityEventController::class, 'store']);
    Route::put('/community/events/{event}', [CommunityEventController::class, 'update'])->whereNumber('event');
    Route::delete('/community/events/{event}', [CommunityEventController::class, 'destroy'])->whereNumber('event');
    Route::post('/community/events/{event}/interest', [CommunityEventController::class, 'interest'])->whereNumber('event');

    Route::post('/uploads', [AssetController::class, 'storeMine'])->middleware('throttle:20,1');
    
    // ----- Admin & Pengelola -----
    Route::middleware(RoleMiddleware::class . ':admin,pengelola')->group(function () {
        Route::post('/assets', [AssetController::class, 'store']);

        Route::get('/campaigns/mine', [CampaignController::class, 'mine']);
        Route::post('/campaigns', [CampaignController::class, 'store']);
        Route::put('/campaigns/{campaign}', [CampaignController::class, 'update'])->whereNumber('campaign');
        
        Route::get('/reports/mine', [ReportController::class, 'mine']);
        Route::post('/reports', [ReportController::class, 'store']);
        Route::put('/reports/{report}', [ReportController::class, 'update'])->whereNumber('report');
    });

    // ----- Admin saja -----
    Route::middleware(RoleMiddleware::class . ':admin')->group(function () {
        Route::get('/admin/campaigns', [CampaignController::class, 'adminIndex']);
        Route::get('/admin/donations', [DonationController::class, 'adminIndex']);
        Route::get('/admin/transactions', [DonationController::class, 'adminTransactions']);

        Route::patch('/campaigns/{campaign}/review', [CampaignController::class, 'review'])->whereNumber('campaign');
        Route::delete('/campaigns/{campaign}', [CampaignController::class, 'destroy'])->whereNumber('campaign');

        Route::post('/news', [NewsController::class, 'store']);
        Route::put('/news/{news}', [NewsController::class, 'update'])->whereNumber('news');
        Route::delete('/news/{news}', [NewsController::class, 'destroy'])->whereNumber('news');

        Route::delete('/assets/{asset}', [AssetController::class, 'destroy'])->whereNumber('asset');
        Route::put('/categories/{category}', [CategoryController::class, 'update'])->whereNumber('category');

        Route::get('/admin/reports', [ReportController::class, 'adminIndex']);
        Route::patch('/reports/{report}/review', [ReportController::class, 'review'])->whereNumber('report');

        Route::get('/admin/users', [AdminUserController::class, 'index']);
        Route::post('/admin/users', [AdminUserController::class, 'store']);
        Route::put('/admin/users/{user}', [AdminUserController::class, 'update'])->whereNumber('user');
        Route::delete('/admin/users/{user}', [AdminUserController::class, 'destroy'])->whereNumber('user');
        Route::post('/admin/users/{user}/warn', [AdminUserController::class, 'warn'])->whereNumber('user');
        Route::post('/admin/users/{user}/ban', [AdminUserController::class, 'ban'])->whereNumber('user');
        Route::post('/admin/users/{user}/lift', [AdminUserController::class, 'lift'])->whereNumber('user');

                Route::post('/community/posts/{post}/pin', [CommunityPostController::class, 'pin'])->whereNumber('post');
        Route::get('/admin/community/reports', [CommunityModerationController::class, 'index']);
        Route::patch('/admin/community/reports/{id}', [CommunityModerationController::class, 'review'])->whereNumber('id');
    });
});
