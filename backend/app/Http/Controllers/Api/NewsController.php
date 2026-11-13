<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\NewsResource;
use App\Models\ActivityLog;
use App\Models\Category;
use App\Models\News;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class NewsController extends Controller
{
    private const WITH = ['category', 'imageAsset'];

    public function index(): AnonymousResourceCollection
    {
        return NewsResource::collection(
            News::with(self::WITH)
                ->where('published_at', '<=', now())
                ->orderByDesc('published_at')
                ->get()
        );
    }

    public function show(News $news): NewsResource
    {
        return new NewsResource($news->load(self::WITH));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate($this->rules(false));

        $news = News::create([
            'category_id' => Category::where('slug', $data['category'])->value('id'),
            'campaign_id' => $data['campaign_id'] ?? null,
            'author_id' => $request->user()->id,
            'author' => $data['author'] ?? 'Redaksi SADAQO',
            'title' => trim($data['title']),
            'summary' => trim($data['summary']),
            'content' => trim($data['content']),
            'image_asset_id' => $data['image_asset_id'] ?? null,
            'published_at' => $data['published_at'] ?? now(),
        ]);

        ActivityLog::record('content', "Admin menerbitkan berita: {$news->title}", $request->user());

        return (new NewsResource($news->load(self::WITH)))->response()->setStatusCode(201);
    }

    public function update(Request $request, News $news): NewsResource
    {
        $data = $request->validate($this->rules(true));

        if (isset($data['category'])) {
            $data['category_id'] = Category::where('slug', $data['category'])->value('id');
            unset($data['category']);
        }

        // Kolom ini tidak boleh kosong di database; abaikan jika dikirim null.
        foreach (['published_at', 'author'] as $notNull) {
            if (array_key_exists($notNull, $data) && $data[$notNull] === null) {
                unset($data[$notNull]);
            }
        }

        $news->update($data);
        ActivityLog::record('content', "Admin mengubah berita: {$news->title}", $request->user());

        return new NewsResource($news->load(self::WITH));
    }

    public function destroy(Request $request, News $news): JsonResponse
    {
        $title = $news->title;
        $news->delete();
        ActivityLog::record('content', "Admin menghapus berita: {$title}", $request->user());

        return response()->json(['message' => 'Berita dihapus']);
    }

    private function rules(bool $partial): array
    {
        $req = $partial ? ['sometimes', 'required'] : ['required'];

        return [
            'title' => [...$req, 'string', 'min:5', 'max:255'],
            'summary' => [...$req, 'string', 'max:500'],
            'content' => [
                ...$req,
                'string',
                function (string $attribute, mixed $value, \Closure $fail) {
                    $words = preg_split('/\s+/u', trim((string) $value), -1, PREG_SPLIT_NO_EMPTY);
                    if (count($words) > News::MAX_WORDS) {
                        $fail('Isi berita maksimal ' . News::MAX_WORDS . ' kata.');
                    }
                },
            ],
            'category' => [...$req, 'string', 'exists:categories,slug'],
            'campaign_id' => ['sometimes', 'nullable', 'integer', 'exists:campaigns,id'],
            'author' => ['sometimes', 'nullable', 'string', 'max:100'],
            'image_asset_id' => ['sometimes', 'nullable', 'integer', 'exists:assets,id'],
            'published_at' => ['sometimes', 'nullable', 'date'],
        ];
    }
}
