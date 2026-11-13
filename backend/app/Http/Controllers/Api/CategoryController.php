<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Models\ActivityLog;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class CategoryController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return CategoryResource::collection(
            Category::with('iconAsset')->orderBy('sort_order')->get()
        );
    }

    /** Admin mengubah nama dan ikon kategori (menggantikan CategoryOverrides di Flutter). */
    public function update(Request $request, Category $category): CategoryResource
    {
        $data = $request->validate([
            'label' => ['sometimes', 'required', 'string', 'max:60'],
            'short_label' => ['sometimes', 'required', 'string', 'max:30'],
            'icon_asset_id' => ['sometimes', 'nullable', Rule::exists('assets', 'id')->where('group', 'icons')],
        ]);

        $category->update($data);
        ActivityLog::record('content', "Admin mengubah tampilan kategori: {$category->label}", $request->user());

        return new CategoryResource($category->load('iconAsset'));
    }
}
