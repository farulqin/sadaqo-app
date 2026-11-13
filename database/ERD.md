# ERD Database SADAQO

Database: MySQL (`sadaqo`). Dikelola lewat migration Laravel di `backend/database/migrations`.

Prinsip utama: **tabel `assets` adalah registri semua gambar**. Gambar bawaan aplikasi
(`source = bundled`) dan gambar yang diunggah admin/pengelola (`source = uploaded`) sama-sama
tercatat di sana. Tabel lain hanya boleh menunjuk gambar lewat foreign key ke `assets`.

```mermaid
erDiagram
    users ||--o{ assets : "uploaded_by"
    assets ||--o{ users : "avatar_asset_id"
    assets ||--o{ categories : "icon_asset_id"
    assets ||--o{ campaigns : "image_asset_id"
    assets ||--o{ news : "image_asset_id"
    assets ||--o{ report_photos : "asset_id"

    categories ||--o{ campaigns : "category_id"
    categories ||--o{ news : "category_id"
    users ||--o{ campaigns : "owner_id (pengelola)"
    campaigns ||--o{ donations : "campaign_id"
    users ||--o{ donations : "user_id"
    payment_providers ||--o{ donations : "payment_provider_id"
    campaigns ||--o{ news : "campaign_id"
    users ||--o{ news : "author_id"

    campaigns ||--o{ campaign_reports : "campaign_id"
    users ||--o{ campaign_reports : "manager_id"
    campaign_reports ||--o{ report_photos : "campaign_report_id"

    users ||--o{ favorites : "user_id"
    campaigns ||--o{ favorites : "campaign_id"
    users ||--o{ app_notifications : "user_id"

    users ||--o{ community_messages : "user_id"
    community_messages ||--o{ message_reactions : "community_message_id"
    community_messages ||--o{ community_reports : "community_message_id"
    users ||--o{ community_violations : "user_id"
    users ||--o{ activity_logs : "user_id"

    assets {
        bigint id PK
        string path UK
        string file_name
        string group
        enum source "bundled | uploaded"
        string mime_type
        bigint size_bytes
        int width
        int height
        string checksum
        bigint uploaded_by FK
    }
    users {
        bigint id PK
        string name
        string email UK
        string phone
        enum gender
        enum role "donatur | pengelola | admin"
        bigint avatar_asset_id FK
        tinyint strikes
        timestamp banned_until
    }
    categories {
        bigint id PK
        string slug UK
        string label
        bigint icon_asset_id FK
    }
    campaigns {
        bigint id PK
        bigint category_id FK
        bigint owner_id FK
        string title
        bigint target_amount
        bigint collected_amount
        datetime deadline
        bigint unit_price
        int slot_total
        int slot_filled
        bigint image_asset_id FK
        enum status "pending | active | rejected | closed"
    }
    donations {
        bigint id PK
        string reference UK
        bigint user_id FK
        bigint campaign_id FK
        bigint amount
        enum payment_method
        bigint payment_provider_id FK
        enum status
    }
    news {
        bigint id PK
        bigint category_id FK
        bigint campaign_id FK
        string title
        longtext content
        bigint image_asset_id FK
        datetime published_at
    }
    campaign_reports {
        bigint id PK
        bigint campaign_id FK
        bigint manager_id FK
        enum status "pending | approved | revision"
    }
    report_photos {
        bigint id PK
        bigint campaign_report_id FK
        bigint asset_id FK
        enum type "activity | proof"
    }
```

## Query pembuktian (untuk presentasi)

```sql
-- 1) Semua gambar terdaftar, dikelompokkan
SELECT `group`, source, COUNT(*) AS jumlah FROM assets GROUP BY `group`, source;

-- 2) Gambar tiap program lewat foreign key ke assets
SELECT c.title, a.path, a.source
FROM campaigns c JOIN assets a ON a.id = c.image_asset_id;

-- 3) Gambar hasil unggahan admin/pengelola beserta pengunggahnya
SELECT a.path, a.group, u.name AS pengunggah, u.role
FROM assets a JOIN users u ON u.id = a.uploaded_by
WHERE a.source = 'uploaded';

-- 4) Gambar yang belum dipakai tabel mana pun
SELECT a.* FROM assets a
LEFT JOIN campaigns c ON c.image_asset_id = a.id
LEFT JOIN news n ON n.image_asset_id = a.id
LEFT JOIN categories k ON k.icon_asset_id = a.id
LEFT JOIN users u ON u.avatar_asset_id = a.id
LEFT JOIN report_photos r ON r.asset_id = a.id
WHERE c.id IS NULL AND n.id IS NULL AND k.id IS NULL AND u.id IS NULL AND r.id IS NULL;
```
