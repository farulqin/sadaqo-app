<?php

namespace App\Support;

/**
 * Penyaring konten berbasis kata kunci. Tidak memahami konteks dan tidak bisa
 * memastikan sebuah kabar itu hoaks; hoaks ditangani lewat tombol Laporkan.
 */
class ContentFilter
{
    public const LABELS = [
        'hoax' => 'berita bohong (hoaks)',
        'hate' => 'ujaran kebencian',
        'scam' => 'penipuan / scam',
        'porn' => 'pornografi',
        'blasphemy' => 'penistaan agama',
        'profanity' => 'kata-kata kotor',
    ];

    private const RELIGION = [
        'islam', 'allah', 'nabi', 'rasul', 'quran', 'alquran', 'muhammad',
        'kristen', 'yesus', 'tuhan', 'hindu', 'buddha', 'budha', 'agama',
        'masjid', 'gereja', 'pura', 'vihara',
    ];

    private const INSULT = [
        'sampah', 'bodoh', 'goblok', 'tolol', 'anjing', 'babi', 'bangsat',
        'laknat', 'sesat', 'teroris', 'dongeng', 'khayalan', 'jelek', 'hina',
    ];

    private const PHRASES = [
        'blasphemy' => [
            'allah bodoh', 'nabi palsu', 'quran palsu', 'alquran palsu', 'hina agama',
            'agama sampah', 'tuhan bodoh', 'rasul palsu',
        ],
        'hate' => [
            'bunuh dia', 'bunuh mereka', 'bunuh semua', 'mati kau', 'mati saja kau',
            'musnahkan', 'bantai', 'dasar cina', 'dasar kafir', 'kafir laknat',
            'cina kafir', 'binatang kau', 'babi kau', 'usir semua',
        ],
        'porn' => [
            'bokep', 'porno', 'pornografi', 'seks', 'sex', 'telanjang', 'bugil',
            'ngentot', 'vcs', 'open bo', 'video dewasa', 'konten dewasa', 'nude',
            'nsfw', 'xxx', 'colmek', 'masturbasi',
        ],
        'scam' => [
            'transfer dulu', 'kirim pulsa', 'kirim otp', 'minta otp', 'kode otp',
            'klik link', 'link hadiah', 'hadiah gratis', 'menang undian',
            'judi online', 'slot gacor', 'togel', 'jackpot', 'uang cepat',
            'kirim uang dulu', 'donasi ke rekening', 'rekening pribadi',
            'investasi cepat kaya',
        ],
        'hoax' => [
            'sebarkan sebelum dihapus', 'viral wajib sebar', 'share ke semua grup',
            'sebarkan ke semua kontak', 'berita ini dirahasiakan',
            'media tidak berani', 'forward ke 10',
        ],
        'profanity' => [
            'anjing', 'bangsat', 'bajingan', 'brengsek', 'keparat', 'bangke',
            'sialan', 'goblok', 'tolol', 'kontol', 'memek', 'jancok', 'jancuk',
            'asu', 'tai', 'kampret', 'fuck', 'shit', 'bitch', 'asshole',
        ],
    ];

    private const ORDER = ['hate', 'porn', 'scam', 'hoax', 'profanity'];

    /** Jenis pelanggaran pertama yang ditemukan, atau null bila aman. */
    public static function check(string $raw): ?string
    {
        $text = self::normalize($raw);
        if ($text === '') {
            return null;
        }
        $words = explode(' ', $text);

        $has = function (string $keyword) use ($text, $words): bool {
            if (str_contains($keyword, ' ')) {
                return str_contains(" {$text} ", " {$keyword} ");
            }
            if (in_array($keyword, $words, true)) {
                return true;
            }
            // Kata panjang juga dicocokkan di dalam kata (mis. "bangsatnya").
            return strlen($keyword) >= 6 && str_contains($text, $keyword);
        };

        $religious = count(array_intersect(self::RELIGION, $words)) > 0;
        $insulting = count(array_intersect(self::INSULT, $words)) > 0;
        if (($religious && $insulting) || self::any(self::PHRASES['blasphemy'], $has)) {
            return 'blasphemy';
        }

        foreach (self::ORDER as $type) {
            if (self::any(self::PHRASES[$type], $has)) {
                return $type;
            }
        }

        return null;
    }

    private static function any(array $keywords, callable $has): bool
    {
        foreach ($keywords as $k) {
            if ($has($k)) {
                return true;
            }
        }

        return false;
    }

    /** Huruf kecil, angka "gaul" jadi huruf, simbol dibuang, huruf berulang dipadatkan. */
    private static function normalize(string $input): string
    {
        $s = strtr(mb_strtolower($input), [
            '0' => 'o', '1' => 'i', '3' => 'e', '4' => 'a', '5' => 's', '7' => 't', '@' => 'a', '$' => 's',
        ]);
        $s = preg_replace('/[^a-z ]/', ' ', $s) ?? '';
        $s = preg_replace('/(.)\1{2,}/', '$1', $s) ?? '';

        return trim(preg_replace('/\s+/', ' ', $s) ?? '');
    }
}