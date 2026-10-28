# Jesi Laundry App — Spesifikasi Backend

> Lokasi file: `jesi-laundry-app/server/BACKEND.md`. Baca `../ARCHITECTURE.md` terlebih dahulu.
> Go module: `jesi-laundry-app-server`. Framework: Fiber v3. ORM: GORM. Database: PostgreSQL 17.

---

## 1. Tujuan & Batasan

- REST API JSON untuk aplikasi mobile Jesi Laundry (Android & iOS). Tidak ada client web, jadi **tidak perlu CORS**.
- Modular monolith: satu binary `api`, satu binary `migrate`, satu database.
- Pola per modul: `handler → service → repository`. Tanpa usecase layer, tanpa DI container, tanpa generic repository.
- **Tidak ada file test.**
- Satu entitas GORM per file di `internal/model/`. Satu file migrasi di `internal/platform/database/migrate.go`.
- Raw SQL hanya diizinkan untuk ekspresi agregasi waktu di modul dashboard (§11). Semua query lain memakai GORM query builder.

---

## 2. Dependency

Gunakan versi stabil terbaru saat `go get`. Jangan menambah dependency lain tanpa alasan tertulis.

| Package | Kegunaan |
|---|---|
| `github.com/gofiber/fiber/v3` | HTTP framework + middleware bawaan (`recover`, `requestid`, `logger`, `limiter`) |
| `gorm.io/gorm`, `gorm.io/driver/postgres` | ORM, migrasi |
| `github.com/golang-jwt/jwt/v5` | Access token |
| `golang.org/x/crypto/bcrypt` | Hash password |
| `github.com/go-playground/validator/v10` | Validasi DTO |
| `github.com/google/uuid` | UUID v7 (`uuid.NewV7()`) |
| `github.com/shopspring/decimal` | Kuantitas desimal & perhitungan harga |
| SDK Go resmi Resend (`github.com/resend/resend-go/...`, major terbaru) | Kirim email OTP |
| `github.com/joho/godotenv` | Memuat `.env` saat development saja |

Gunakan `log/slog` (stdlib) untuk logging. Konfigurasi dibaca dengan `os.Getenv` biasa (tanpa library config).

`go.mod` memakai directive `go 1.27`.

---

## 3. Struktur Folder

```
server/
├── BACKEND.md
├── cmd/
│   ├── api/
│   │   └── main.go                  # load config → open DB → build app → listen PORT → graceful shutdown
│   └── migrate/
│       └── main.go                  # load config → open DB (unpooled) → database.Migrate → exit
├── internal/
│   ├── app/
│   │   ├── app.go                   # New(deps) *fiber.App: config Fiber, middleware global, error handler
│   │   └── routes.go                # wiring repo/service/handler tiap modul + registrasi route /api/v1
│   ├── model/
│   │   ├── base.go                  # struct Base (ID, CreatedAt, UpdatedAt) + hook BeforeCreate UUID v7
│   │   ├── enum_role.go
│   │   ├── enum_service_category.go
│   │   ├── enum_pricing_unit.go
│   │   ├── enum_service_speed.go
│   │   ├── enum_order_status.go
│   │   ├── enum_payment_status.go
│   │   ├── outlet.go
│   │   ├── user.go
│   │   ├── refresh_token.go
│   │   ├── password_reset_otp.go
│   │   ├── laundry_service.go
│   │   ├── customer.go
│   │   ├── order.go
│   │   ├── order_item.go
│   │   └── order_counter.go
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── handler.go
│   │   │   ├── service.go
│   │   │   ├── repository.go
│   │   │   ├── dto.go
│   │   │   └── routes.go
│   │   ├── user/                    # manajemen staff + endpoint /me
│   │   │   ├── handler.go
│   │   │   ├── service.go
│   │   │   ├── repository.go
│   │   │   ├── dto.go
│   │   │   └── routes.go
│   │   ├── outlet/
│   │   │   ├── handler.go
│   │   │   ├── service.go
│   │   │   ├── repository.go
│   │   │   ├── dto.go
│   │   │   └── routes.go
│   │   ├── catalog/                 # laundry_services
│   │   │   ├── handler.go
│   │   │   ├── service.go
│   │   │   ├── repository.go
│   │   │   ├── dto.go
│   │   │   ├── defaults.go          # daftar layanan default per outlet baru
│   │   │   └── routes.go
│   │   ├── customer/
│   │   │   ├── handler.go
│   │   │   ├── service.go
│   │   │   ├── repository.go
│   │   │   ├── dto.go
│   │   │   ├── phone.go             # normalisasi nomor HP
│   │   │   └── routes.go
│   │   ├── order/
│   │   │   ├── handler.go
│   │   │   ├── service.go
│   │   │   ├── repository.go
│   │   │   ├── dto.go
│   │   │   ├── pricing.go           # perhitungan billed_quantity, subtotal, total, estimasi
│   │   │   ├── status.go            # aturan transisi status & pembayaran
│   │   │   ├── number.go            # pembuatan nomor order
│   │   │   └── routes.go
│   │   └── dashboard/
│   │       ├── handler.go
│   │       ├── service.go
│   │       ├── repository.go
│   │       ├── dto.go
│   │       ├── range.go             # definisi range & bucket + gap-filling
│   │       └── routes.go
│   └── platform/
│       ├── config/
│       │   └── config.go            # struct Config + Load() + validasi
│       ├── database/
│       │   ├── database.go          # Open(dsn, pool) *gorm.DB
│       │   ├── migrate.go           # SATU-SATUNYA file migrasi (AutoMigrate)
│       │   └── tx.go                # WithTx(ctx, db, fn)
│       ├── httpx/
│       │   ├── response.go          # OK, Created, Paginated, NoContent
│       │   ├── error.go             # type AppError + kode error + konstruktor
│       │   ├── error_handler.go     # Fiber ErrorHandler → envelope error
│       │   ├── bind.go              # BindBody / BindQuery + validasi → VALIDATION_ERROR
│       │   └── pagination.go        # Page params (page, limit) + offset
│       ├── middleware/
│       │   ├── principal.go         # type Principal + PrincipalFrom(c) + ScopedOutletID
│       │   ├── auth.go              # RequireAuth: verifikasi JWT → simpan Principal
│       │   └── role.go              # RequireOwner
│       ├── security/
│       │   ├── password.go          # Hash, Compare, dummy compare (anti timing attack)
│       │   ├── jwt.go               # IssueAccessToken, ParseAccessToken
│       │   ├── token.go             # RandomToken(32 byte, base64url), SHA256Hex
│       │   └── otp.go               # GenerateOTP (crypto/rand), HashOTP (HMAC-SHA256)
│       ├── mailer/
│       │   ├── mailer.go            # interface Mailer { SendPasswordResetOTP(ctx, to, name, code, lang) error }
│       │   ├── resend.go            # implementasi Resend
│       │   ├── log.go               # implementasi dev: tulis OTP ke log
│       │   └── otp_template.go      # subject & HTML/text email id/en
│       ├── validation/
│       │   └── validator.go         # instance validator + tag name dari json tag
│       └── timeutil/
│           └── timeutil.go          # Location() Asia/Jakarta, LocalDate(t), StartOfDay, dll
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .env.example
├── .gitignore
├── go.mod
└── go.sum
```

Aturan dependency antar package:

- `internal/model` tidak mengimpor apa pun dari `internal/` selain dirinya sendiri.
- `platform/*` tidak mengimpor `modules/*`.
- Antar modul **tidak saling mengimpor handler**. Jika modul A butuh modul B (mis. `order` butuh `catalog` & `customer`, `auth` butuh `outlet` & `catalog`), modul A mendefinisikan **interface kecil** di sisi konsumen dan menerima implementasi B lewat konstruktor di `internal/app/routes.go`.
- Handler **tidak pernah** mengembalikan struct GORM langsung; selalu dipetakan ke DTO response di `dto.go`.

---

## 4. Konfigurasi

`.env.example`:

```dotenv
APP_ENV=development                # development | production
PORT=8080
APP_TIMEZONE=Asia/Jakarta

# Runtime (pooled di produksi)
DATABASE_URL=postgres://jesi:jesi@localhost:5432/jesi_laundry?sslmode=disable
# Migrasi (direct/unpooled di produksi). Kosong = pakai DATABASE_URL.
DATABASE_URL_UNPOOLED=
DB_MAX_OPEN_CONNS=10
DB_MAX_IDLE_CONNS=5

JWT_ACCESS_SECRET=change-me-to-a-random-string-at-least-32-chars
JWT_ACCESS_TTL=15m
REFRESH_TOKEN_TTL=720h
OTP_SECRET=change-me-to-another-random-string-32-chars
OTP_TTL=10m

# Header berisi IP klien di belakang proxy (produksi Vercel: X-Real-IP). Kosong = tidak mempercayai header apa pun.
CLIENT_IP_HEADER=

RESEND_API_KEY=
MAIL_FROM=Jesi Laundry <no-reply@example.com>

# Dipakai docker-compose untuk container Postgres
POSTGRES_USER=jesi
POSTGRES_PASSWORD=jesi
POSTGRES_DB=jesi_laundry
```

Aturan `config.Load()`:

- Muat `.env` dengan `godotenv` **hanya jika file ada** (abaikan error file tidak ditemukan).
- Parse durasi dengan `time.ParseDuration`.
- Validasi saat startup (gagal = exit dengan pesan jelas):
  - `DATABASE_URL` wajib.
  - `JWT_ACCESS_SECRET` dan `OTP_SECRET` minimal 32 karakter.
  - Jika `APP_ENV=production`: `RESEND_API_KEY` dan `MAIL_FROM` wajib.
  - Jika `APP_ENV=production`: `JWT_ACCESS_SECRET` dan `OTP_SECRET` yang masih berawalan `change-me` (nilai contoh `.env.example`) ditolak.
- Jika `APP_ENV=development` dan `RESEND_API_KEY` kosong → pakai `mailer.LogMailer` (OTP dicetak ke log). Di production, OTP **tidak pernah** dicetak ke log.
- `APP_TIMEZONE` dimuat dengan `time.LoadLocation`. Tambahkan `import _ "time/tzdata"` di `cmd/api/main.go` dan `cmd/migrate/main.go` agar data zona waktu ikut ter-embed di binary.

---

## 5. Konvensi Kode

### 5.1 Lapisan

| Lapisan | Tanggung jawab | Tidak boleh |
|---|---|---|
| `handler.go` | Parse & validasi request (via `httpx.Bind*`), ambil `Principal`, panggil service, map ke DTO, tulis response | Akses DB, logika bisnis |
| `service.go` | Aturan bisnis, otorisasi berbasis data (scope outlet, kepemilikan), transaksi | Mengakses `fiber.Ctx` |
| `repository.go` | Query GORM | Aturan bisnis |

- Semua method service & repository menerima `context.Context` sebagai argumen pertama; repository memakai `db.WithContext(ctx)`.
- Transaksi: `database.WithTx(ctx, db, func(tx *gorm.DB) error {...})`. Repository menyediakan `WithTx(tx *gorm.DB) *Repository` agar bisa dipakai di dalam transaksi lintas modul.
- Error bisnis dikembalikan sebagai `*httpx.AppError` (status HTTP + `code` + message). Error lain dibungkus `fmt.Errorf("...: %w", err)` dan berakhir sebagai `INTERNAL_ERROR` (detail hanya di log).
- `gorm.ErrRecordNotFound` diterjemahkan ke `NOT_FOUND` di service.
- Pelanggaran unique constraint diterjemahkan ke kode `*_TAKEN` yang sesuai (deteksi via `errors.As` ke `*pgconn.PgError` kode `23505` dan nama constraint).

### 5.1.1 Aturan GORM: zero-value & boolean (WAJIB)

- Kolom `is_active` **tidak punya default di database** (tag `default:true` membuat GORM menimpa `false` menjadi `true` saat insert). Karena itu **setiap `Create`** untuk `Outlet`, `User`, dan `LaundryService` wajib mengisi `IsActive: true` secara eksplisit.
- **Jangan** memakai `Updates(struct)` untuk mengubah boolean, angka `0`, atau string kosong: GORM mengabaikan zero-value pada struct. Gunakan `Updates(map[string]any{"is_active": false})` atau `Select("is_active").Updates(&model)`.
- Untuk PATCH, DTO request memakai field **pointer** (`*string`, `*bool`, `*int64`) agar bisa membedakan "tidak dikirim" dari "dikirim dengan nilai kosong/false". Service membangun `map[string]any` hanya dari field yang tidak nil.

### 5.2 Fiber v3

- Handler bertanda tangan `func(c fiber.Ctx) error` (Fiber v3: `fiber.Ctx` adalah interface).
- Binding: `c.Bind().Body(&req)` / `c.Bind().Query(&req)`, lalu validasi dengan validator. Bungkus di `httpx.BindBody` / `httpx.BindQuery`.
- Konfigurasi `fiber.Config`: `AppName`, `BodyLimit: 1 * 1024 * 1024`, `ErrorHandler: httpx.ErrorHandler`, `ReadTimeout`/`WriteTimeout` 15 detik.
- Middleware global (urutan): `recover` → `requestid` → `logger` (format JSON-ish berisi request id, method, path, status, latency).

### 5.3 Validasi

- Tag `validate` di DTO request; nama field di `details` memakai nama `json` (daftarkan `RegisterTagNameFunc`).
- Rule umum: `required`, `email`, `min`, `max`, `oneof`, `uuid`, `gt`, `gte`, `lte`, `dive`.
- Validasi yang bergantung data (mis. layanan milik outlet) dilakukan di service.
- Email selalu di-`strings.ToLower(strings.TrimSpace())` sebelum dipakai.
- String bebas di-`TrimSpace`.

### 5.4 Logging

- `slog` JSON handler di production, text handler di development.
- **Jangan pernah** me-log password, token, refresh token, OTP (kecuali `LogMailer` di development), atau `Authorization` header.

---

## 6. Data Model

Semua tabel memakai `id uuid` (UUID v7 di-generate di Go lewat hook `BeforeCreate` di `Base`), `created_at timestamptz`, `updated_at timestamptz`. Semua kolom waktu bertipe `timestamptz`. Uang `bigint`. Kuantitas `numeric(10,2)` (Go: `decimal.Decimal`).

Enum disimpan sebagai `varchar` + `CHECK` constraint (tag GORM `check:`), dan di Go sebagai typed string dengan konstanta. Set `decimal.MarshalJSONWithoutQuotes = true` saat startup agar desimal dikirim sebagai angka JSON.

### 6.1 Enum

| Type Go | Nilai |
|---|---|
| `Role` | `owner`, `staff` |
| `ServiceCategory` | `wash_iron`, `iron_only`, `wash_fold`, `unit` |
| `PricingUnit` | `kg`, `piece`, `sqm` |
| `ServiceSpeed` | `regular`, `express` |
| `OrderStatus` | `received`, `processing`, `done`, `picked_up` |
| `PaymentStatus` | `unpaid`, `paid` |

Helper di enum: `IsValid()`, dan untuk `ServiceCategory`: `IsKilo()` (true untuk 3 kategori kiloan).

### 6.2 `outlets`

| Kolom | Tipe | Aturan |
|---|---|---|
| `code` | varchar(5) | not null, unique, huruf kapital/angka, immutable |
| `name` | varchar(100) | not null |
| `address` | varchar(255) | null |
| `phone` | varchar(20) | null |
| `is_active` | boolean | not null, default true |

### 6.3 `users`

| Kolom | Tipe | Aturan |
|---|---|---|
| `name` | varchar(100) | not null |
| `email` | varchar(255) | not null, unique (selalu lowercase) |
| `password_hash` | varchar(255) | not null, bcrypt cost 12 |
| `role` | varchar(10) | not null, check `owner`/`staff` |
| `outlet_id` | uuid | null, FK → outlets (RESTRICT) |
| `is_active` | boolean | not null, default true |
| `last_login_at` | timestamptz | null |

Constraint tambahan:

- Unique partial index `uq_users_single_owner` pada `role` dengan `WHERE role = 'owner'` (tag GORM `uniqueIndex:uq_users_single_owner,where:role = 'owner'`) → menjamin hanya 1 owner, aman dari race condition.
- Check `chk_users_role_outlet`: `(role = 'owner' AND outlet_id IS NULL) OR (role = 'staff' AND outlet_id IS NOT NULL)`.

### 6.4 `refresh_tokens`

| Kolom | Tipe | Aturan |
|---|---|---|
| `user_id` | uuid | not null, FK → users (CASCADE), index |
| `token_hash` | char(64) | not null, unique (SHA-256 hex) |
| `expires_at` | timestamptz | not null |
| `revoked_at` | timestamptz | null |
| `replaced_by_id` | uuid | null (token pengganti saat rotasi) |

### 6.5 `password_reset_otps`

| Kolom | Tipe | Aturan |
|---|---|---|
| `user_id` | uuid | not null, FK → users (CASCADE) |
| `code_hash` | char(64) | not null (HMAC-SHA256 hex) |
| `expires_at` | timestamptz | not null |
| `attempts` | smallint | not null, default 0 |
| `used_at` | timestamptz | null |

Index komposit `(user_id, created_at)`.

### 6.6 `laundry_services`

| Kolom | Tipe | Aturan |
|---|---|---|
| `outlet_id` | uuid | not null, FK → outlets (RESTRICT) |
| `category` | varchar(20) | not null, check enum |
| `name` | varchar(100) | not null |
| `pricing_unit` | varchar(10) | not null, check enum, immutable setelah dibuat |
| `regular_price` | bigint | not null, check `>= 0` |
| `express_price` | bigint | not null, check `>= 0` |
| `regular_duration_days` | smallint | not null, check 1–30 |
| `express_duration_days` | smallint | not null, check 1–30 |
| `min_quantity` | numeric(10,2) | not null, default 0 (0 = tanpa minimum) |
| `is_system` | boolean | not null, default false (true untuk 3 layanan kiloan) |
| `is_active` | boolean | not null, default true |
| `sort_order` | int | not null, default 0 |
| `deleted_at` | timestamptz | null, index (`gorm.DeletedAt`, soft delete) |

Index `(outlet_id, category)`. Keunikan nama per outlet (case-insensitive, di antara baris yang belum dihapus) dicek di service → `SERVICE_NAME_TAKEN`.

Konsistensi kategori ↔ unit (divalidasi di service):

- Kategori kiloan → `pricing_unit = kg`, `is_system = true`, tepat 1 per kategori per outlet.
- Kategori `unit` → `pricing_unit` `piece` atau `sqm`, `is_system = false`.

### 6.7 `customers`

| Kolom | Tipe | Aturan |
|---|---|---|
| `name` | varchar(100) | not null |
| `phone` | varchar(20) | null, index, format ternormalisasi (§8.6) |
| `last_order_at` | timestamptz | null |

Index ekspresi `lower(name)` (tag GORM `index:idx_customers_name_lower,expression:lower(name)`). Pelanggan tidak dihapus.

### 6.8 `orders`

| Kolom | Tipe | Aturan |
|---|---|---|
| `outlet_id` | uuid | not null, FK → outlets (RESTRICT) |
| `order_number` | varchar(30) | not null, unique |
| `customer_id` | uuid | not null, FK → customers (RESTRICT), index |
| `customer_name` | varchar(100) | not null (snapshot) |
| `customer_phone` | varchar(20) | null (snapshot) |
| `speed` | varchar(10) | not null, check enum |
| `status` | varchar(15) | not null, check enum, default `received`, index |
| `payment_status` | varchar(10) | not null, check enum, default `unpaid`, index |
| `total_amount` | bigint | not null, check `>= 0` |
| `estimated_done_at` | timestamptz | not null |
| `processing_at` | timestamptz | null |
| `done_at` | timestamptz | null |
| `picked_up_at` | timestamptz | null |
| `paid_at` | timestamptz | null |
| `notes` | varchar(500) | null |
| `created_by_id` | uuid | not null, FK → users (RESTRICT) |
| `updated_by_id` | uuid | null, FK → users |
| `deleted_by_id` | uuid | null, FK → users |
| `deleted_at` | timestamptz | null, index (soft delete) |

Index komposit `(outlet_id, created_at)` untuk list & dashboard.

### 6.9 `order_items`

| Kolom | Tipe | Aturan |
|---|---|---|
| `order_id` | uuid | not null, FK → orders (CASCADE), index |
| `service_id` | uuid | not null, FK → laundry_services (RESTRICT), index |
| `service_name` | varchar(100) | not null (snapshot) |
| `category` | varchar(20) | not null (snapshot) |
| `pricing_unit` | varchar(10) | not null (snapshot) |
| `quantity` | numeric(10,2) | not null — kg aktual / jumlah pcs / luas m² |
| `length_m` | numeric(10,2) | null (hanya `sqm`) |
| `width_m` | numeric(10,2) | null (hanya `sqm`) |
| `billed_quantity` | numeric(10,2) | not null — kuantitas yang ditagih setelah minimum |
| `unit_price` | bigint | not null (snapshot harga sesuai `speed`) |
| `subtotal` | bigint | not null |
| `duration_days` | smallint | not null (snapshot durasi sesuai `speed`) |

### 6.10 `order_counters`

| Kolom | Tipe | Aturan |
|---|---|---|
| `outlet_id` | uuid | PK (komposit), FK → outlets |
| `local_date` | date | PK (komposit), tanggal di zona `APP_TIMEZONE` |
| `last_number` | int | not null |

Tabel ini tidak memakai `Base` (tidak punya `id`), cukup `updated_at`.

### 6.11 Relasi GORM

Definisikan field relasi (`Outlet *Outlet`, `Items []OrderItem`, dll) dengan tag `foreignKey` dan `constraint:OnUpdate:CASCADE,OnDelete:RESTRICT|CASCADE` agar AutoMigrate membuat FK constraint tanpa raw SQL. Field relasi diberi tag `json:"-"` dan **tidak pernah** diserialisasi langsung.

---

## 7. Migrasi & Seed

### 7.1 `internal/platform/database/migrate.go` (satu-satunya file migrasi)

```go
func Migrate(ctx context.Context, db *gorm.DB) error {
    return db.WithContext(ctx).AutoMigrate(
        &model.Outlet{},
        &model.User{},
        &model.RefreshToken{},
        &model.PasswordResetOTP{},
        &model.LaundryService{},
        &model.Customer{},
        &model.Order{},
        &model.OrderItem{},
        &model.OrderCounter{},
    )
}
```

- Dijalankan **hanya** oleh `cmd/migrate`, tidak otomatis saat `cmd/api` start (menghindari migrasi paralel dari banyak instance).
- `cmd/migrate` memakai `config.LoadDatabase()` (hanya `DATABASE_URL`, `DATABASE_URL_UNPOOLED`, `APP_TIMEZONE`, `APP_ENV`), **tanpa** mewajibkan secret JWT/OTP/Resend. `cmd/api` tetap memakai `config.Load()` penuh. Migrasi memakai `DATABASE_URL_UNPOOLED` jika diisi, selain itu `DATABASE_URL`.
- Catatan: AutoMigrate menambah tabel/kolom/index tetapi tidak menghapus kolom. Perubahan destruktif dilakukan manual dan didokumentasikan.

### 7.2 Katalog Default (`catalog/defaults.go`)

Dibuat untuk setiap outlet baru (saat register owner dan saat `POST /outlets`), di dalam transaksi yang sama.

| category | name | unit | reguler (Rp) | express (Rp) | hari reg / exp | min | system |
|---|---|---|---:|---:|---|---:|:-:|
| `wash_iron` | Cuci Setrika | kg | 7.000 | 12.000 | 3 / 1 | 3 | ✅ |
| `iron_only` | Setrika | kg | 5.000 | 8.000* | 3 / 1 | 3 | ✅ |
| `wash_fold` | Cuci Lipat | kg | 5.000 | 8.000* | 3 / 1 | 3 | ✅ |
| `unit` | Bed Cover | piece | 25.000* | 35.000* | 3 / 1 | 0 | — |
| `unit` | Boneka | piece | 15.000* | 25.000* | 3 / 1 | 0 | — |
| `unit` | Karpet | sqm | 15.000* | 25.000* | 3 / 1 | 0 | — |

\* Harga placeholder. Owner akan mengubahnya lewat aplikasi.

`sort_order` mengikuti urutan tabel di atas (10, 20, 30, ...).

---

## 8. Aturan Bisnis

### 8.1 Perhitungan Item Order (`order/pricing.go`)

Untuk setiap item, ambil layanan (harus aktif, belum dihapus, milik outlet order) dan harga/durasi sesuai `speed` order:

| `pricing_unit` | Input dari client | Validasi | `quantity` | `billed_quantity` |
|---|---|---|---|---|
| `kg` | `quantity` | `0 < q ≤ 999.99`, maks 2 desimal | `q` | `max(q, min_quantity)` |
| `piece` | `quantity` | bilangan bulat `1–999` | `q` | `max(q, min_quantity)` |
| `sqm` | `length_m`, `width_m` | masing-masing `0 < x ≤ 99.99`, maks 2 desimal | `round(length × width, 2)` | `max(quantity, min_quantity)` |

- `subtotal = round(billed_quantity × unit_price, 0)` dengan pembulatan half-up (`decimal.Round(0)`).
- `total_amount = Σ subtotal`.
- Contoh: Cuci Setrika reguler 2,5 kg → `billed_quantity = 3`, `subtotal = 21.000`.
- Satu order minimal 1 item, maksimal 50 item.
- Satu layanan kiloan hanya boleh muncul 1 kali per order (`DUPLICATE_KILO_SERVICE`). Layanan satuan boleh muncul berkali-kali (mis. 2 karpet beda ukuran).
- Untuk `kg`/`piece`, field `length_m`/`width_m` diabaikan; untuk `sqm`, field `quantity` diabaikan.

### 8.2 Estimasi Selesai

`estimated_done_at = created_at + max(duration_days semua item) × 24 jam`.
Saat order diedit, dihitung ulang dari `created_at` asli.

### 8.3 Nomor Order (`order/number.go`)

- Format: `{OUTLET_CODE}-{YYMMDD}-{NNNN}`, contoh `JL-261027-0001`. Tanggal = tanggal lokal `APP_TIMEZONE`.
- Urutan per outlet per hari lewat upsert atomik pada `order_counters` di dalam transaksi pembuatan order:
  - GORM `Clauses(clause.OnConflict{Columns: outlet_id, local_date; DoUpdates: last_number = order_counters.last_number + 1}, clause.Returning{})`.
  - Insert awal `last_number = 1`.
- Nomor order tidak pernah dipakai ulang (termasuk dari order yang dihapus).

### 8.4 Transisi Status (`order/status.go`)

Urutan: `received(0) → processing(1) → done(2) → picked_up(3)`.

| Kasus | Siapa | Aturan |
|---|---|---|
| Maju (rank tujuan > rank sekarang, boleh melompat) | owner & staff | Set timestamp tahap tujuan = now; timestamp tahap yang dilompati dan masih null juga diisi now |
| Ke `picked_up` | owner & staff | Wajib `payment_status = paid`, jika tidak → `PAYMENT_REQUIRED` |
| Mundur (rank tujuan < rank sekarang) | owner saja | Kosongkan timestamp tahap setelah tujuan. Staff → `FORBIDDEN` |
| Sama dengan sekarang | — | `INVALID_STATUS_TRANSITION` |

### 8.5 Pembayaran

| Perubahan | Siapa | Aturan |
|---|---|---|
| `unpaid → paid` | owner & staff | Set `paid_at = now` |
| `paid → unpaid` | owner saja | Ditolak jika status `picked_up` (`ORDER_NOT_EDITABLE`); kosongkan `paid_at` |
| Sama dengan sekarang | — | `INVALID_STATUS_TRANSITION` |

Order boleh langsung dibuat dengan `payment_status = paid` (bayar di depan).

### 8.6 Pelanggan

- Normalisasi nomor HP (`customer/phone.go`): buang semua karakter non-digit; awalan `0` → `62`; hasil harus 9–15 digit, jika tidak → `VALIDATION_ERROR` pada field `customer.phone`. String kosong → `null`.
- Saat membuat / mengedit order:
  - Jika `customer.id` dikirim → harus ada (`NOT_FOUND` jika tidak).
  - Jika tidak, cari pelanggan dengan `lower(name) = lower(input)` **dan** nomor HP sama (keduanya null dianggap sama). Jika ketemu → pakai; jika tidak → buat baru.
- `last_order_at` diperbarui setiap order dibuat.
- Snapshot `customer_name` / `customer_phone` disalin ke order.

### 8.7 Edit & Hapus Order (owner saja)

- Edit (`PUT`) hanya jika `status != picked_up` **dan** `payment_status = unpaid`; selain itu `ORDER_NOT_EDITABLE`.
- Edit mengganti seluruh item dan menghitung ulang memakai **harga & durasi katalog saat ini**. Outlet order tidak bisa diubah.
- Hapus = soft delete (`deleted_at`, `deleted_by_id`). Order terhapus tidak muncul di list, detail (`NOT_FOUND`), maupun dashboard.

### 8.8 Katalog Layanan (owner)

- Layanan kiloan (`is_system = true`): boleh ubah `name`, harga, durasi, `min_quantity`, `is_active`, `sort_order`. Tidak boleh dihapus (`SYSTEM_SERVICE_NOT_DELETABLE`), tidak boleh ubah `category`/`pricing_unit`.
- Layanan satuan: create, update, aktif/nonaktif, soft delete. `pricing_unit` tidak bisa diubah setelah dibuat.
- Menonaktifkan atau menghapus layanan tidak mempengaruhi order lama (data order memakai snapshot).
- Perubahan harga tidak mempengaruhi order lama.

### 8.9 Outlet & Staff (owner)

- Outlet: create (kode unik, kapital), update `name`/`address`/`phone`/`is_active`. Tidak ada delete.
- Staff: create (`name`, `email`, `password`, `outlet_id` outlet aktif), update `name`/`outlet_id`/`is_active`, reset password oleh owner.
- Saat staff dinonaktifkan, dipindah outlet, atau di-reset password → cabut semua refresh token staff tersebut.
- Owner tidak bisa menonaktifkan dirinya sendiri; endpoint `/users` hanya mengelola staff.

---

## 9. Autentikasi & Keamanan

### 9.1 Password

- Minimal 8 karakter, maksimal 72 byte (batas bcrypt), mengandung huruf dan angka.
- bcrypt cost 12.
- Login dengan email tidak terdaftar tetap menjalankan `bcrypt.CompareHashAndPassword` terhadap hash dummy agar waktu respons setara.
- Login user nonaktif → `ACCOUNT_INACTIVE` (dicek setelah password benar).

### 9.2 Access Token (JWT HS256)

Claims: `sub` (user id), `role`, `oid` (outlet id, kosong untuk owner), `iss = "jesi-laundry"`, `iat`, `exp`. TTL `JWT_ACCESS_TTL` (15 menit).

`middleware.RequireAuth`:

- Header tidak ada / format salah / signature salah → `UNAUTHORIZED`.
- Kedaluwarsa → `TOKEN_EXPIRED` (bedakan via `errors.Is(err, jwt.ErrTokenExpired)`).
- Simpan `Principal{UserID, Role, OutletID *uuid.UUID}` di `c.Locals`.

`middleware.ScopedOutletID(principal, requested *uuid.UUID) *uuid.UUID`:

- Staff → selalu outlet staff.
- Owner → `requested` (nil = semua outlet).

Trade-off yang diterima: perubahan status aktif / outlet staff berlaku penuh paling lambat saat access token kedaluwarsa (≤ 15 menit), karena refresh token sudah dicabut.

### 9.3 Refresh Token

- 32 byte acak (`crypto/rand`) → base64url. Simpan `SHA-256 hex` di DB.
- `POST /auth/refresh`:
  1. Cari hash. Tidak ada / kedaluwarsa → `INVALID_REFRESH_TOKEN`.
  2. Jika sudah `revoked_at` (reuse terdeteksi) → cabut **semua** refresh token user tersebut → `INVALID_REFRESH_TOKEN`.
  3. Cek user masih aktif (jika tidak → cabut semua, `ACCOUNT_INACTIVE`).
  4. Dalam transaksi: cabut token lama, buat token baru, isi `replaced_by_id`.
  5. Kembalikan access token + refresh token baru.
- `POST /auth/logout`: cabut refresh token yang dikirim (idempoten, selalu `204`).
- `POST /me/change-password`: verifikasi `current_password`, update password, cabut **semua** refresh token user, lalu kembalikan sesi baru (access + refresh token) agar perangkat yang sedang dipakai tetap login.

### 9.4 OTP Reset Password

- `POST /auth/forgot-password {email}` selalu `200 {"data": {"retry_after_seconds": 60}}`.
- Jika user ada & aktif:
  - Cooldown: jika ada OTP user yang dibuat < 60 detik lalu → tidak kirim lagi (diam-diam).
  - Batas: maksimal 5 OTP per user per jam → tidak kirim lagi (diam-diam).
  - Tandai semua OTP aktif sebelumnya sebagai terpakai (`used_at = now`).
  - Buat OTP 6 digit (`crypto/rand`, angka 000000–999999 dengan leading zero), simpan `HMAC-SHA256(OTP_SECRET, user_id + ":" + code)`, `expires_at = now + OTP_TTL`.
  - Kirim email via `Mailer` dengan bahasa dari `Accept-Language` (`en` jika diawali `en`, selain itu `id`). Kegagalan kirim email di-log, respons tetap `200`.
- `POST /auth/reset-password {email, otp, new_password}`:
  1. Ambil OTP terbaru user yang `used_at IS NULL`. Tidak ada / user tidak ada / kedaluwarsa → `OTP_EXPIRED`.
  2. `attempts >= 5` → `OTP_TOO_MANY_ATTEMPTS`.
  3. Bandingkan hash dengan `hmac.Equal`. Salah → `attempts++` → `OTP_INVALID`.
  4. Benar → dalam transaksi: update password, `used_at = now`, cabut semua refresh token user → `204`.

### 9.5 Rate Limit

Gunakan middleware `limiter` Fiber (penyimpanan memory) pada:

| Endpoint | Batas | Key |
|---|---|---|
| `POST /auth/login` | 10 / menit | IP |
| `POST /auth/register-owner` | 5 / menit | IP |
| `POST /auth/forgot-password` | 5 / menit | IP |
| `POST /auth/reset-password` | 10 / menit | IP |

Respons limit → `RATE_LIMITED`. Catatan: limiter memakai memori dan bersifat **per instance** (tidak global); di Vercel setiap instance menghitung sendiri. IP klien dibaca lewat `CLIENT_IP_HEADER` (mis. `X-Real-IP` di Vercel): bila diisi, Fiber (`ProxyHeader` + `TrustProxy`) membaca header itu hanya jika peer TCP berupa alamat loopback/private/link-local; bila kosong, header tidak dipercaya dan IP = peer TCP (lokal). Jika peer proxy ternyata bukan alamat private, `c.IP()` kembali ke IP proxy dan semua klien berbagi satu hitungan limit — verifikasi setelah deploy (§13 langkah 8). Perlindungan utama brute force OTP tetap batas percobaan di database (§9.4).

---

## 10. Endpoint API

Prefix: `/api/v1`. Kolom **Akses**: `public`, `auth` (owner & staff), `owner`.

### 10.1 Daftar Endpoint

| Method | Path | Akses | Keterangan |
|---|---|---|---|
| GET | `/health` (tanpa prefix) | public | `{"status":"ok","database":"ok"}` (ping DB) |
| GET | `/auth/setup-status` | public | `{"owner_exists": bool}` |
| POST | `/auth/register-owner` | public | Buat owner + outlet + katalog default, kembalikan sesi |
| POST | `/auth/login` | public | Kembalikan sesi |
| POST | `/auth/refresh` | public | Rotasi refresh token |
| POST | `/auth/logout` | public | Cabut refresh token |
| POST | `/auth/forgot-password` | public | Kirim OTP |
| POST | `/auth/reset-password` | public | Reset password dengan OTP |
| GET | `/me` | auth | Profil user + outlet |
| PATCH | `/me` | auth | Ubah `name` |
| POST | `/me/change-password` | auth | `{current_password, new_password}` → sesi baru |
| GET | `/users` | owner | List staff (`outlet_id`, `search`, `page`, `limit`) |
| POST | `/users` | owner | Buat staff |
| GET | `/users/:id` | owner | Detail staff |
| PATCH | `/users/:id` | owner | Ubah `name`, `outlet_id`, `is_active` |
| POST | `/users/:id/reset-password` | owner | `{new_password}` |
| GET | `/outlets` | auth | Owner: semua; staff: outletnya saja |
| POST | `/outlets` | owner | Buat outlet + katalog default |
| PATCH | `/outlets/:id` | owner | Ubah `name`, `address`, `phone`, `is_active` |
| GET | `/services` | auth | Query: `outlet_id` (owner wajib jika >1 outlet), `include_inactive` (owner saja). Urut `sort_order`, `name` |
| POST | `/services` | owner | Buat layanan satuan |
| PATCH | `/services/:id` | owner | Ubah layanan (§8.8) |
| DELETE | `/services/:id` | owner | Soft delete layanan satuan |
| GET | `/customers` | auth | Autocomplete & list: `search`, `page`, `limit` (default 10 untuk autocomplete) |
| GET | `/customers/:id` | auth | Detail pelanggan |
| PATCH | `/customers/:id` | owner | Ubah `name`, `phone` |
| GET | `/orders` | auth | List order (§10.4) |
| POST | `/orders` | auth | Buat order |
| GET | `/orders/:id` | auth | Detail order |
| PUT | `/orders/:id` | owner | Edit order (§8.7) |
| PATCH | `/orders/:id/status` | auth | `{status}` (§8.4) |
| PATCH | `/orders/:id/payment` | auth | `{payment_status}` (§8.5) |
| DELETE | `/orders/:id` | owner | Soft delete |
| GET | `/dashboard` | auth | `range`, `outlet_id` (§11) |

Endpoint yang membuat resource mengembalikan `201`; delete & logout mengembalikan `204`.

### 10.2 Bentuk DTO Response

**Session** (register-owner, login, refresh, change-password):

```json
{
  "data": {
    "access_token": "eyJ...",
    "access_token_expires_at": "2026-10-27T08:27:00Z",
    "refresh_token": "q3Jx...",
    "refresh_token_expires_at": "2026-11-26T08:12:00Z",
    "user": { "...UserResponse" }
  }
}
```

**UserResponse**:

```json
{
  "id": "0192...", "name": "Jesi", "email": "owner@jesilaundry.com",
  "role": "owner", "is_active": true,
  "outlet": null,
  "last_login_at": "2026-10-27T08:12:00Z", "created_at": "2026-10-01T02:00:00Z"
}
```

Untuk staff, `outlet` berisi `{"id": "...", "code": "JL", "name": "Jesi Laundry Serpong"}`.

**OutletResponse**: `id, code, name, address, phone, is_active, created_at`.

**ServiceResponse**: `id, outlet_id, category, name, pricing_unit, regular_price, express_price, regular_duration_days, express_duration_days, min_quantity, is_system, is_active, sort_order`.

**CustomerResponse**: `id, name, phone, last_order_at`.

**OrderListItemResponse**: `id, order_number, outlet {id, code, name}, customer_name, customer_phone, speed, status, payment_status, total_amount, items_count, estimated_done_at, created_at`.

**OrderDetailResponse**:

```json
{
  "id": "0192...",
  "order_number": "JL-261027-0001",
  "outlet": { "id": "...", "code": "JL", "name": "Jesi Laundry" },
  "customer": { "id": "...", "name": "Budi", "phone": "6281234567890" },
  "speed": "regular",
  "status": "received",
  "payment_status": "unpaid",
  "total_amount": 96000,
  "estimated_done_at": "2026-10-30T08:12:00Z",
  "processing_at": null, "done_at": null, "picked_up_at": null, "paid_at": null,
  "notes": "Kemeja jangan dilipat",
  "items": [
    {
      "id": "...", "service_id": "...", "service_name": "Cuci Setrika",
      "category": "wash_iron", "pricing_unit": "kg",
      "quantity": 2.5, "length_m": null, "width_m": null,
      "billed_quantity": 3, "unit_price": 7000, "subtotal": 21000, "duration_days": 3
    },
    {
      "id": "...", "service_id": "...", "service_name": "Karpet",
      "category": "unit", "pricing_unit": "sqm",
      "quantity": 5, "length_m": 2, "width_m": 2.5,
      "billed_quantity": 5, "unit_price": 15000, "subtotal": 75000, "duration_days": 3
    }
  ],
  "created_by": { "id": "...", "name": "Staff A" },
  "created_at": "2026-10-27T08:12:00Z",
  "updated_at": "2026-10-27T08:12:00Z"
}
```

### 10.3 Contoh Request

**POST `/auth/register-owner`**

```json
{
  "name": "Jesi",
  "email": "owner@jesilaundry.com",
  "password": "rahasia123",
  "outlet_name": "Jesi Laundry",
  "outlet_code": "JL",
  "outlet_address": "Serpong",
  "outlet_phone": "081234567890"
}
```

**POST `/orders`**

```json
{
  "outlet_id": "0192...",
  "customer": { "id": null, "name": "Budi", "phone": "0812-3456-7890" },
  "speed": "regular",
  "payment_status": "unpaid",
  "notes": "Kemeja jangan dilipat",
  "items": [
    { "service_id": "<cuci setrika>", "quantity": 2.5 },
    { "service_id": "<bed cover>", "quantity": 1 },
    { "service_id": "<karpet>", "length_m": 2, "width_m": 2.5 }
  ]
}
```

- `outlet_id`: wajib untuk owner, diabaikan untuk staff.
- `customer`: kirim `id` untuk pelanggan lama; atau `name` (+ `phone` opsional) untuk pelanggan baru.
- `payment_status` opsional, default `unpaid`.

**PUT `/orders/:id`**: sama seperti POST tanpa `outlet_id` dan `payment_status`.

### 10.4 Query List Order

| Param | Contoh | Keterangan |
|---|---|---|
| `status` | `received,processing` | Multi nilai dipisah koma |
| `payment_status` | `unpaid` | |
| `search` | `JL-2610` / `budi` | `order_number ILIKE` atau `customer_name ILIKE` |
| `date_from`, `date_to` | `2026-10-01` | Tanggal lokal `APP_TIMEZONE`, inklusif |
| `outlet_id` | uuid | Owner saja |
| `page`, `limit` | `1`, `20` | `limit` maks 100 |

Urutan: `created_at DESC`. Hitung `items_count` dengan subquery GORM, bukan N+1.

---

## 11. Dashboard

### 11.1 Range & Bucket

`GET /api/v1/dashboard?range=24h&outlet_id=...`

| `range` | Rentang | `bucket` | Jumlah titik |
|---|---|---|---:|
| `1h` | `now − 1 jam` s/d `now` | `5m` | 12–13 |
| `24h` | `now − 24 jam` s/d `now` | `hour` | 24–25 |
| `7d` | `now − 7 hari` s/d `now` | `day` | 7–8 |
| `30d` | `now − 30 hari` s/d `now` | `day` | 30–31 |
| `1y` | `now − 1 tahun` s/d `now` | `month` | 12–13 |
| `all` | order pertama (lihat bawah) s/d `now` | `month` jika rentang ≤ 24 bulan kalender, selain itu `year` | ≤ 25 (month) atau jumlah tahun + 1 (year) |

- Rentang `all` (seluruh waktu): `from` = `MIN(orders.created_at)` dengan scope outlet yang sama dan `deleted_at IS NULL` (satu query tambahan khusus `all`, sehingga maksimum query menjadi 7). Jika belum ada order sama sekali: `from = to = now`, `bucket = month`, dan `series` berisi satu bucket (bulan berjalan) bernilai 0. Pemilihan bucket: hitung selisih bulan kalender antara bulan `from` dan bulan `to` di zona bisnis; ≤ 24 → `month`, > 24 → `year`. Response `range = "all"`, `from` = waktu order pertama (UTC).
- Rentang bersifat rolling (berakhir di `now`). Filter berdasarkan `orders.created_at` (waktu order masuk), order terhapus dikecualikan.
- Bucket disejajarkan di zona `APP_TIMEZONE`:
  - `hour`/`day`/`month`/`year`: `date_trunc('<unit>', orders.created_at AT TIME ZONE '<tz>')`.
  - `5m`: `date_bin('5 minutes', orders.created_at AT TIME ZONE '<tz>', TIMESTAMP '2000-01-01')`.
  - Nama zona waktu dikirim sebagai parameter query (bukan string concatenation).
- Ekspresi agregasi di atas adalah satu-satunya raw SQL yang diizinkan; gunakan lewat `Select(...)` / `Group(...)` GORM dengan parameter terikat.
- **Gap filling di Go** (`dashboard/range.go`): bangun daftar semua bucket dari bucket pertama sampai bucket `now`, isi 0 untuk bucket kosong.

### 11.2 Response

```json
{
  "data": {
    "range": "7d",
    "bucket": "day",
    "from": "2026-10-20T08:12:00Z",
    "to": "2026-10-27T08:12:00Z",
    "timezone": "Asia/Jakarta",
    "outlet_id": null,
    "totals": {
      "orders": 42,
      "weight_kg": 156.5,
      "unit_pieces": 9,
      "area_sqm": 12.5,
      "revenue": 1250000,
      "revenue_paid": 900000,
      "revenue_unpaid": 350000
    },
    "by_category": [
      { "category": "wash_iron", "orders": 20, "quantity": 80.5, "revenue": 700000 },
      { "category": "iron_only", "orders": 8, "quantity": 30, "revenue": 150000 },
      { "category": "wash_fold", "orders": 10, "quantity": 46, "revenue": 230000 },
      { "category": "unit", "orders": 6, "quantity": 21.5, "revenue": 170000 }
    ],
    "by_unit_service": [
      { "service_id": "...", "service_name": "Bed Cover", "pricing_unit": "piece", "orders": 3, "quantity": 4, "revenue": 100000 },
      { "service_id": "...", "service_name": "Karpet", "pricing_unit": "sqm", "orders": 2, "quantity": 12.5, "revenue": 70000 }
    ],
    "by_speed": [
      { "speed": "regular", "orders": 35, "revenue": 950000 },
      { "speed": "express", "orders": 7, "revenue": 300000 }
    ],
    "by_status": [
      { "status": "received", "orders": 5 },
      { "status": "processing", "orders": 7 },
      { "status": "done", "orders": 4 },
      { "status": "picked_up", "orders": 26 }
    ],
    "series": [
      { "bucket_start": "2026-10-21T00:00:00+07:00", "orders": 6, "weight_kg": 20.5, "revenue": 180000 }
    ],
    "operational": {
      "in_progress": 12,
      "ready_for_pickup": 4,
      "unpaid_orders": 6,
      "unpaid_amount": 210000
    }
  }
}
```

Definisi:

- `weight_kg` = jumlah `quantity` (berat aktual, bukan `billed_quantity`) dari item `pricing_unit = kg`.
- `unit_pieces` = jumlah `quantity` item `piece`; `area_sqm` = jumlah `quantity` item `sqm`.
- `revenue` = jumlah `total_amount` order dalam rentang; per kategori/layanan memakai jumlah `subtotal`.
- `by_category[].orders` = jumlah order **distinct** yang memiliki item kategori itu; `quantity` = jumlah `quantity`.
- `by_unit_service` dikelompokkan per `service_id`; `service_name` = nama snapshot terbaru (`MAX(service_name)`), sehingga layanan yang sudah dihapus tetap muncul.
- `by_status` = status **saat ini** dari order yang masuk dalam rentang. Selalu kirim 4 status (0 jika kosong). `by_category` selalu kirim 4 kategori; `by_speed` selalu kirim 2.
- `operational` = kondisi saat ini, **tidak** dibatasi rentang (tetap dibatasi outlet): `in_progress` = status `received`+`processing`; `ready_for_pickup` = status `done`; `unpaid_orders`/`unpaid_amount` = order belum lunas yang belum `picked_up`.
- **Staff**: semua field pendapatan (`revenue`, `revenue_paid`, `revenue_unpaid`, `unpaid_amount`, dan `revenue` di setiap array) **tidak dikirim**. Implementasikan dengan field pointer + `omitempty` yang dikosongkan di service berdasarkan role, bukan hanya disembunyikan di client.

Gunakan sesedikit mungkin query (target ≤ 6 query per request) dan pastikan semua memakai index `(outlet_id, created_at)`.

---

## 12. Docker

### 12.1 `Dockerfile` (multi-stage)

```dockerfile
# ---- build ----
FROM golang:1.27-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/api ./cmd/api \
 && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/migrate ./cmd/migrate

# ---- runtime ----
FROM gcr.io/distroless/static-debian12:nonroot
WORKDIR /app
COPY --from=build /out/api /app/api
COPY --from=build /out/migrate /app/migrate
ENV PORT=8080
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/app/api"]
```

- Jangan memakai `RUN --mount=type=cache` agar build kompatibel dengan builder Vercel.
- Image akhir distroless static non-root (tanpa shell). Data zona waktu sudah ter-embed lewat `time/tzdata`.

### 12.2 `.dockerignore`

```
.git
.env
*.md
docker-compose.yml
tmp/
```

### 12.3 `docker-compose.yml` (development)

```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 3s
      retries: 10

  migrate:
    build: .
    entrypoint: ["/app/migrate"]
    env_file: .env
    environment:
      DATABASE_URL: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}?sslmode=disable
    depends_on:
      db: { condition: service_healthy }

  api:
    build: .
    env_file: .env
    environment:
      DATABASE_URL: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}?sslmode=disable
    ports: ["8080:8080"]
    depends_on:
      migrate: { condition: service_completed_successfully }

volumes:
  pgdata:
```

Perintah:

```bash
cp .env.example .env
docker compose up --build          # db → migrate → api
docker compose run --rm migrate    # migrasi ulang setelah mengubah model
```

Alternatif tanpa Docker untuk api: jalankan hanya `docker compose up db`, lalu `go run ./cmd/migrate` dan `go run ./cmd/api`.

### 12.4 Graceful Shutdown

`cmd/api/main.go` menangkap `SIGINT`/`SIGTERM`, memanggil `app.ShutdownWithTimeout(25 * time.Second)`, lalu menutup koneksi DB. (Vercel mengirim `SIGTERM` dengan masa tenggang 30 detik saat scale-down.)

### 12.5 Pool Koneksi

`database.Open` mengatur `SetMaxOpenConns(DB_MAX_OPEN_CONNS)`, `SetMaxIdleConns(DB_MAX_IDLE_CONNS)`, `SetConnMaxIdleTime(5m)`, `SetConnMaxLifetime(30m)`. Di Vercel gunakan nilai kecil (mis. 5 / 2) karena bisa ada beberapa instance paralel, dan gunakan connection string **pooled** Neon untuk `DATABASE_URL`. GORM: `PrepareStmt: false`, logger level `Warn` di production.

---

## 13. Deploy ke Vercel (Container Runtime)

Vercel Container Runtime (Beta) membangun image dari `Dockerfile` dan menjalankannya sebagai Vercel Function yang di-scale otomatis. Server wajib listen di `PORT`, stateless, dan menyimpan data di database eksternal.

Langkah:

1. **Database**: buat Neon Postgres (via Vercel Marketplace: `vercel integration add neon`, atau dari console Neon lalu isi env manual). Pastikan tersedia `DATABASE_URL` (pooled) dan `DATABASE_URL_UNPOOLED` (direct).
2. **Project Vercel**: impor repo, set **Root Directory = `server`**.
3. **Framework preset = Container.** Karena folder berisi `go.mod`, paksa preset container:
   ```bash
   vercel project update --framework container --yes
   ```
4. **Environment variables** (Production & Preview):
   `APP_ENV=production`, `PORT=8080` (**wajib**: tanpa `PORT` Vercel mengarahkan traffic ke port 80, yang tidak bisa dibuka user non-root di image distroless), `CLIENT_IP_HEADER=X-Real-IP`, `APP_TIMEZONE=Asia/Jakarta`, `JWT_ACCESS_SECRET`, `JWT_ACCESS_TTL=15m`, `REFRESH_TOKEN_TTL=720h`, `OTP_SECRET`, `OTP_TTL=10m`, `RESEND_API_KEY`, `MAIL_FROM`, `DB_MAX_OPEN_CONNS=5`, `DB_MAX_IDLE_CONNS=2` (+ `DATABASE_URL`, `DATABASE_URL_UNPOOLED` dari Neon).
5. **Migrasi** dijalankan dari mesin lokal sebelum deploy versi yang mengubah model:
   ```bash
   DATABASE_URL="<neon-unpooled-url>" go run ./cmd/migrate
   ```
6. Deploy (`vercel deploy --prod` atau push ke branch production), lalu cek `GET https://<project>.vercel.app/health`.
7. **Resend**: verifikasi domain pengirim di Resend agar `MAIL_FROM` bisa dipakai.
8. **Verifikasi IP klien untuk rate limit**: kirim 11 `POST /api/v1/auth/login` salah dari satu jaringan hingga `RATE_LIMITED`, lalu coba login dari jaringan lain (mis. data seluler). Jika jaringan kedua ikut terblokir, Fiber tidak mempercayai peer Vercel (bukan alamat private) dan membaca IP proxy; kosongkan `CLIENT_IP_HEADER` atau tambahkan rentang proxy ke `TrustProxyConfig.Proxies` di `internal/app/app.go`.

Catatan Container Runtime (dokumentasi Vercel, diperbarui 2026-07-07): Beta di semua paket; scale-down setelah 5 menit tanpa traffic di production dan **30 detik di preview**; instance menerima `SIGTERM` dengan masa tenggang 30 detik (server memakai 25 detik); log dibaca dari stdout/stderr; **Secure Compute dan Static IP belum didukung** untuk container, sehingga Neon tidak bisa dibatasi ke IP tetap Vercel (andalkan kredensial + TLS). Preset container otomatis dipilih untuk project baru bila tidak ada framework lain yang terdeteksi; perintah `vercel project update --framework container --yes` di langkah 3 adalah cara resmi memaksanya (alternatif: nama file `Dockerfile.vercel`).

Catatan: paket Hobby Vercel hanya untuk penggunaan non-komersial (lihat ARCHITECTURE.md §10.3). Image yang sama dapat dijalankan di penyedia container lain tanpa perubahan kode.

---

## 14. Fase Implementasi

Setiap fase: kode di-`gofmt`, `go build ./...` dan `go vet ./...` lolos, tanpa file test. Akhiri fase dengan ringkasan file (path lengkap) + daftar perintah `curl` untuk uji manual, lalu **berhenti**.

### B1 — Fondasi

- `go.mod` (module `jesi-laundry-app-server`, `go 1.27`), dependency §2.
- `platform/config`, `platform/database` (Open, Migrate, WithTx), `platform/timeutil`, `platform/validation`, `platform/httpx`.
- Semua file di `internal/model/` (enum + entitas) sesuai §6.
- `cmd/migrate`, `cmd/api`, `internal/app` dengan `GET /health`.
- `Dockerfile`, `.dockerignore`, `docker-compose.yml`, `.env.example`, `.gitignore`.
- **Selesai jika**: `docker compose up --build` → migrasi sukses, semua tabel & constraint terbentuk, `/health` mengembalikan ok.

### B2 — Auth & Keamanan

- `platform/security`, `platform/mailer` (Resend + Log + template id/en), `platform/middleware`.
- Modul `outlet` & `catalog` bagian repository + `defaults.go` (dibutuhkan register).
- Modul `auth` (semua endpoint `/auth/*`) dan endpoint `/me`.
- Rate limiter endpoint auth.
- **Selesai jika**: register owner → login → refresh (rotasi & deteksi reuse) → logout → forgot/reset password (OTP terlihat di log saat dev) berjalan; register kedua ditolak.

### B3 — Master Data

- Endpoint outlet, services, users (staff) lengkap dengan aturan §8.8–§8.9.
- **Selesai jika**: owner bisa membuat outlet kedua (katalog default ikut terbuat), mengubah harga, menambah/menonaktifkan/menghapus satuan, membuat staff; staff ditolak `FORBIDDEN` untuk endpoint owner.

### B4 — Pelanggan & Order

- Modul `customer` dan `order` lengkap (§8.1–§8.7, §10.4).
- **Selesai jika**: membuat order campuran kiloan + pcs + m² menghasilkan total benar (termasuk minimum 3 kg), nomor order berurutan per hari, transisi status & pembayaran sesuai aturan per role, edit & hapus owner berjalan, staff tidak bisa melihat order outlet lain.

### B5 — Dashboard

- Modul `dashboard` sesuai §11.
- **Selesai jika**: kelima range mengembalikan series lengkap (dengan bucket kosong bernilai 0), field pendapatan hilang untuk staff, filter outlet berjalan.

### B6 — Kesiapan Produksi

- Graceful shutdown, pengaturan pool, logging production, review keamanan (tidak ada secret/OTP di log).
- `README.md` singkat di root monorepo (cara menjalankan server) dan langkah deploy Vercel (§13).
- **Selesai jika**: image berjalan lokal dengan `APP_ENV=production` + database Neon, siap di-deploy.