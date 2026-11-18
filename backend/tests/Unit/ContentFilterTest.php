<?php

namespace Tests\Unit;

use App\Support\CommunityGuard;
use App\Support\ContentFilter;
use PHPUnit\Framework\TestCase;

class ContentFilterTest extends TestCase
{
    public function test_clean_text_passes(): void
    {
        $this->assertNull(ContentFilter::check('Semoga donasi kita berkah untuk semua'));
    }

    public function test_scam_phrase_is_detected(): void
    {
        $this->assertSame('scam', ContentFilter::check('tolong kirim otp ke saya'));
    }

    public function test_porn_keyword_is_detected(): void
    {
        $this->assertSame('porn', ContentFilter::check('ini video bokep'));
    }

    public function test_sanction_policy_matches_flutter_app(): void
    {
        // Harus sama dengan CommunityPolicy di lib/features/community_feed/domain/moderation.dart
        $this->assertSame(2, CommunityGuard::STRIKES_BEFORE_BAN);
        $this->assertSame(30, CommunityGuard::BAN_DAYS);
    }
}