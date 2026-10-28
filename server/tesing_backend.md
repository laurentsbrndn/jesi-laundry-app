# Panduan Uji Manual Backend — Jesi Laundry App (B1–B6)

> Ikuti urut dari B1 sampai B6. Jika sebuah fase gagal, **perbaiki dulu sebelum lanjut** (lihat §8 untuk cara melapor).
> Panduan ini hanya dokumen. Jangan dimasukkan sebagai file test di repo.
> Estimasi waktu total: 2–3 jam. Semua perintah dijalankan di macOS (zsh) dari folder `server/`.

---

## 0. Persiapan

### 0.1 Alat

```bash
brew install jq
go version
docker --version
docker info
```

- `go version` harus 1.27.x. `docker info` tidak boleh error (nyalakan Docker Desktop dulu).
- `jq` dipakai untuk membaca JSON.

### 0.2 Blok helper (tempel sekali per terminal baru)

zsh menolak baris komentar `#` secara default, jadi aktifkan dulu. Simpan blok ini di `~/jesi-helpers.sh` (di luar repo), lalu `source ~/jesi-helpers.sh` setiap membuka terminal baru.

```bash
setopt interactive_comments 2>/dev/null

export B=http://localhost:8080/api/v1
export H='Content-Type: application/json'

# api METHOD PATH TOKEN [JSON]  -> cetak body respons (untuk dipipe ke jq)
api() {
  local m=$1 p=$2 t=$3 d=$4
  local args=(-s -X "$m" "$B$p" -H "$H")
  [ -n "$t" ] && args+=(-H "Authorization: Bearer $t")
  [ -n "$d" ] && args+=(-d "$d")
  curl "${args[@]}"
}

# st METHOD PATH TOKEN [JSON]   -> cetak HTTP status saja
st() {
  local m=$1 p=$2 t=$3 d=$4
  local args=(-s -o /dev/null -w "%{http_code}\n" -X "$m" "$B$p" -H "$H")
  [ -n "$t" ] && args+=(-H "Authorization: Bearer $t")
  [ -n "$d" ] && args+=(-d "$d")
  curl "${args[@]}"
}

# tok EMAIL PASSWORD -> cetak access token
tok() { api POST /auth/login "" "{\"email\":\"$1\",\"password\":\"$2\"}" | jq -r .data.access_token; }

# dbq "SQL"  -> jalankan query di Postgres compose
dbq() { docker compose exec -T db psql -U jesi -d jesi_laundry -c "$1"; }

# reset: hapus semua data & jalankan ulang dari nol
reset_all() {
  docker compose down -v >/dev/null 2>&1
  docker compose up --build -d
  until curl -sf localhost:8080/health >/dev/null; do sleep 1; done
  echo "server siap"
}

# bersihkan rate limiter (disimpan di memori api)
reset_limiter() { docker compose restart api >/dev/null && until curl -sf localhost:8080/health >/dev/null; do sleep 1; done; echo "limiter direset"; }
```

### 0.3 Aturan baca hasil

- Perintah `api ... | jq` menampilkan JSON. Perintah `st ...` hanya menampilkan angka status HTTP.
- Format error server selalu `{"error": {"code": "...", "message": "...", "details": [...]}}`. Yang diperiksa adalah `code` dan status HTTP, bukan `message`.
- Access token berlaku **15 menit**. Jika tiba-tiba semua respons `401 TOKEN_EXPIRED`, ambil token baru dengan `tok`.
- Rate limit login 10/menit dan forgot-password 5/menit (per IP, di memori). Jika muncul `429 RATE_LIMITED` di tengah pengujian, jalankan `reset_limiter`.
- Setiap uji punya bagian **Harus:** yang berisi hasil yang benar. Jika hasilnya berbeda, itu temuan.

---

## 1. Fase B1 — Fondasi (config, database, model, migrasi, Docker)

### 1.1 Kompilasi bersih

```bash
cd server
gofmt -l .
go build ./...
go vet ./...
```

**Harus:** `gofmt -l .` tidak mencetak apa pun, dua perintah lainnya tidak mencetak error.

### 1.2 Build image dan jalankan

```bash
cp .env.example .env
docker build -t jesi-server .
docker compose down -v
docker compose up --build -d
docker compose ps -a
```

**Harus:** `db` berstatus healthy, `api` berstatus running (port 8080), `migrate` berstatus `Exited (0)`. Jika `migrate` exit bukan 0:

```bash
docker compose logs migrate
```

### 1.3 Health check

```bash
curl -i localhost:8080/health
```

**Harus:** status `200`, body `{"status":"ok","database":"ok"}`.

Matikan database sebentar:

```bash
docker compose stop db
curl -i localhost:8080/health
docker compose start db
```

**Harus:** saat db mati, status bukan `200` dan body menandakan database bermasalah. Server tidak crash. Setelah db hidup lagi dan beberapa detik berlalu, `/health` kembali `200`.

### 1.4 Route tidak ada

```bash
curl -i localhost:8080/rute-tidak-ada
```

**Harus:** status `404`, body envelope error dengan `code` `NOT_FOUND` (bukan teks polos).

### 1.5 Skema database — tabel

```bash
dbq '\dt'
```

**Harus:** tepat 9 tabel: `customers`, `laundry_services`, `order_counters`, `order_items`, `orders`, `outlets`, `password_reset_otps`, `refresh_tokens`, `users`.

### 1.6 Skema database — constraint dan index

```bash
dbq "select tablename, indexname, indexdef from pg_indexes where schemaname='public' order by 1,2;"
```

**Harus ada:**

| Tabel | Index yang harus ada |
|---|---|
| `users` | unik pada `email`; **`uq_users_single_owner`** dengan `WHERE (role = 'owner')` |
| `outlets` | unik pada `code` |
| `refresh_tokens` | unik pada `token_hash`; index pada `user_id` |
| `password_reset_otps` | index komposit `(user_id, created_at)` |
| `customers` | index ekspresi `lower(name)`; index `phone` |
| `orders` | unik pada `order_number`; index komposit `(outlet_id, created_at)`; index `status`, `payment_status`, `deleted_at` |
| `order_items` | index `order_id`, `service_id` |
| `laundry_services` | index `(outlet_id, category)` |

Jika `uq_users_single_owner` tidak punya `WHERE`, atau index `lower(name)` tidak ada, itu bug serius (jaminan 1 owner dan pencarian pelanggan bergantung padanya).

```bash
dbq "select conrelid::regclass as tabel, conname, pg_get_constraintdef(oid) as definisi from pg_constraint where contype='c' order by 1,2;"
```

**Harus ada check constraint untuk:** `users.role` (`owner`/`staff`), `chk_users_role_outlet`, `laundry_services` (`category`, `pricing_unit`, harga ≥ 0, durasi 1–30), `orders` (`speed`, `status`, `payment_status`, `total_amount ≥ 0`).

```bash
dbq "select conrelid::regclass as tabel, conname, confdeltype from pg_constraint where contype='f' order by 1,2;"
```

**Harus:** `confdeltype = c` (cascade) untuk `refresh_tokens.user_id`, `password_reset_otps.user_id`, dan `order_items.order_id`. Semua foreign key lain `r` (restrict).

### 1.7 Tipe kolom

```bash
dbq '\d orders'
dbq '\d order_items'
dbq '\d order_counters'
```

**Harus:**
- Kolom uang (`total_amount`, `unit_price`, `subtotal`, `regular_price`, `express_price`) bertipe **bigint**.
- Kolom kuantitas (`quantity`, `length_m`, `width_m`, `billed_quantity`, `min_quantity`) bertipe **numeric(10,2)**.
- Semua kolom waktu bertipe **timestamp with time zone**.
- `order_counters` punya primary key komposit `(outlet_id, local_date)`.

### 1.8 Constraint benar-benar bekerja

```bash
dbq "insert into users (id,name,email,password_hash,role,outlet_id,is_active,created_at,updated_at) values (gen_random_uuid(),'x','a@x.com','h','staff',null,true,now(),now());"
```
**Harus:** ERROR melanggar `chk_users_role_outlet`.

```bash
dbq "insert into users (id,name,email,password_hash,role,outlet_id,is_active,created_at,updated_at) values (gen_random_uuid(),'x','a@x.com','h','admin',null,true,now(),now());"
```
**Harus:** ERROR melanggar check pada `role`.

```bash
dbq "insert into users (id,name,email,password_hash,role,outlet_id,is_active,created_at,updated_at) values (gen_random_uuid(),'o1','o1@x.com','h','owner',null,true,now(),now());"
dbq "insert into users (id,name,email,password_hash,role,outlet_id,is_active,created_at,updated_at) values (gen_random_uuid(),'o2','o2@x.com','h','owner',null,true,now(),now());"
dbq "delete from users;"
```
**Harus:** insert pertama berhasil, insert kedua ERROR melanggar `uq_users_single_owner`. Perintah terakhir membersihkan data uji.

### 1.9 Migrasi idempoten

```bash
docker compose run --rm migrate
echo "exit=$?"
```

**Harus:** `exit=0`, tidak ada error, dan `dbq '\dt'` masih 9 tabel.

### 1.10 Selesai B1 jika

Semua poin 1.1–1.9 sesuai. Simpan hasilnya di checklist §9.

---

## 2. Fase B2 — Auth & Keamanan

Mulai dari database bersih:

```bash
reset_all
```

Siapkan payload (dipakai berulang):

```bash
export REG='{"name":"Jesi","email":"owner@jesilaundry.com","password":"rahasia123","outlet_name":"Jesi Laundry","outlet_code":"JL","outlet_address":"Serpong","outlet_phone":"081234567890"}'
```

### 2.1 Status setup awal

```bash
api GET /auth/setup-status "" | jq
```
**Harus:** `{"data":{"owner_exists":false}}`.

### 2.2 Validasi register

```bash
st POST /auth/register-owner "" '{"name":"A","email":"bukan-email","password":"123","outlet_name":"X","outlet_code":"jl"}'
api POST /auth/register-owner "" '{"name":"A","email":"bukan-email","password":"123","outlet_name":"X","outlet_code":"jl"}' | jq '.error'
```
**Harus:** status `422`, `code = VALIDATION_ERROR`, `details` memuat field `email`, `password`, dan `outlet_code`.

```bash
st POST /auth/register-owner "" '{bukan json'
```
**Harus:** `400` (`BAD_REQUEST`).

Password hanya huruf atau hanya angka harus ditolak:

```bash
st POST /auth/register-owner "" '{"name":"A","email":"a@x.com","password":"abcdefgh","outlet_name":"X","outlet_code":"JL"}'
st POST /auth/register-owner "" '{"name":"A","email":"a@x.com","password":"12345678","outlet_name":"X","outlet_code":"JL"}'
```
**Harus:** keduanya `422`.

### 2.3 Race condition register (dua request bersamaan)

```bash
for i in 1 2; do st POST /auth/register-owner "" "$REG" & done; wait
```
**Harus:** satu `201` dan satu `409` (urutan bebas). Lalu:

```bash
dbq "select (select count(*) from users where role='owner') as owner, (select count(*) from outlets) as outlet, (select count(*) from laundry_services) as layanan;"
```
**Harus:** `owner=1, outlet=1, layanan=6`. Jika `outlet=2` atau `layanan=12`, transaksi register tidak atomik (bug).

### 2.4 Hasil register

```bash
api GET /auth/setup-status "" | jq
st POST /auth/register-owner "" "$REG"
api POST /auth/register-owner "" "$REG" | jq -r .error.code
```
**Harus:** `owner_exists` kini `true`; register ketiga `409` dengan `OWNER_ALREADY_EXISTS`.

```bash
dbq "select name, email, role, outlet_id is null as tanpa_outlet, left(password_hash,7) as hash, is_active from users;"
dbq "select code, name, is_active from outlets;"
dbq "select category, name, pricing_unit, regular_price, express_price, regular_duration_days, express_duration_days, min_quantity, is_system, is_active from laundry_services order by sort_order;"
```
**Harus:**
- User: role `owner`, `tanpa_outlet = t`, hash diawali `$2a$12$` atau `$2b$12$` (bcrypt cost 12), `is_active = t`.
- Outlet: `JL`, aktif.
- 6 layanan sesuai katalog default: Cuci Setrika (7000/12000, min 3), Setrika (5000/8000, min 3), Cuci Lipat (5000/8000, min 3), Bed Cover, Boneka, Karpet (tidak ada minimum). Tiga layanan kiloan `is_system = t`, durasi 3 hari reguler dan 1 hari express.

### 2.5 Login

```bash
st POST /auth/login "" '{"email":"owner@jesilaundry.com","password":"salah12345"}'
st POST /auth/login "" '{"email":"tidakada@x.com","password":"salah12345"}'
api POST /auth/login "" '{"email":"owner@jesilaundry.com","password":"salah12345"}' | jq -c '.error'
api POST /auth/login "" '{"email":"tidakada@x.com","password":"salah12345"}' | jq -c '.error'
```
**Harus:** keduanya `401` `INVALID_CREDENTIALS` dengan body yang **identik** (email tidak terdaftar tidak boleh bisa dibedakan dari password salah).

```bash
R=$(api POST /auth/login "" '{"email":"owner@jesilaundry.com","password":"rahasia123"}')
jq 'del(.data.access_token, .data.refresh_token)' <<< "$R"
OT=$(jq -r .data.access_token <<< "$R"); RT1=$(jq -r .data.refresh_token <<< "$R")
echo "$R" | grep -c password_hash
```
**Harus:** `user` berisi `id, name, email, role=owner, is_active, outlet=null`. Hitungan `grep` bernilai `0` (hash password tidak pernah dikirim).

Periksa isi access token:

```bash
jq -R 'split(".")[1] | @base64d | fromjson' <<< "$OT"
```
**Harus:** `sub` (UUID), `role: "owner"`, `iss: "jesi-laundry"`, dan `exp - iat = 900` detik. `oid` kosong/tidak ada untuk owner.

### 2.6 Endpoint terproteksi

```bash
st GET /me ""
st GET /me "token-sampah"
st GET /me "$OT"
```
**Harus:** `401`, `401`, `200`.

```bash
api PATCH /me "$OT" '{"name":"Jesi Baru"}' | jq -r .data.name
st PATCH /me "$OT" '{"name":""}'
api GET /me "$OT" | jq -c '{name:.data.name, role:.data.role}'
```
**Harus:** `Jesi Baru`, lalu `422`, lalu nama tetap `Jesi Baru`.

### 2.7 Token kedaluwarsa

```bash
sed -i '' 's/^JWT_ACCESS_TTL=.*/JWT_ACCESS_TTL=10s/' .env
docker compose up -d --no-deps --force-recreate api
until curl -sf localhost:8080/health >/dev/null; do sleep 1; done
T=$(tok owner@jesilaundry.com rahasia123)
st GET /me "$T"
sleep 12
api GET /me "$T" | jq -r .error.code
```
**Harus:** `200`, lalu setelah 12 detik `TOKEN_EXPIRED` (bukan `UNAUTHORIZED`).

Kembalikan konfigurasi:

```bash
sed -i '' 's/^JWT_ACCESS_TTL=.*/JWT_ACCESS_TTL=15m/' .env
docker compose up -d --no-deps --force-recreate api
until curl -sf localhost:8080/health >/dev/null; do sleep 1; done
OT=$(tok owner@jesilaundry.com rahasia123)
```

### 2.8 Refresh token: rotasi dan deteksi reuse

```bash
R=$(api POST /auth/login "" '{"email":"owner@jesilaundry.com","password":"rahasia123"}'); RT1=$(jq -r .data.refresh_token <<< "$R")
R2=$(api POST /auth/refresh "" "{\"refresh_token\":\"$RT1\"}"); echo "$R2" | jq -c '.data | keys'
RT2=$(jq -r .data.refresh_token <<< "$R2")
echo "RT1 == RT2 ? $([ "$RT1" = "$RT2" ] && echo SAMA-BURUK || echo beda-baik)"
```
**Harus:** `beda-baik`, dan respons berisi token baru.

```bash
dbq "select to_char(created_at,'HH24:MI:SS') jam, revoked_at is not null as dicabut, replaced_by_id is not null as ada_pengganti, length(token_hash) as panjang_hash from refresh_tokens order by created_at desc limit 3;"
dbq "select count(*) from refresh_tokens where token_hash = '$RT1';"
```
**Harus:** token lama `dicabut = t` dan `ada_pengganti = t`; `panjang_hash = 64`; hitungan token mentah di database `0` (token tidak pernah disimpan mentah).

Reuse token lama:

```bash
api POST /auth/refresh "" "{\"refresh_token\":\"$RT1\"}" | jq -r .error.code
api POST /auth/refresh "" "{\"refresh_token\":\"$RT2\"}" | jq -r .error.code
```
**Harus:** keduanya `INVALID_REFRESH_TOKEN`. Yang kedua gagal karena reuse mencabut **semua** sesi user (ini perilaku keamanan yang benar).

```bash
dbq "select count(*) filter (where revoked_at is null) as aktif, count(*) as total from refresh_tokens;"
```
**Harus:** `aktif = 0`.

Token acak:

```bash
api POST /auth/refresh "" '{"refresh_token":"acak-tidak-dikenal"}' | jq -r .error.code
```
**Harus:** `INVALID_REFRESH_TOKEN`.

### 2.9 Logout

```bash
R=$(api POST /auth/login "" '{"email":"owner@jesilaundry.com","password":"rahasia123"}'); RT3=$(jq -r .data.refresh_token <<< "$R")
st POST /auth/logout "" "{\"refresh_token\":\"$RT3\"}"
api POST /auth/refresh "" "{\"refresh_token\":\"$RT3\"}" | jq -r .error.code
st POST /auth/logout "" "{\"refresh_token\":\"$RT3\"}"
st POST /auth/logout "" '{"refresh_token":"tidak-dikenal"}'
```
**Harus:** `204`, `INVALID_REFRESH_TOKEN`, `204`, `204` (logout idempoten).

### 2.10 Lupa password (OTP)

```bash
reset_limiter
curl -s -X POST $B/auth/forgot-password -H "$H" -d '{"email":"tidakada@x.com"}' | jq -c
curl -s -X POST $B/auth/forgot-password -H "$H" -H "Accept-Language: en" -d '{"email":"owner@jesilaundry.com"}' | jq -c
```
**Harus:** keduanya `200` dengan body **identik**: `{"data":{"retry_after_seconds":60}}`.

Ambil OTP dari log (di development OTP dicetak oleh `LogMailer`):

```bash
docker compose logs api --since 2m | grep -E "[0-9]{6}"
```
**Harus:** hanya ada satu baris dengan kode 6 digit, dan itu untuk email owner (bukan untuk `tidakada@x.com`). Format log bisa berbeda, cari angka 6 digit-nya. Simpan di `OTP1`.

Cooldown 60 detik:

```bash
curl -s -X POST $B/auth/forgot-password -H "$H" -d '{"email":"owner@jesilaundry.com"}' | jq -c
docker compose logs api --since 1m | grep -cE "[0-9]{6}"
dbq "select count(*) from password_reset_otps;"
```
**Harus:** respons tetap `200`, tapi tidak ada OTP baru di log dan tabel tetap berisi 1 baris.

OTP salah dan batas percobaan:

```bash
for i in 1 2 3 4 5; do api POST /auth/reset-password "" '{"email":"owner@jesilaundry.com","otp":"000000","new_password":"passbaru123"}' | jq -r .error.code; done
dbq "select attempts from password_reset_otps;"
api POST /auth/reset-password "" "{\"email\":\"owner@jesilaundry.com\",\"otp\":\"$OTP1\",\"new_password\":\"passbaru123\"}" | jq -r .error.code
st POST /auth/reset-password "" "{\"email\":\"owner@jesilaundry.com\",\"otp\":\"$OTP1\",\"new_password\":\"passbaru123\"}"
```
**Harus:** lima kali `OTP_INVALID`; `attempts = 5`; lalu **walau OTP benar**, hasilnya `OTP_TOO_MANY_ATTEMPTS` dengan status `429`.

Tunggu cooldown, minta OTP baru:

```bash
sleep 61
curl -s -X POST $B/auth/forgot-password -H "$H" -d '{"email":"owner@jesilaundry.com"}' | jq -c
docker compose logs api --since 1m | grep -E "[0-9]{6}"
dbq "select attempts, used_at is not null as terpakai from password_reset_otps order by created_at;"
```
**Harus:** OTP baru muncul di log (simpan sebagai `OTP2`); OTP lama `terpakai = t`.

```bash
api POST /auth/reset-password "" "{\"email\":\"owner@jesilaundry.com\",\"otp\":\"$OTP1\",\"new_password\":\"passbaru123\"}" | jq -r .error.code
st POST /auth/reset-password "" "{\"email\":\"owner@jesilaundry.com\",\"otp\":\"$OTP2\",\"new_password\":\"lemah\"}"
st POST /auth/reset-password "" "{\"email\":\"owner@jesilaundry.com\",\"otp\":\"$OTP2\",\"new_password\":\"passbaru123\"}"
```
**Harus:** OTP lama ditolak (`OTP_INVALID` atau `OTP_EXPIRED`); password lemah `422` (OTP tidak hangus); password valid `204`.

```bash
st POST /auth/login "" '{"email":"owner@jesilaundry.com","password":"rahasia123"}'
st POST /auth/login "" '{"email":"owner@jesilaundry.com","password":"passbaru123"}'
api POST /auth/reset-password "" "{\"email\":\"owner@jesilaundry.com\",\"otp\":\"$OTP2\",\"new_password\":\"passbaru999\"}" | jq -r .error.code
```
**Harus:** `401`, `200`, dan OTP yang sama tidak bisa dipakai dua kali (`OTP_EXPIRED`). Semua refresh token lama juga harus sudah tercabut (uji dengan token dari sebelum reset).

### 2.11 Ganti password

```bash
OT=$(tok owner@jesilaundry.com passbaru123)
st POST /me/change-password "$OT" '{"current_password":"salah12345","new_password":"lagi12345"}'
api POST /me/change-password "$OT" '{"current_password":"passbaru123","new_password":"lagi12345"}' | jq -c '.data | keys'
st POST /auth/login "" '{"email":"owner@jesilaundry.com","password":"passbaru123"}'
st POST /auth/login "" '{"email":"owner@jesilaundry.com","password":"lagi12345"}'
```
**Harus:** `401` (password lama salah); respons sukses berisi sesi baru (`access_token`, `refresh_token`, `user`, dst.); login password lama `401`; password baru `200`.

### 2.12 Rate limit

```bash
reset_limiter
for i in {1..11}; do st POST /auth/login "" '{"email":"x@x.com","password":"salah12345"}'; done
```
**Harus:** sepuluh kali `401`, lalu request ke-11 `429`. Cek kode:

```bash
api POST /auth/login "" '{"email":"x@x.com","password":"salah12345"}' | jq -r .error.code
reset_limiter
```
**Harus:** `RATE_LIMITED`.

### 2.13 Batas ukuran body (opsional)

```bash
python3 -c "print('{\"email\":\"' + 'a'*1100000 + '\"}')" > /tmp/big.json
curl -s -o /dev/null -w "%{http_code}\n" -X POST $B/auth/login -H "$H" --data-binary @/tmp/big.json
```
**Harus:** `413`.

### 2.14 Reset bersih untuk fase berikutnya

```bash
reset_all
api POST /auth/register-owner "" "$REG" | jq -c '.data.user | {email, role}'
```
**Harus:** owner dengan password `rahasia123` kembali ada. Fase B3 dan B4 memakai data ini.

---

## 3. Fase B3 — Master data (outlet, layanan, staff)

```bash
OT=$(tok owner@jesilaundry.com rahasia123)
O1=$(api GET /outlets "$OT" | jq -r '.data[0].id'); echo "O1=$O1"
```

### 3.1 Outlet

```bash
R=$(api POST /outlets "$OT" '{"code":"JL2","name":"Jesi Laundry 2","address":"BSD","phone":"081200000000"}')
jq -c '.data | {code,name,is_active}' <<< "$R"
O2=$(jq -r .data.id <<< "$R"); echo "O2=$O2"
```
**Harus:** `JL2` aktif dibuat.

```bash
st POST /outlets "$OT" '{"code":"JL2","name":"Dobel"}'
api POST /outlets "$OT" '{"code":"JL2","name":"Dobel"}' | jq -r .error.code
st POST /outlets "$OT" '{"code":"jl3","name":"Kecil"}'
st POST /outlets "$OT" '{"code":"TERLALUPANJANG","name":"X"}'
st POST /outlets "$OT" '{"code":"JL3"}'
```
**Harus:** `409 OUTLET_CODE_TAKEN`; `422` (huruf kecil); `422` (terlalu panjang); `422` (nama kosong).

Katalog default ikut terbentuk:

```bash
api GET "/services?outlet_id=$O2" "$OT" | jq -c '.data | length, ([.[].name])'
```
**Harus:** `6` dan daftar nama sesuai katalog default.

```bash
api PATCH /outlets/$O2 "$OT" '{"name":"Jesi Laundry BSD","address":"BSD City"}' | jq -c '.data | {code,name,address}'
```
**Harus:** nama dan alamat berubah, `code` tetap `JL2`.

Kode tidak bisa diubah:

```bash
api PATCH /outlets/$O2 "$OT" '{"code":"XX"}' | jq -c
dbq "select code from outlets order by code;"
```
**Harus:** kode di database tetap `JL` dan `JL2` (field `code` diabaikan atau ditolak, bukan diubah).

### 3.2 Layanan: ubah harga dan aturan immutable

```bash
S1=$(api GET "/services?outlet_id=$O2" "$OT" | jq -r '.data[] | select(.name=="Cuci Setrika") | .id')
api PATCH /services/$S1 "$OT" '{"regular_price":8000,"min_quantity":3}' | jq -c '.data | {regular_price,min_quantity}'
st PATCH /services/$S1 "$OT" '{"pricing_unit":"piece"}'
st PATCH /services/$S1 "$OT" '{"category":"unit"}'
st DELETE /services/$S1 "$OT"
api DELETE /services/$S1 "$OT" | jq -r .error.code
```
**Harus:** harga jadi 8000; ubah `pricing_unit` atau `category` `422`; hapus layanan kiloan `422 SYSTEM_SERVICE_NOT_DELETABLE`.

Uji persistensi nilai nol/false (aturan GORM §5.1.1):

```bash
api PATCH /services/$S1 "$OT" '{"min_quantity":0}' | jq -c '.data.min_quantity'
dbq "select min_quantity from laundry_services where id='$S1';"
api PATCH /services/$S1 "$OT" '{"min_quantity":3}' | jq -c '.data.min_quantity'
api PATCH /services/$S1 "$OT" '{"is_active":false}' | jq -c '.data.is_active'
dbq "select is_active from laundry_services where id='$S1';"
api PATCH /services/$S1 "$OT" '{"is_active":true}' | jq -c '.data.is_active'
```
**Harus:** `0` benar-benar tersimpan di database (bukan diabaikan), lalu kembali `3`; `is_active=false` tersimpan `f`, lalu kembali `true`.

### 3.3 Layanan satuan

```bash
R=$(api POST /services "$OT" "{\"outlet_id\":\"$O2\",\"name\":\"Selimut\",\"pricing_unit\":\"piece\",\"regular_price\":20000,\"express_price\":30000,\"regular_duration_days\":3,\"express_duration_days\":1}")
jq -c '.data | {name,category,pricing_unit,is_system,is_active,sort_order}' <<< "$R"
S3=$(jq -r .data.id <<< "$R")
```
**Harus:** `category: "unit"`, `is_system: false`, `is_active: true`, `sort_order` lebih besar dari layanan lain.

Validasi:

```bash
st POST /services "$OT" "{\"outlet_id\":\"$O2\",\"name\":\"selimut\",\"pricing_unit\":\"piece\",\"regular_price\":1,\"express_price\":1,\"regular_duration_days\":3,\"express_duration_days\":1}"
st POST /services "$OT" "{\"outlet_id\":\"$O2\",\"name\":\"Gorden\",\"pricing_unit\":\"kg\",\"regular_price\":1,\"express_price\":1,\"regular_duration_days\":3,\"express_duration_days\":1}"
st POST /services "$OT" "{\"outlet_id\":\"$O2\",\"name\":\"Gorden\",\"pricing_unit\":\"sqm\",\"regular_price\":-5,\"express_price\":1,\"regular_duration_days\":3,\"express_duration_days\":1}"
st POST /services "$OT" "{\"outlet_id\":\"$O2\",\"name\":\"Gorden\",\"pricing_unit\":\"sqm\",\"regular_price\":1,\"express_price\":1,\"regular_duration_days\":0,\"express_duration_days\":31}"
```
**Harus:** `409` (nama sama beda huruf besar); `422` (unit `kg` untuk satuan); `422` (harga negatif); `422` (durasi di luar 1–30).

Nonaktifkan, daftar, hapus:

```bash
api PATCH /services/$S3 "$OT" '{"is_active":false}' | jq -c '.data.is_active'
api GET "/services?outlet_id=$O2" "$OT" | jq -r '[.data[].name] | index("Selimut")'
api GET "/services?outlet_id=$O2&include_inactive=true" "$OT" | jq -r '[.data[].name] | index("Selimut")'
st DELETE /services/$S3 "$OT"
api GET "/services?outlet_id=$O2&include_inactive=true" "$OT" | jq -r '[.data[].name] | index("Selimut")'
```
**Harus:** `false`; `null` (tidak muncul tanpa `include_inactive`); angka indeks (muncul); `204`; `null` (hilang setelah dihapus).

Nama bisa dipakai lagi setelah soft delete:

```bash
st POST /services "$OT" "{\"outlet_id\":\"$O2\",\"name\":\"Selimut\",\"pricing_unit\":\"piece\",\"regular_price\":20000,\"express_price\":30000,\"regular_duration_days\":3,\"express_duration_days\":1}"
```
**Harus:** `201`.

Owner tanpa `outlet_id` saat ada 2 outlet:

```bash
st GET /services "$OT"
api GET /services "$OT" | jq -c '.error'
st GET "/services?outlet_id=00000000-0000-0000-0000-000000000000" "$OT"
```
**Harus:** `422` dengan error pada `outlet_id`; ID tidak ada `404`.

### 3.4 Staff

```bash
R=$(api POST /users "$OT" "{\"name\":\"Staff Satu\",\"email\":\"staff1@jesilaundry.com\",\"password\":\"staff12345\",\"outlet_id\":\"$O1\"}")
jq -c '.data | {name,email,role,is_active,outlet}' <<< "$R"
U1=$(jq -r .data.id <<< "$R")
R=$(api POST /users "$OT" "{\"name\":\"Staff Dua\",\"email\":\"staff2@jesilaundry.com\",\"password\":\"staff12345\",\"outlet_id\":\"$O2\"}")
U2=$(jq -r .data.id <<< "$R")
```
**Harus:** `role: "staff"`, `outlet` berisi id/kode/nama.

Validasi:

```bash
st POST /users "$OT" "{\"name\":\"X\",\"email\":\"staff1@jesilaundry.com\",\"password\":\"staff12345\",\"outlet_id\":\"$O1\"}"
st POST /users "$OT" "{\"name\":\"X\",\"email\":\"baru@x.com\",\"password\":\"lemah\",\"outlet_id\":\"$O1\"}"
st POST /users "$OT" '{"name":"X","email":"baru@x.com","password":"staff12345","outlet_id":"00000000-0000-0000-0000-000000000000"}'
st POST /users "$OT" '{"name":"X","email":"baru@x.com","password":"staff12345"}'
```
**Harus:** `409` (email dobel); `422`; `404` (outlet tidak ada); `422` (tanpa outlet).

Outlet nonaktif tidak bisa menerima staff:

```bash
O3=$(api POST /outlets "$OT" '{"code":"OFF","name":"Tutup"}' | jq -r .data.id)
api PATCH /outlets/$O3 "$OT" '{"is_active":false}' | jq -c '.data.is_active'
api POST /users "$OT" "{\"name\":\"X\",\"email\":\"baru@x.com\",\"password\":\"staff12345\",\"outlet_id\":\"$O3\"}" | jq -r .error.code
```
**Harus:** `false`, lalu `OUTLET_INACTIVE`.

### 3.5 Staff: hak akses dan scope

```bash
ST1=$(tok staff1@jesilaundry.com staff12345)
ST2=$(tok staff2@jesilaundry.com staff12345)
jq -R 'split(".")[1] | @base64d | fromjson | {role, oid}' <<< "$ST1"
```
**Harus:** `role: staff` dan `oid` = ID outlet 1.

```bash
st POST /outlets "$ST1" '{"code":"XX","name":"x"}'
st GET /users "$ST1"
st POST /users "$ST1" '{}'
st POST /services "$ST1" '{}'
st DELETE /services/$S1 "$ST1"
st PATCH /outlets/$O1 "$ST1" '{"name":"x"}'
```
**Harus:** semua `403`.

```bash
api GET /outlets "$ST1" | jq -c '[.data[].code]'
api GET "/services?outlet_id=$O2&include_inactive=true" "$ST1" | jq -c '[.data[].name]'
api GET "/services?outlet_id=$O2&include_inactive=true" "$ST2" | jq -c '[.data[].name]'
```
**Harus:** staff 1 hanya melihat `["JL"]`; query `outlet_id` outlet lain **diabaikan** (staff 1 melihat layanan outlet JL, bukan JL2); staff 2 melihat layanan aktif JL2 saja (tanpa layanan nonaktif walau `include_inactive=true`).

### 3.6 Manajemen staff: perubahan, pencabutan sesi

Daftar:

```bash
api GET "/users?page=1&limit=1" "$OT" | jq -c '{n:(.data|length), meta}'
api GET "/users?search=satu" "$OT" | jq -c '[.data[].name]'
api GET "/users?outlet_id=$O2" "$OT" | jq -c '[.data[].name]'
```
**Harus:** `n=1` dengan `meta.total = 2`; pencarian menemukan "Staff Satu"; filter outlet menemukan "Staff Dua".

Perubahan nama tidak mencabut sesi; pindah outlet yang sama juga tidak:

```bash
R=$(api POST /auth/login "" '{"email":"staff1@jesilaundry.com","password":"staff12345"}'); SRT=$(jq -r .data.refresh_token <<< "$R")
api PATCH /users/$U1 "$OT" '{"name":"Staff Satu Baru"}' | jq -c '.data.name'
api PATCH /users/$U1 "$OT" "{\"outlet_id\":\"$O1\"}" | jq -c '.data.outlet.code'
st POST /auth/refresh "" "{\"refresh_token\":\"$SRT\"}"
```
**Harus:** nama berubah, outlet tetap `JL`, dan refresh tetap `200`.

Pindah outlet sungguhan mencabut sesi:

```bash
R=$(api POST /auth/login "" '{"email":"staff1@jesilaundry.com","password":"staff12345"}'); SRT=$(jq -r .data.refresh_token <<< "$R")
api PATCH /users/$U1 "$OT" "{\"outlet_id\":\"$O2\"}" | jq -c '.data.outlet.code'
api POST /auth/refresh "" "{\"refresh_token\":\"$SRT\"}" | jq -r .error.code
api PATCH /users/$U1 "$OT" "{\"outlet_id\":\"$O1\"}" | jq -c '.data.outlet.code'
```
**Harus:** `JL2`, lalu `INVALID_REFRESH_TOKEN`, lalu kembali `JL`.

Nonaktifkan staff:

```bash
R=$(api POST /auth/login "" '{"email":"staff1@jesilaundry.com","password":"staff12345"}'); SRT=$(jq -r .data.refresh_token <<< "$R"); ST1=$(jq -r .data.access_token <<< "$R")
api PATCH /users/$U1 "$OT" '{"is_active":false}' | jq -c '.data.is_active'
api POST /auth/refresh "" "{\"refresh_token\":\"$SRT\"}" | jq -r .error.code
api POST /auth/login "" '{"email":"staff1@jesilaundry.com","password":"staff12345"}' | jq -r .error.code
st POST /auth/login "" '{"email":"staff1@jesilaundry.com","password":"staff12345"}'
api GET /me "$ST1" | jq -r .error.code
```
**Harus:** `false`; `INVALID_REFRESH_TOKEN`; `ACCOUNT_INACTIVE` dengan status `403`; dan access token lama (masih berlaku) pada `/me` menghasilkan `ACCOUNT_INACTIVE`.

Aktifkan kembali dan reset password oleh owner:

```bash
api PATCH /users/$U1 "$OT" '{"is_active":true}' | jq -c '.data.is_active'
st POST /auth/login "" '{"email":"staff1@jesilaundry.com","password":"staff12345"}'
R=$(api POST /auth/login "" '{"email":"staff1@jesilaundry.com","password":"staff12345"}'); SRT=$(jq -r .data.refresh_token <<< "$R")
st POST /users/$U1/reset-password "$OT" '{"new_password":"baru123456"}'
st POST /auth/refresh "" "{\"refresh_token\":\"$SRT\"}"
st POST /auth/login "" '{"email":"staff1@jesilaundry.com","password":"staff12345"}'
st POST /auth/login "" '{"email":"staff1@jesilaundry.com","password":"baru123456"}'
```
**Harus:** `true`; `200`; `204`; `401` (refresh dicabut); `401` (password lama); `200` (password baru).

Owner tidak bisa dikelola lewat `/users`:

```bash
OWNER_ID=$(api GET /me "$OT" | jq -r .data.id)
st PATCH /users/$OWNER_ID "$OT" '{"is_active":false}'
st GET /users/$OWNER_ID "$OT"
```
**Harus:** keduanya `404`. Pastikan owner masih aktif: `api GET /me "$OT" | jq -r .data.is_active` → `true`.

Kembalikan password staff 1 untuk fase berikutnya:

```bash
st POST /users/$U1/reset-password "$OT" '{"new_password":"staff12345"}'
```

---

## 4. Fase B4a — Pelanggan dan pembuatan order

Lanjut dari data B3. Siapkan variabel:

```bash
OT=$(tok owner@jesilaundry.com rahasia123)
ST1=$(tok staff1@jesilaundry.com staff12345)
ST2=$(tok staff2@jesilaundry.com staff12345)
O1=$(api GET /outlets "$OT" | jq -r '.data[] | select(.code=="JL") | .id')
O2=$(api GET /outlets "$OT" | jq -r '.data[] | select(.code=="JL2") | .id')
svc() { api GET "/services?outlet_id=$1" "$OT" | jq -r ".data[] | select(.name==\"$2\") | .id"; }
S_CS=$(svc $O1 "Cuci Setrika"); S_IR=$(svc $O1 Setrika); S_CL=$(svc $O1 "Cuci Lipat")
S_BC=$(svc $O1 "Bed Cover"); S_BN=$(svc $O1 Boneka); S_KP=$(svc $O1 Karpet)
S2_CS=$(svc $O2 "Cuci Setrika")
```

Harga default outlet JL (dipakai untuk menghitung hasil yang benar): Cuci Setrika 7000/12000, Setrika 5000/8000, Cuci Lipat 5000/8000, Bed Cover 25000/35000, Boneka 15000/25000, Karpet 15000/25000 (reguler/express). Minimum 3 kg untuk tiga layanan kiloan.

### 4.1 Order campuran

```bash
BODY=$(cat <<EOF
{"outlet_id":"$O1","customer":{"name":"Budi","phone":"0812-3456-7890"},"speed":"regular","notes":"Kemeja jangan dilipat",
 "items":[{"service_id":"$S_CS","quantity":2.5},
          {"service_id":"$S_BC","quantity":1},
          {"service_id":"$S_KP","length_m":2,"width_m":2.5}]}
EOF
)
R=$(api POST /orders "$OT" "$BODY")
jq '.data | {order_number,total_amount,speed,status,payment_status,estimated_done_at,created_at,customer,items:[.items[]|{service_name,quantity,billed_quantity,unit_price,subtotal,duration_days}]}' <<< "$R"
```
**Harus:**
- `order_number` seperti `JL-261027-0001` (tanggal hari ini WIB).
- Cuci Setrika: `quantity 2.5`, `billed_quantity 3`, `subtotal 21000`.
- Bed Cover: `subtotal 25000`.
- Karpet: `quantity 5`, `billed_quantity 5`, `subtotal 75000`.
- `total_amount 121000`, `status received`, `payment_status unpaid`.
- `estimated_done_at` = `created_at` + 3 hari (72 jam).
- `customer.phone` = `6281234567890`.

Jenis data JSON:

```bash
jq '.data.items[0] | {q:(.quantity|type), bq:(.billed_quantity|type), up:(.unit_price|type), sub:(.subtotal|type)}' <<< "$R"
jq '.data | (.total_amount|type)' <<< "$R"
```
**Harus:** semuanya `"number"` (bukan string).

Periksa snapshot di database:

```bash
dbq "select service_name, category, pricing_unit, quantity, length_m, width_m, billed_quantity, unit_price, subtotal, duration_days from order_items order by created_at;"
```

### 4.2 Pembulatan dan minimum

```bash
mk() { echo "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"Uji\"},\"speed\":\"$2\",\"items\":$1}"; }
api POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_CS\",\"quantity\":1}]" regular)" | jq -c '.data.items[0] | {billed_quantity,subtotal}'
api POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_CS\",\"quantity\":3.33}]" regular)" | jq -c '.data.items[0] | {billed_quantity,subtotal}'
api POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_CS\",\"quantity\":10}]" regular)" | jq -c '.data.items[0] | {billed_quantity,subtotal}'
api POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_CS\",\"quantity\":0.01}]" regular)" | jq -c '.data.items[0] | {billed_quantity,subtotal}'
```
**Harus:** 1 kg → billed `3`, subtotal `21000`; 3,33 kg → billed `3.33`, subtotal `23310`; 10 kg → `70000`; 0,01 kg → billed `3`, subtotal `21000`.

### 4.3 Express

```bash
R=$(api POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_CS\",\"quantity\":3},{\"service_id\":\"$S_BC\",\"quantity\":2}]" express)")
jq -c '.data | {total_amount,created_at,estimated_done_at,items:[.items[]|{unit_price,duration_days}]}' <<< "$R"
```
**Harus:** harga express terpakai (12000 dan 35000), total `36000 + 70000 = 106000`, `duration_days` 1, dan `estimated_done_at` = `created_at` + 1 hari.

### 4.4 Validasi item

Masing-masing harus `422` kecuali disebut lain:

```bash
st POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_CS\",\"quantity\":1000}]" regular)"
st POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_CS\",\"quantity\":0}]" regular)"
st POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_CS\",\"quantity\":-1}]" regular)"
st POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_CS\",\"quantity\":2.555}]" regular)"
st POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_BC\",\"quantity\":1.5}]" regular)"
st POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_BC\",\"quantity\":1000}]" regular)"
st POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_KP\",\"length_m\":0,\"width_m\":2}]" regular)"
st POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_KP\",\"length_m\":0.01,\"width_m\":0.01}]" regular)"
st POST /orders "$OT" "$(mk "[]" regular)"
st POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_CS\",\"quantity\":1}]" kilat)"
st POST /orders "$OT" "$(mk "[{\"service_id\":\"bukan-uuid\",\"quantity\":1}]" regular)"
```

Order dengan 51 item harus `422`:

```bash
ITEMS=$(python3 -c "import json;print(json.dumps([{'service_id':'$S_BC','quantity':1}]*51))")
st POST /orders "$OT" "$(mk "$ITEMS" regular)"
```

Kiloan dobel ditolak, satuan dobel diterima:

```bash
api POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_CS\",\"quantity\":1},{\"service_id\":\"$S_CS\",\"quantity\":2}]" regular)" | jq -r .error.code
st POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_KP\",\"length_m\":2,\"width_m\":2.5},{\"service_id\":\"$S_KP\",\"length_m\":1,\"width_m\":1}]" regular)"
```
**Harus:** `DUPLICATE_KILO_SERVICE`; lalu `201` (dua karpet beda ukuran).

### 4.5 Layanan dan outlet tidak sah

```bash
api PATCH /services/$S_BN "$OT" '{"is_active":false}' >/dev/null
api POST /orders "$OT" "$(mk "[{\"service_id\":\"$S_BN\",\"quantity\":1}]" regular)" | jq -r .error.code
api PATCH /services/$S_BN "$OT" '{"is_active":true}' >/dev/null
api POST /orders "$OT" "$(mk "[{\"service_id\":\"$S2_CS\",\"quantity\":1}]" regular)" | jq -r .error.code
api POST /orders "$OT" "{\"customer\":{\"name\":\"X\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":1}]}" | jq -c '.error'
api POST /orders "$OT" "{\"outlet_id\":\"$O3\",\"customer\":{\"name\":\"X\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":1}]}" | jq -r .error.code
```
**Harus:** `SERVICE_INACTIVE` (layanan nonaktif); `SERVICE_INACTIVE` (layanan milik outlet lain); `VALIDATION_ERROR` pada `outlet_id` (owner tanpa outlet); `OUTLET_INACTIVE` (outlet OFF dari uji B3 — jika variabel `O3` belum ada, abaikan baris terakhir).

### 4.6 Staff

```bash
SBODY="{\"outlet_id\":\"$O2\",\"customer\":{\"name\":\"Sari\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":3}]}"
api POST /orders "$ST1" "$SBODY" | jq -c '.data | {order_number, outlet:.outlet.code, total_amount, created_by:.created_by.name}'
```
**Harus:** `outlet_id` di body **diabaikan**; order masuk ke outlet staff 1 (`JL`), harga tetap terlihat, `created_by` berisi nama staff.

Staff memakai layanan outlet lain:

```bash
api POST /orders "$ST1" "{\"customer\":{\"name\":\"Sari\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S2_CS\",\"quantity\":3}]}" | jq -r .error.code
```
**Harus:** `SERVICE_INACTIVE`.

### 4.7 Pelanggan

```bash
dbq "select name, phone, last_order_at is not null as ada_last from customers order by created_at;"
```
**Harus:** pelanggan "Budi" hanya muncul **sekali** walaupun ada beberapa order dengan nama dan HP sama. Cek:

```bash
api POST /orders "$OT" "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"BUDI\",\"phone\":\"+62 812 3456 7890\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_BC\",\"quantity\":1}]}" | jq -c '.data.customer'
dbq "select count(*) from customers where lower(name)='budi';"
api POST /orders "$OT" "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"Budi\",\"phone\":\"081111111111\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_BC\",\"quantity\":1}]}" | jq -c '.data.customer'
dbq "select count(*) from customers where lower(name)='budi';"
```
**Harus:** pelanggan yang sama (id sama) untuk "BUDI" dengan HP `+62 812 ...` yang dinormalisasi; count tetap `1`. Dengan HP berbeda dibuat pelanggan baru, count menjadi `2`.

Pakai `customer.id`:

```bash
CUST=$(dbq "select id from customers where lower(name)='budi' limit 1;" | sed -n '3p' | tr -d ' ')
api POST /orders "$OT" "{\"outlet_id\":\"$O1\",\"customer\":{\"id\":\"$CUST\"},\"speed\":\"express\",\"payment_status\":\"paid\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}" | jq -c '.data | {payment_status,paid_at,customer:.customer.name}'
api POST /orders "$OT" "{\"outlet_id\":\"$O1\",\"customer\":{\"id\":\"00000000-0000-0000-0000-000000000000\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}" | jq -r .error.code
st POST /orders "$OT" "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"Z\",\"phone\":\"abc\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}"
st POST /orders "$OT" "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}"
```
**Harus:** order langsung `paid` dengan `paid_at` terisi; `NOT_FOUND`; `422`; `422`.

Jika `CUST` kosong (format keluaran psql berbeda), ambil ID dari respons order sebelumnya (`.data.customer.id`).

Autocomplete pelanggan:

```bash
api GET "/customers?search=bud" "$ST1" | jq -c '[.data[] | {name,phone}]'
api GET "/customers?search=0812" "$ST1" | jq -c '[.data[] | .phone]'
api GET "/customers?search=%25" "$ST1" | jq -c '.data | length'
api GET "/customers?limit=1" "$ST1" | jq -c '.data | length'
api GET /customers/$CUST "$ST1" | jq -c '.data | {name,phone}'
```
**Harus:** pelanggan "Budi" ditemukan; pencarian `0812` menemukan nomor `62812...`; `%` diperlakukan literal (`0`); limit bekerja; detail bisa dilihat staff.

Edit pelanggan oleh owner saja, dan nota lama tidak berubah:

```bash
st PATCH /customers/$CUST "$ST1" '{"name":"Hacker"}'
api PATCH /customers/$CUST "$OT" '{"name":"Budi Santoso"}' | jq -c '.data.name'
api PATCH /customers/$CUST "$OT" '{"phone":""}' | jq -c '.data.phone'
st PATCH /customers/$CUST "$OT" '{"phone":"abc"}'
ORD1=$(api GET "/orders?search=budi&limit=1" "$OT" | jq -r '.data[0].id')
api GET /orders/$ORD1 "$OT" | jq -c '.data.customer'
```
**Harus:** `403`; nama berubah; `phone` jadi `null`; `422`; nota lama tetap memakai nama snapshot lama ("Budi"/"BUDI"), bukan "Budi Santoso".

### 4.8 Nomor order

```bash
BODY1="{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"Paralel\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_BC\",\"quantity\":1}]}"
( for i in {1..10}; do api POST /orders "$OT" "$BODY1" | jq -r .data.order_number & done; wait ) | sort
dbq "select * from order_counters;"
dbq "select count(*) from orders where outlet_id='$O1' and created_at::date = (now() at time zone 'Asia/Jakarta')::date;"
```
**Harus:** 10 nomor **berurutan dan unik** (tidak ada yang kembar atau hilang), `last_number` di `order_counters` sama dengan jumlah order outlet JL hari ini, dan outlet JL2 punya counter terpisah dimulai dari `0001`.

### 4.9 Daftar order

```bash
api GET "/orders?page=1&limit=5" "$OT" | jq -c '{n:(.data|length), meta, first:.data[0].order_number}'
api GET "/orders?status=received,processing" "$OT" | jq -c '.meta.total'
api GET "/orders?payment_status=paid" "$OT" | jq -c '[.data[].payment_status] | unique'
api GET "/orders?search=budi" "$OT" | jq -c '[.data[].customer_name] | unique'
api GET "/orders?search=JL-2610" "$OT" | jq -c '.meta.total'
api GET "/orders?search=%25" "$OT" | jq -c '.meta.total'
api GET "/orders?outlet_id=$O2" "$OT" | jq -c '.meta.total'
api GET "/orders" "$ST1" | jq -c '[.data[].outlet.code] | unique'
api GET "/orders?outlet_id=$O2" "$ST1" | jq -c '[.data[].outlet.code] | unique'
```
**Harus:** halaman berisi 5 item dan `meta.total` benar; urutan terbaru dulu; filter status/pembayaran bekerja; pencarian nomor dan nama bekerja; `%` literal (`0`); staff hanya melihat outlet sendiri walau mengirim `outlet_id` lain.

`items_count` benar:

```bash
api GET "/orders?search=Uji&limit=3" "$OT" | jq -c '[.data[] | {order_number, items_count}]'
```
Bandingkan dengan `dbq "select o.order_number, count(i.id) from orders o join order_items i on i.order_id=o.id group by 1 order by 1 desc limit 3;"`.

Filter tanggal (inklusif, zona WIB). Geser satu order ke kemarin:

```bash
OID=$(api GET "/orders?limit=1" "$OT" | jq -r '.data[0].id')
dbq "update orders set created_at = (date_trunc('day', now() at time zone 'Asia/Jakarta') - interval '1 minute') at time zone 'Asia/Jakarta' where id='$OID';"
Y=$(date -v-1d +%F); T=$(date +%F)
api GET "/orders?date_from=$Y&date_to=$Y" "$OT" | jq -c '[.data[].id] | index("'$OID'")'
api GET "/orders?date_from=$T&date_to=$T" "$OT" | jq -c '[.data[].id] | index("'$OID'")'
api GET "/orders?date_to=$T" "$OT" | jq -c '[.data[].id] | index("'$OID'")'
st GET "/orders?date_from=bukan-tanggal" "$OT"
```
**Harus:** order itu (23:59 WIB kemarin) muncul pada rentang kemarin (angka indeks), tidak muncul pada rentang hari ini (`null`), muncul pada `date_to` hari ini; tanggal tidak valid `422`.

### 4.10 Detail dan scope

```bash
st GET /orders/$ORD1 "$OT"
st GET /orders/00000000-0000-0000-0000-000000000000 "$OT"
st GET /orders/bukan-uuid "$OT"
ORD_JL1=$ORD1
st GET /orders/$ORD_JL1 "$ST1"
st GET /orders/$ORD_JL1 "$ST2"
```
**Harus:** `200`; `404`; `400` atau `422`; staff outlet sendiri `200`; staff outlet lain `404` (bukan `403`).

---

## 5. Fase B4b — Status, pembayaran, edit, hapus

Siapkan order baru:

```bash
newo() { api POST /orders "$OT" "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"Tes Status\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}" | jq -r .data.id; }
ORD=$(newo)
ts() { api GET /orders/$1 "$OT" | jq -c '.data | {status,payment_status,processing_at,done_at,picked_up_at,paid_at}'; }
ts $ORD
```
**Harus:** `received`, `unpaid`, semua timestamp `null`.

### 5.1 Alur status oleh staff

```bash
api PATCH /orders/$ORD/status "$ST1" '{"status":"processing"}' | jq -c '.data | {status,processing_at}'
api PATCH /orders/$ORD/status "$ST1" '{"status":"done"}' | jq -c '.data | {status,done_at}'
api PATCH /orders/$ORD/status "$ST1" '{"status":"done"}' | jq -r .error.code
api PATCH /orders/$ORD/status "$ST1" '{"status":"picked_up"}' | jq -r .error.code
api PATCH /orders/$ORD/status "$ST1" '{"status":"received"}' | jq -r .error.code
st PATCH /orders/$ORD/status "$ST1" '{"status":"received"}'
st PATCH /orders/$ORD/status "$ST1" '{"status":"ngawur"}'
```
**Harus:** `processing` dengan `processing_at` terisi; `done` dengan `done_at` terisi; `INVALID_STATUS_TRANSITION`; `PAYMENT_REQUIRED`; `FORBIDDEN` (staff mundur) dengan status `403`; `422` untuk status tidak dikenal.

### 5.2 Melompat tahap

```bash
O_J=$(newo)
api PATCH /orders/$O_J/status "$ST1" '{"status":"done"}' | jq -c '.data | {status,processing_at,done_at}'
```
**Harus:** `processing_at` **dan** `done_at` sama-sama terisi.

### 5.3 Pembayaran

```bash
api PATCH /orders/$ORD/payment "$ST1" '{"payment_status":"paid"}' | jq -c '.data | {payment_status,paid_at}'
api PATCH /orders/$ORD/payment "$ST1" '{"payment_status":"paid"}' | jq -r .error.code
api PATCH /orders/$ORD/payment "$ST1" '{"payment_status":"unpaid"}' | jq -r .error.code
api PATCH /orders/$ORD/status "$ST1" '{"status":"picked_up"}' | jq -c '.data | {status,picked_up_at}'
api PATCH /orders/$ORD/payment "$OT" '{"payment_status":"unpaid"}' | jq -r .error.code
```
**Harus:** `paid` dengan `paid_at` terisi; `INVALID_STATUS_TRANSITION` (nilai sama); `FORBIDDEN` (staff batalkan lunas); `picked_up` berhasil; owner batalkan lunas pada order `picked_up` → `ORDER_NOT_EDITABLE`.

### 5.4 Koreksi mundur oleh owner

```bash
api PATCH /orders/$ORD/status "$OT" '{"status":"processing"}' | jq -c '.data | {status,processing_at,done_at,picked_up_at,paid_at}'
api PATCH /orders/$ORD/payment "$OT" '{"payment_status":"unpaid"}' | jq -c '.data | {payment_status,paid_at}'
api PATCH /orders/$ORD/status "$OT" '{"status":"received"}' | jq -c '.data | {status,processing_at,done_at,picked_up_at}'
```
**Harus:** mundur ke `processing` → `processing_at` **tetap terisi**, `done_at` dan `picked_up_at` kosong, `paid_at` tidak ikut berubah; batalkan lunas → `paid_at` kosong; mundur ke `received` → semua timestamp kosong.

### 5.5 Scope dan tidak ditemukan

```bash
st PATCH /orders/$ORD/status "$ST2" '{"status":"processing"}'
st PATCH /orders/00000000-0000-0000-0000-000000000000/status "$OT" '{"status":"processing"}'
```
**Harus:** `404` untuk keduanya.

### 5.6 Request paralel pada order yang sama

```bash
ORD2=$(newo)
for i in 1 2; do st PATCH /orders/$ORD2/status "$OT" '{"status":"processing"}' & done; wait
ts $ORD2
```
**Harus:** satu `200` dan satu `422` (`INVALID_STATUS_TRANSITION`), dan `processing_at` hanya satu nilai.

Sepuluh request paralel:

```bash
ORD3=$(newo)
( for i in {1..10}; do st PATCH /orders/$ORD3/payment "$OT" '{"payment_status":"paid"}' & done; wait ) | sort | uniq -c
```
**Harus:** tepat satu `200`, sembilan `422`.

### 5.7 Edit order (owner)

Order dasar:

```bash
EDIT=$(api POST /orders "$OT" "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"Edit Aku\"},\"speed\":\"regular\",\"notes\":\"catatan lama\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}")
EID=$(jq -r .data.id <<< "$EDIT"); jq -c '.data | {total_amount,created_at,estimated_done_at}' <<< "$EDIT"
dbq "select last_order_at from customers where name='Edit Aku';"
```

Ganti item dan speed:

```bash
api PUT /orders/$EID "$OT" "{\"customer\":{\"name\":\"Edit Aku\"},\"speed\":\"express\",\"notes\":\"\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":5},{\"service_id\":\"$S_BC\",\"quantity\":1}]}" | jq -c '.data | {total_amount,status,notes,created_at,estimated_done_at,n_items:(.items|length)}'
dbq "select count(*) from order_items where order_id='$EID';"
dbq "select last_order_at from customers where name='Edit Aku';"
```
**Harus:** total `5×12000 + 35000 = 95000`; `created_at` **tidak berubah**; `estimated_done_at` = `created_at` + 1 hari; `status` tidak berubah; `notes` jadi `null`; 2 item (item lama terhapus, bukan menumpuk: count database `2`); `last_order_at` pelanggan tidak berubah.

Harga katalog baru dipakai:

```bash
api PATCH /services/$S_CS "$OT" '{"regular_price":9000}' >/dev/null
api PUT /orders/$EID "$OT" "{\"customer\":{\"name\":\"Edit Aku\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}" | jq -c '.data | {total_amount, up:.items[0].unit_price}'
api PATCH /services/$S_CS "$OT" '{"regular_price":7000}' >/dev/null
```
**Harus:** `unit_price 9000`, total `36000`.

Ganti pelanggan lewat edit:

```bash
api PUT /orders/$EID "$OT" "{\"customer\":{\"name\":\"Pelanggan Pengganti\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}" | jq -c '.data.customer'
```
**Harus:** pelanggan baru tersimpan.

Larangan:

```bash
st PUT /orders/$EID "$ST1" "{\"customer\":{\"name\":\"X\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}"
api PATCH /orders/$EID/payment "$OT" '{"payment_status":"paid"}' >/dev/null
api PUT /orders/$EID "$OT" "{\"customer\":{\"name\":\"X\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}" | jq -r .error.code
api PATCH /orders/$EID/payment "$OT" '{"payment_status":"unpaid"}' >/dev/null
api PATCH /orders/$EID/status "$OT" '{"status":"processing"}' >/dev/null
st PUT /orders/$EID "$OT" "{\"customer\":{\"name\":\"X\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}"
```
**Harus:** staff `403`; order sudah Lunas → `ORDER_NOT_EDITABLE`; order belum lunas dan status `processing` masih bisa diedit (`200`). Order `picked_up` juga `ORDER_NOT_EDITABLE`.

### 5.8 Hapus (soft delete)

```bash
DEL=$(newo)
st DELETE /orders/$DEL "$ST1"
st DELETE /orders/$DEL "$OT"
st GET /orders/$DEL "$OT"
api GET "/orders?search=Tes Status&limit=100" "$OT" | jq -c '[.data[].id] | index("'$DEL'")'
dbq "select deleted_at is not null as terhapus, deleted_by_id is not null as ada_penghapus from orders where id='$DEL';"
dbq "select count(*) from order_items where order_id='$DEL';"
st DELETE /orders/$DEL "$OT"
```
**Harus:** staff `403`; owner `204`; detail `404`; tidak ada di list (`null`); di database baris tetap ada dengan `terhapus = t`, `ada_penghapus = t`; item order **tetap ada** (soft delete tidak menghapus item); hapus kedua kali `404`.

Nomor order tidak dipakai ulang:

```bash
api POST /orders "$OT" "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"Setelah Hapus\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_BC\",\"quantity\":1}]}" | jq -r .data.order_number
dbq "select order_number from orders where id='$DEL';"
```
**Harus:** nomor baru lebih besar dari nomor order yang dihapus.

### 5.9 Uji pool koneksi (tidak boleh macet)

Ini menguji perbaikan deadlock pool pada `PUT /orders/:id`.

```bash
sed -i '' 's/^DB_MAX_OPEN_CONNS=.*/DB_MAX_OPEN_CONNS=2/' .env
docker compose up -d --no-deps --force-recreate api
until curl -sf localhost:8080/health >/dev/null; do sleep 1; done
OT=$(tok owner@jesilaundry.com rahasia123)
PBODY="{\"customer\":{\"name\":\"Edit Aku\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":4}]}"
time ( for i in {1..6}; do st PUT /orders/$EID "$OT" "$PBODY" & done; wait )
```
**Harus:** semua request selesai dalam beberapa detik (hasil campuran `200`, dan mungkin `422`). Jika menggantung lebih dari 15 detik, masih ada query di luar transaksi. Kembalikan:

```bash
sed -i '' 's/^DB_MAX_OPEN_CONNS=.*/DB_MAX_OPEN_CONNS=10/' .env
docker compose up -d --no-deps --force-recreate api
until curl -sf localhost:8080/health >/dev/null; do sleep 1; done
```

---

## 6. Fase B5 — Dashboard

Mulai dari data bersih dan terkontrol.

```bash
reset_all
export REG='{"name":"Jesi","email":"owner@jesilaundry.com","password":"rahasia123","outlet_name":"Jesi Laundry","outlet_code":"JL","outlet_address":"Serpong","outlet_phone":"081234567890"}'
api POST /auth/register-owner "" "$REG" >/dev/null
OT=$(tok owner@jesilaundry.com rahasia123)
O1=$(api GET /outlets "$OT" | jq -r '.data[0].id')
api POST /users "$OT" "{\"name\":\"Staff\",\"email\":\"staff1@jesilaundry.com\",\"password\":\"staff12345\",\"outlet_id\":\"$O1\"}" >/dev/null
ST1=$(tok staff1@jesilaundry.com staff12345)
svc() { api GET "/services?outlet_id=$1" "$OT" | jq -r ".data[] | select(.name==\"$2\") | .id"; }
S_CS=$(svc $O1 "Cuci Setrika"); S_IR=$(svc $O1 Setrika); S_CL=$(svc $O1 "Cuci Lipat"); S_BC=$(svc $O1 "Bed Cover"); S_KP=$(svc $O1 Karpet)
```

### 6.1 Dataset terkontrol

Empat order (satu akan dihapus):

| Order | Isi | Kecepatan | Tindakan | Total |
|---|---|---|---|---|
| A | Cuci Setrika 2,5 kg | reguler | dibiarkan `received`, belum lunas | 21.000 |
| B | Bed Cover 1 pcs + Karpet 2×2,5 m | express | lunas, status `picked_up` | 35.000 + 125.000 = 160.000 |
| C | Cuci Lipat 4 kg | reguler | **dihapus** | 20.000 |
| D | Setrika 3 kg | express | belum lunas, status `done` | 24.000 |

```bash
new() { api POST /orders "$OT" "$1" | jq -r .data.id; }
A=$(new "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"A\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CS\",\"quantity\":2.5}]}")
B_=$(new "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"B\"},\"speed\":\"express\",\"payment_status\":\"paid\",\"items\":[{\"service_id\":\"$S_BC\",\"quantity\":1},{\"service_id\":\"$S_KP\",\"length_m\":2,\"width_m\":2.5}]}")
C=$(new "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"C\"},\"speed\":\"regular\",\"items\":[{\"service_id\":\"$S_CL\",\"quantity\":4}]}")
D=$(new "{\"outlet_id\":\"$O1\",\"customer\":{\"name\":\"D\"},\"speed\":\"express\",\"items\":[{\"service_id\":\"$S_IR\",\"quantity\":3}]}")
api PATCH /orders/$B_/status "$OT" '{"status":"picked_up"}' >/dev/null
api PATCH /orders/$D/status "$OT" '{"status":"done"}' >/dev/null
api DELETE /orders/$C "$OT" >/dev/null
```

### 6.2 Verifikasi angka (range 24h)

```bash
api GET "/dashboard?range=24h" "$OT" | jq '.data | {range,bucket,totals,by_category,by_speed,by_status,operational}'
```

**Harus persis:**

| Bagian | Nilai |
|---|---|
| `totals.orders` | `3` (order C yang dihapus tidak dihitung) |
| `totals.weight_kg` | `5.5` (2,5 berat **aktual** + 3; bukan `6`) |
| `totals.unit_pieces` | `1` |
| `totals.area_sqm` | `5` |
| `totals.revenue` | `205000` |
| `totals.revenue_paid` / `revenue_unpaid` | `160000` / `45000` |
| `by_category` | 4 elemen: `wash_iron` (1 order, 2.5, 21000), `iron_only` (1, 3, 24000), `wash_fold` (**0**, 0, 0), `unit` (1, 6, 160000) |
| `by_speed` | 2 elemen: `regular` (1 order, 21000), `express` (2 order, 184000) |
| `by_status` | 4 elemen: `received 1`, `processing 0`, `done 1`, `picked_up 1` |
| `operational` | `in_progress 1`, `ready_for_pickup 1`, `unpaid_orders 2`, `unpaid_amount 45000` |

```bash
api GET "/dashboard?range=24h" "$OT" | jq '.data.by_unit_service'
api GET "/dashboard?range=24h" "$OT" | jq '.data | {orders_type:(.totals.orders|type), kg_type:(.totals.weight_kg|type), rev_type:(.totals.revenue|type)}'
```
**Harus:** `by_unit_service` berisi Bed Cover (`piece`, qty 1, rev 35000) dan Karpet (`sqm`, qty 5, rev 125000); semua nilai bertipe `"number"`.

Cocokkan dengan SQL (hasil harus sama dengan JSON di atas):

```bash
dbq "select count(*) as orders, sum(total_amount) as revenue from orders where deleted_at is null and created_at >= now() - interval '24 hours';"
dbq "select category, count(distinct order_id) as orders, sum(quantity) as qty, sum(subtotal) as rev from order_items i join orders o on o.id=i.order_id where o.deleted_at is null and o.created_at >= now() - interval '24 hours' group by category order by 1;"
```

### 6.3 Series dan jumlah titik tiap range

```bash
for r in 1h 24h 7d 30d 1y all; do api GET "/dashboard?range=$r" "$OT" | jq -c '.data | {range,bucket,points:(.series|length),total_orders:([.series[].orders]|add),first:.series[0].bucket_start}'; done
```
**Harus:**

| range | bucket | points |
|---|---|---|
| `1h` | `5m` | 12–13 |
| `24h` | `hour` | 24–25 |
| `7d` | `day` | 7–8 |
| `30d` | `day` | 30–31 |
| `1y` | `month` | 12–13 |
| `all` | `month` | 1 (semua order di bulan ini) |

`total_orders` (jumlah `orders` di semua titik series) harus `3` untuk semua range, dan `bucket_start` berakhiran `+07:00`. Bucket kosong harus bernilai 0, bukan hilang.

Range tidak valid:

```bash
api GET "/dashboard?range=2h" "$OT" | jq -c '.error'
st GET "/dashboard?range=" "$OT"
```
**Harus:** `422` dengan `details` berisi daftar nilai valid (termasuk `all`); range kosong memakai default `24h` (`200`).

### 6.4 Menggeser waktu order (uji rentang)

Geser tiap order lewat SQL, lalu ulangi pengecekan. `jum()` mencetak jumlah order per range:

```bash
jum() { for r in 1h 24h 7d 30d 1y all; do printf "%s=%s " $r $(api GET "/dashboard?range=$r" "$OT" | jq '.data.totals.orders'); done; echo; }
jum
dbq "update orders set created_at = now() - interval '2 hours' where id='$A';"
jum
dbq "update orders set created_at = now() - interval '3 days' where id='$D';"
jum
dbq "update orders set created_at = now() - interval '40 days' where id='$B_';"
jum
```
**Harus (berurutan):**

| Setelah | 1h | 24h | 7d | 30d | 1y | all |
|---|---|---|---|---|---|---|
| awal | 3 | 3 | 3 | 3 | 3 | 3 |
| A digeser 2 jam | 2 | 3 | 3 | 3 | 3 | 3 |
| D digeser 3 hari | 1 | 2 | 3 | 3 | 3 | 3 |
| B digeser 40 hari | 0 | 1 | 2 | 2 | 3 | 3 |

`operational` **tidak boleh berubah** walau order digeser (selalu kondisi saat ini).

```bash
api GET "/dashboard?range=1h" "$OT" | jq -c '.data.operational'
```
**Harus:** sama dengan §6.2 (`in_progress 1`, `ready_for_pickup 1`, `unpaid_orders 2`, `unpaid_amount 45000`).

### 6.5 Zona waktu bucket (WIB, bukan UTC)

Letakkan order A pukul **00:30 WIB hari ini** (kalau Anda menguji antara 00:00–00:30 WIB, tunggu atau gunakan 00:05):

```bash
dbq "update orders set created_at = ((date_trunc('day', now() at time zone 'Asia/Jakarta') + interval '30 minutes') at time zone 'Asia/Jakarta') where id='$A';"
dbq "select created_at, created_at at time zone 'Asia/Jakarta' as wib, created_at at time zone 'UTC' as utc from orders where id='$A';"
api GET "/dashboard?range=7d" "$OT" | jq -c '.data.series[] | select(.orders>0) | {bucket_start,orders}'
```
**Harus:** `utc` menunjukkan tanggal **kemarin**, tetapi bucket yang berisi order itu adalah **hari ini** (`bucket_start` hari ini `T00:00:00+07:00`). Jika masuk bucket kemarin, pengelompokan memakai UTC (bug).

> Koreksi dari pesan saya sebelumnya: contoh jam 23:30 WIB **tidak** membedakan WIB dari UTC (23:30 WIB masih tanggal yang sama di UTC). Jam 00:30 WIB inilah yang benar.

### 6.6 Bucket `all`

```bash
dbq "update orders set created_at = now() - interval '18 months' where id='$B_';"
api GET "/dashboard?range=all" "$OT" | jq -c '.data | {bucket, points:(.series|length), from}'
dbq "update orders set created_at = now() - interval '3 years' where id='$B_';"
api GET "/dashboard?range=all" "$OT" | jq -c '.data | {bucket, points:(.series|length), first:.series[0].bucket_start}'
```
**Harus:** 18 bulan → `bucket "month"`, sekitar 19 titik; 3 tahun → `bucket "year"`, 4 titik, `bucket_start` berbentuk `YYYY-01-01T00:00:00+07:00`. Order paling lama menjadi `from`.

Order yang dihapus tidak boleh mempengaruhi `from`:

```bash
dbq "update orders set created_at = now() - interval '10 years' where id='$C';"
api GET "/dashboard?range=all" "$OT" | jq -c '.data | {bucket, points:(.series|length)}'
```
**Harus:** tidak berubah dari hasil 3 tahun (order C sudah terhapus).

Tanpa order (outlet kosong):

```bash
O2=$(api POST /outlets "$OT" '{"code":"KSG","name":"Kosong"}' | jq -r .data.id)
api GET "/dashboard?range=all&outlet_id=$O2" "$OT" | jq -c '.data | {bucket, points:(.series|length), orders:.totals.orders, from, to}'
```
**Harus:** `month`, 1 titik, 0 order, `from` = `to`.

### 6.7 Staff tidak melihat pendapatan

```bash
api GET "/dashboard?range=all" "$ST1" > /tmp/staff.json
grep -c revenue /tmp/staff.json
grep -c unpaid_amount /tmp/staff.json
jq '.data | keys' /tmp/staff.json
jq '.data.totals | keys' /tmp/staff.json
```
**Harus:** `0` dan `0` (tidak ada satu pun field pendapatan di JSON, bukan sekadar bernilai 0). Field non-uang (`orders`, `weight_kg`, `by_status`, `operational.in_progress`, dll.) tetap ada.

Pembanding owner: `api GET "/dashboard?range=all" "$OT" | grep -c revenue` harus lebih dari 0.

### 6.8 Scope outlet

```bash
api GET "/dashboard?range=all&outlet_id=$O2" "$ST1" | jq -c '.data | {outlet_id, orders:.totals.orders}'
api GET "/dashboard?range=all&outlet_id=$O1" "$OT" | jq -c '.data.totals.orders'
api GET "/dashboard?range=all" "$OT" | jq -c '.data.totals.orders'
st GET "/dashboard?outlet_id=00000000-0000-0000-0000-000000000000" "$OT"
```
**Harus:** staff dengan `outlet_id` outlet lain tetap melihat data outlet sendiri (`outlet_id` di respons = `O1`); owner dengan filter outlet dan tanpa filter sama (hanya satu outlet yang punya order); ID tidak ada `404`.

### 6.9 Status berubah → dashboard ikut berubah

```bash
api PATCH /orders/$A/status "$OT" '{"status":"processing"}' >/dev/null
api GET "/dashboard?range=all" "$OT" | jq -c '.data | {by_status:[.by_status[]|select(.orders>0)], in_progress:.operational.in_progress}'
api PATCH /orders/$A/payment "$OT" '{"payment_status":"paid"}' >/dev/null
api GET "/dashboard?range=all" "$OT" | jq -c '.data.operational | {unpaid_orders,unpaid_amount}'
api DELETE /orders/$D "$OT" >/dev/null
api GET "/dashboard?range=all" "$OT" | jq -c '.data | {orders:.totals.orders, ready:.operational.ready_for_pickup}'
```
**Harus:** `processing` muncul di `by_status` dan `in_progress` tetap `1`; setelah A dilunasi, `unpaid_orders` turun jadi `1` dan `unpaid_amount` `24000`; setelah D dihapus, order hilang dari `totals` dan `ready_for_pickup` menjadi `0`.

---

## 7. Fase B6 — Kesiapan produksi

Pastikan `.env` dalam kondisi default (`APP_ENV=development`).

### 7.1 Validasi konfigurasi produksi

```bash
docker build -t jesi-server .
docker run --rm -e APP_ENV=production jesi-server; echo "exit=$?"
```
**Harus:** exit bukan 0, pesan mencantumkan **semua** konfigurasi yang kurang (database, secret, Resend, `MAIL_FROM`).

```bash
docker run --rm -e APP_ENV=production -e DATABASE_URL=postgres://x:y@h/d \
 -e JWT_ACCESS_SECRET=change-me-to-a-random-string-at-least-32-chars \
 -e OTP_SECRET=$(openssl rand -hex 32) -e RESEND_API_KEY=re_x -e MAIL_FROM='A <a@b.com>' jesi-server; echo "exit=$?"
```
**Harus:** ditolak karena secret masih nilai contoh (`change-me...`).

```bash
docker run --rm -e APP_ENV=production -e DATABASE_URL=postgres://x:y@h/d \
 -e JWT_ACCESS_SECRET=pendek -e OTP_SECRET=$(openssl rand -hex 32) -e RESEND_API_KEY=re_x -e MAIL_FROM='A <a@b.com>' jesi-server; echo "exit=$?"
docker run --rm -e APP_ENV=production -e DATABASE_URL=postgres://x:y@h/d \
 -e JWT_ACCESS_SECRET=$(openssl rand -hex 32) -e OTP_SECRET=$(openssl rand -hex 32) -e MAIL_FROM='A <a@b.com>' jesi-server; echo "exit=$?"
```
**Harus:** ditolak (secret terlalu pendek), ditolak (tanpa `RESEND_API_KEY`).

Secret acak yang valid lolos validasi dan baru gagal saat mencoba terhubung ke database `h`:

```bash
docker run --rm -e APP_ENV=production -e DATABASE_URL=postgres://x:y@h/d \
 -e JWT_ACCESS_SECRET=$(openssl rand -hex 32) -e OTP_SECRET=$(openssl rand -hex 32) -e RESEND_API_KEY=re_x -e MAIL_FROM='A <a@b.com>' jesi-server; echo "exit=$?"
```
**Harus:** pesan error berupa kegagalan koneksi database (bukan kegagalan konfigurasi).

`.env.example` dengan `APP_ENV=development` tetap harus jalan normal: `docker compose up -d` tidak boleh gagal karena nilai `change-me`.

### 7.2 Properti image

```bash
docker image ls jesi-server --format '{{.Size}}'
docker inspect -f '{{.Config.User}}' jesi-server
docker run --rm --entrypoint sh jesi-server -c 'echo masuk'
```
**Harus:** ukuran kecil (puluhan MB); user `nonroot:nonroot`; perintah ketiga **gagal** (image distroless tidak punya shell).

### 7.3 Graceful shutdown

```bash
reset_all
time docker compose stop api
docker inspect -f '{{.State.ExitCode}}' $(docker compose ps -aq api)
docker compose logs api --tail 5
docker compose up -d api
```
**Harus:** berhenti dalam beberapa detik (bukan 10 detik penuh), exit code `0` (bukan `137` yang berarti dibunuh paksa), dan log mencatat shutdown.

### 7.4 Pembersihan data kedaluwarsa

```bash
export REG='{"name":"Jesi","email":"owner@jesilaundry.com","password":"rahasia123","outlet_name":"Jesi Laundry","outlet_code":"JL"}'
api POST /auth/register-owner "" "$REG" >/dev/null
UID_=$(dbq "select id from users limit 1;" | sed -n '3p' | tr -d ' ')
dbq "insert into refresh_tokens (id,user_id,token_hash,expires_at,revoked_at,created_at,updated_at) values (gen_random_uuid(),'$UID_',repeat('a',64),now()-interval '2 days',null,now()-interval '40 days',now());"
dbq "insert into refresh_tokens (id,user_id,token_hash,expires_at,revoked_at,created_at,updated_at) values (gen_random_uuid(),'$UID_',repeat('b',64),now()+interval '20 days',now()-interval '5 days',now()-interval '6 days',now());"
dbq "select left(token_hash,1) as t, expires_at < now() as kedaluwarsa, revoked_at is not null as dicabut from refresh_tokens where token_hash in (repeat('a',64),repeat('b',64)) order by 1;"
tok owner@jesilaundry.com rahasia123 >/dev/null
dbq "select left(token_hash,1) as t from refresh_tokens where token_hash in (repeat('a',64),repeat('b',64)) order by 1;"
```
**Harus:** setelah login, token `a` (kedaluwarsa) **terhapus**, token `b` (dicabut 5 hari lalu) **masih ada** (disimpan 30 hari agar deteksi reuse tetap bekerja).

OTP kedaluwarsa:

```bash
dbq "insert into password_reset_otps (id,user_id,code_hash,expires_at,attempts,used_at,created_at,updated_at) values (gen_random_uuid(),'$UID_',repeat('c',64),now()-interval '2 days',0,null,now()-interval '2 days',now());"
curl -s -X POST $B/auth/forgot-password -H "$H" -d '{"email":"owner@jesilaundry.com"}' >/dev/null
dbq "select count(*) from password_reset_otps where code_hash=repeat('c',64);"
```
**Harus:** `0`.

### 7.5 Tidak ada rahasia di log

Jalankan semua alur sensitif, lalu cari kebocoran:

```bash
reset_limiter
api POST /auth/login "" '{"email":"owner@jesilaundry.com","password":"rahasia123"}' >/dev/null
api POST /auth/login "" '{"email":"owner@jesilaundry.com","password":"salah-sekali"}' >/dev/null
curl -s -X POST $B/auth/forgot-password -H "$H" -d '{"email":"owner@jesilaundry.com"}' >/dev/null
OT=$(tok owner@jesilaundry.com rahasia123)
api GET /me "$OT" >/dev/null
docker compose logs api --since 5m > /tmp/api.log
grep -ciE "rahasia123|salah-sekali|Bearer|eyJ|authorization|password_hash" /tmp/api.log
grep -c "$OT" /tmp/api.log
```
**Harus:** `0` dan `0`. (Satu pengecualian yang disengaja: di development, `LogMailer` mencetak kode OTP; itu bukan kebocoran, tetapi tidak boleh terjadi di produksi, lihat §7.6.)

### 7.6 Mode produksi lokal (Resend palsu)

Dengan kunci Resend palsu, aplikasi harus **tetap tidak mencetak OTP** dan tetap merespons `200`.

```bash
sed -i '' 's/^APP_ENV=.*/APP_ENV=production/' .env
sed -i '' 's/^JWT_ACCESS_SECRET=.*/JWT_ACCESS_SECRET='$(openssl rand -hex 32)'/' .env
sed -i '' 's/^OTP_SECRET=.*/OTP_SECRET='$(openssl rand -hex 32)'/' .env
sed -i '' 's/^RESEND_API_KEY=.*/RESEND_API_KEY=re_palsu_123/' .env
sed -i '' 's/^MAIL_FROM=.*/MAIL_FROM=Jesi <no-reply@example.com>/' .env
docker compose up -d --no-deps --force-recreate api
until curl -sf localhost:8080/health >/dev/null; do sleep 1; done
curl -s -X POST $B/auth/forgot-password -H "$H" -d '{"email":"owner@jesilaundry.com"}' | jq -c
docker compose logs api --since 1m | grep -E "[0-9]{6}"
docker compose logs api --since 1m | tail -5
```
**Harus:** respons `200`; **tidak ada** kode 6 digit di log; log berisi error pengiriman email tanpa membocorkan OTP atau API key.

Kembalikan `.env` ke development setelah selesai:

```bash
cp .env.example .env
docker compose up -d --no-deps --force-recreate api
```

### 7.7 Rate limit di balik proxy (`CLIENT_IP_HEADER`)

```bash
echo "CLIENT_IP_HEADER=X-Real-IP" >> .env
docker compose up -d --no-deps --force-recreate api
until curl -sf localhost:8080/health >/dev/null; do sleep 1; done
for i in {1..11}; do curl -s -o /dev/null -w "%{http_code} " -X POST $B/auth/login -H "$H" -H "X-Real-IP: 1.2.3.4" -d '{"email":"x@x.com","password":"salah12345"}'; done; echo
curl -s -o /dev/null -w "%{http_code}\n" -X POST $B/auth/login -H "$H" -H "X-Real-IP: 5.6.7.8" -d '{"email":"x@x.com","password":"salah12345"}'
```
**Harus:** untuk IP `1.2.3.4`: sepuluh kali `401`, lalu `429`; IP lain `5.6.7.8` tetap `401` (hitungan per IP klien, bukan satu hitungan untuk semua).

Tanpa env (header tidak dipercaya):

```bash
sed -i '' '/^CLIENT_IP_HEADER=/d' .env
docker compose up -d --no-deps --force-recreate api
until curl -sf localhost:8080/health >/dev/null; do sleep 1; done
for i in {1..11}; do curl -s -o /dev/null -w "%{http_code} " -X POST $B/auth/login -H "$H" -H "X-Real-IP: 1.$i.1.1" -d '{"email":"x@x.com","password":"salah12345"}'; done; echo
```
**Harus:** header palsu **diabaikan**: request ke-11 tetap `429` walau setiap request memakai `X-Real-IP` berbeda.

### 7.8 Deploy ke Neon + Vercel

Hanya setelah §7.1–7.7 lolos.

1. **Neon:** buat project/database. Ambil `DATABASE_URL` (pooled) dan `DATABASE_URL_UNPOOLED` (direct).
2. **Migrasi ke Neon dari lokal:**
   ```bash
   DATABASE_URL_UNPOOLED="<url-unpooled>" DATABASE_URL="<url-unpooled>" go run ./cmd/migrate
   psql "<url-unpooled>" -c '\dt'
   ```
   **Harus:** 9 tabel terbentuk di Neon.
3. **Vercel:** ikuti README root (root directory `server`, preset container, env var, `PORT=8080`, `CLIENT_IP_HEADER=X-Real-IP`). Deploy.
4. **Health:**
   ```bash
   curl -i https://<project>.vercel.app/health
   ```
   **Harus:** `200`, `{"status":"ok","database":"ok"}`.
5. **Cold start:** diamkan 10 menit lalu ukur:
   ```bash
   curl -s -o /dev/null -w "%{time_total}s\n" https://<project>.vercel.app/health
   curl -s -o /dev/null -w "%{time_total}s\n" https://<project>.vercel.app/health
   ```
   Request pertama boleh lebih lambat (beberapa detik); request kedua harus cepat.
6. **Register owner produksi** (membuat akun owner asli, gunakan data sebenarnya):
   ```bash
   P=https://<project>.vercel.app/api/v1
   curl -s $P/auth/setup-status | jq
   ```
7. **OTP asli lewat email:** minta `forgot-password` ke email owner. **Harus:** email tiba dalam hitungan detik dengan bahasa sesuai `Accept-Language` (`id` atau `en`), dan tidak ada OTP di log Vercel (`vercel logs`).
8. **Verifikasi rate limit per IP (yang diragukan):** dari jaringan Wi-Fi, kirim 11 login salah; lalu dari data seluler (jaringan lain) kirim 1 login salah. **Harus:** jaringan kedua tidak terkena `429`. Jika terkena, asumsi IP klien salah; hentikan dan laporkan.
9. **Pool Neon:** gunakan `DATABASE_URL` pooled di Vercel, `DB_MAX_OPEN_CONNS=5`. Jalankan alur order dan dashboard lewat curl ke URL produksi dan pastikan tidak ada error koneksi.

---

## 8. Jika ada yang gagal

### 8.1 Gejala umum

| Gejala | Kemungkinan penyebab |
|---|---|
| `curl: (7) Failed to connect` | `api` belum jalan atau crash. Cek `docker compose ps -a` dan `docker compose logs api`. |
| `jq: parse error` | Respons bukan JSON (kosong atau teks). Jalankan perintah tanpa `| jq` untuk melihat apa yang dikirim server. |
| Semua respons `401 TOKEN_EXPIRED` | Access token lebih dari 15 menit. Ambil ulang dengan `tok`. |
| `429 RATE_LIMITED` di tengah uji | Batas login/forgot-password tercapai. Jalankan `reset_limiter`. |
| Variabel kosong (`$S_CS` dll.) | Perintah `svc` gagal karena `OT` kedaluwarsa atau outlet salah. Cetak `echo $S_CS` sebelum memakainya. |
| `dbq` gagal | Container `db` mati. `docker compose up -d db`. |
| Banyak `422` yang tidak diharapkan | Cek `jq .error.details`; biasanya field salah ketik atau JSON tidak valid. |

### 8.2 Format laporan ke Claude Code / ke saya

Sertakan empat hal:

1. **Fase dan nomor uji** (mis. "B4a §4.2").
2. **Perintah yang dijalankan** (salin persis).
3. **Hasil yang didapat** (tempel output, termasuk kode HTTP dan `error.code`).
4. **Hasil yang diharapkan** (dari bagian **Harus:**).

Tambahkan `docker compose logs api --tail 30` jika ada status `500`.

### 8.3 Aturan perbaikan

- Perbaiki bug fase terkait dulu, lalu jalankan ulang **seluruh** bagian uji fase itu (bukan hanya poin yang gagal), karena perbaikan bisa merusak poin lain.
- Bug di fase lebih awal (mis. B2) ditemukan saat menguji fase lanjut: perbaiki di sana, lalu jalankan ulang uji fase asal.

---

## 9. Checklist hasil

Salin dan isi sambil menguji.

| Fase | Bagian | Hasil | Catatan |
|---|---|---|---|
| B1 | 1.1 kompilasi bersih | ☐ | |
| B1 | 1.2–1.4 docker up, health, 404 | ☐ | |
| B1 | 1.5–1.7 tabel, index, constraint, tipe kolom | ☐ | |
| B1 | 1.8–1.9 constraint bekerja, migrasi idempoten | ☐ | |
| B2 | 2.1–2.4 setup, validasi, race, register | ☐ | |
| B2 | 2.5–2.7 login, `/me`, token kedaluwarsa | ☐ | |
| B2 | 2.8–2.9 refresh, reuse, logout | ☐ | |
| B2 | 2.10 lupa password, OTP, batas percobaan | ☐ | |
| B2 | 2.11–2.13 ganti password, rate limit, body limit | ☐ | |
| B3 | 3.1–3.3 outlet, layanan, satuan | ☐ | |
| B3 | 3.4–3.6 staff, scope, pencabutan sesi | ☐ | |
| B4a | 4.1–4.5 harga, minimum, validasi | ☐ | |
| B4a | 4.6–4.7 staff, pelanggan | ☐ | |
| B4a | 4.8–4.10 nomor order, list, detail, scope | ☐ | |
| B4b | 5.1–5.6 status, pembayaran, paralel | ☐ | |
| B4b | 5.7–5.9 edit, hapus, pool koneksi | ☐ | |
| B5 | 6.1–6.3 dataset, angka, series | ☐ | |
| B5 | 6.4–6.6 rentang, zona waktu, `all` | ☐ | |
| B5 | 6.7–6.9 staff tanpa pendapatan, scope, perubahan status | ☐ | |
| B6 | 7.1–7.3 config produksi, image, shutdown | ☐ | |
| B6 | 7.4–7.6 pembersihan, log, mode produksi | ☐ | |
| B6 | 7.7 rate limit proxy | ☐ | |
| B6 | 7.8 deploy Neon + Vercel | ☐ | |

Setelah semua baris tercentang, backend siap menjadi dasar frontend.