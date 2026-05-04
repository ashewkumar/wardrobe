# Laravel Backend Structure For Outfit Builder

This matches the Flutter calls already wired in the app:

- `GET /api/outfits?user_id={id}`
- `POST /api/outfits`
- `POST /api/outfits/{id}` with `_method=PUT`

## 1. Routes

Add this to `routes/api.php`:

```php
use App\Http\Controllers\Api\OutfitController;

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/outfits', [OutfitController::class, 'index']);
    Route::post('/outfits', [OutfitController::class, 'store']);
    Route::put('/outfits/{outfit}', [OutfitController::class, 'update']);
    Route::post('/outfits/{outfit}', [OutfitController::class, 'update']);
});
```

## 2. Models

### `app/Models/Outfit.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Outfit extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'occasion',
        'notes',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function outfitItems()
    {
        return $this->hasMany(OutfitItem::class)->orderBy('sort_order');
    }

    public function images()
    {
        return $this->belongsToMany(UserImage::class, 'outfit_items', 'outfit_id', 'user_image_id')
            ->withPivot(['slot', 'sort_order'])
            ->withTimestamps();
    }
}
```

### `app/Models/OutfitItem.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OutfitItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'outfit_id',
        'user_image_id',
        'slot',
        'sort_order',
    ];

    public function outfit()
    {
        return $this->belongsTo(Outfit::class);
    }

    public function image()
    {
        return $this->belongsTo(UserImage::class, 'user_image_id');
    }
}
```

## 3. Controller

### `app/Http/Controllers/Api/OutfitController.php`

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Outfit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OutfitController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->query('user_id');

        $outfits = Outfit::with([
            'outfitItems.image.category',
            'images.category',
        ])
            ->when($userId, fn ($query) => $query->where('user_id', $userId))
            ->latest()
            ->get();

        return response()->json([
            'status' => true,
            'data' => $outfits->map(fn ($outfit) => $this->transformOutfit($outfit)),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'name' => ['required', 'string', 'max:180'],
            'occasion' => ['nullable', 'string', 'max:120'],
            'notes' => ['nullable', 'string'],
            'image_ids' => ['required', 'array', 'min:1'],
            'image_ids.*' => ['integer', 'exists:user_images,id'],
        ]);

        $outfit = DB::transaction(function () use ($validated) {
            $outfit = Outfit::create([
                'user_id' => $validated['user_id'],
                'name' => $validated['name'],
                'occasion' => $validated['occasion'] ?? null,
                'notes' => $validated['notes'] ?? null,
            ]);

            foreach ($validated['image_ids'] as $index => $imageId) {
                $outfit->outfitItems()->create([
                    'user_image_id' => $imageId,
                    'sort_order' => $index,
                ]);
            }

            return $outfit->load(['outfitItems.image.category', 'images.category']);
        });

        return response()->json([
            'status' => true,
            'message' => 'Outfit created successfully',
            'data' => $this->transformOutfit($outfit),
        ], 201);
    }

    public function update(Request $request, Outfit $outfit)
    {
        $validated = $request->validate([
            'user_id' => ['nullable', 'integer', 'exists:users,id'],
            'name' => ['required', 'string', 'max:180'],
            'occasion' => ['nullable', 'string', 'max:120'],
            'notes' => ['nullable', 'string'],
            'image_ids' => ['required', 'array', 'min:1'],
            'image_ids.*' => ['integer', 'exists:user_images,id'],
        ]);

        DB::transaction(function () use ($validated, $outfit) {
            $outfit->update([
                'user_id' => $validated['user_id'] ?? $outfit->user_id,
                'name' => $validated['name'],
                'occasion' => $validated['occasion'] ?? null,
                'notes' => $validated['notes'] ?? null,
            ]);

            $outfit->outfitItems()->delete();

            foreach ($validated['image_ids'] as $index => $imageId) {
                $outfit->outfitItems()->create([
                    'user_image_id' => $imageId,
                    'sort_order' => $index,
                ]);
            }
        });

        $outfit->load(['outfitItems.image.category', 'images.category']);

        return response()->json([
            'status' => true,
            'message' => 'Outfit updated successfully',
            'data' => $this->transformOutfit($outfit),
        ]);
    }

    private function transformOutfit(Outfit $outfit): array
    {
        return [
            'id' => $outfit->id,
            'user_id' => $outfit->user_id,
            'name' => $outfit->name,
            'occasion' => $outfit->occasion,
            'notes' => $outfit->notes,
            'image_ids' => $outfit->outfitItems
                ->pluck('user_image_id')
                ->map(fn ($id) => (string) $id)
                ->values(),
            'items' => $outfit->outfitItems->map(function ($item) {
                return [
                    'id' => $item->id,
                    'image_id' => $item->user_image_id,
                    'slot' => $item->slot,
                    'sort_order' => $item->sort_order,
                    'image' => $item->image,
                ];
            })->values(),
            'created_at' => $outfit->created_at,
            'updated_at' => $outfit->updated_at,
        ];
    }
}
```

## 4. Optional migration names

If you prefer Laravel migrations instead of raw SQL:

- `create_outfits_table`
- `create_outfit_items_table`

## 5. Response shape expected by Flutter

The Flutter page is happiest if each saved outfit returns:

```json
{
  "id": 1,
  "name": "Office Monday",
  "occasion": "Work",
  "notes": "Neutral layers",
  "image_ids": ["12", "18", "22"],
  "items": [
    {
      "id": 5,
      "image_id": 12,
      "slot": "Top",
      "sort_order": 0,
      "image": {
        "id": 12,
        "image_name": "White Shirt",
        "image_url": "/storage/uploads/shirt.png",
        "category": {
          "name": "Tops",
          "type": "Shirt",
          "colour": "White"
        }
      }
    }
  ]
}
```

## 6. Small recommendation

If you already use Laravel Sanctum for the other endpoints, keep these outfit routes inside the same authenticated API group so they behave consistently with `images`, `important-dates`, and `inner-circle`.
