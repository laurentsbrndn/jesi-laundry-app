# Jesi Laundry App

Aplikasi mobile internal (Android & iOS) untuk mencatat cucian masuk harian di Jesi Laundry, lengkap dengan dashboard dan grafik. Monorepo ini berisi:

- `server/` — backend Go (Fiber v3 + GORM + PostgreSQL). Spesifikasi: [`server/BACKEND.md`](server/BACKEND.md).
- `client/` — aplikasi Flutter (dikerjakan setelah backend). Spesifikasi: `client/FRONTEND.md`.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — dokumen induk (prinsip, kontrak API, hak akses).

Dokumen ini hanya membahas **server**.

## Prasyarat

| Kebutuhan | Versi | Untuk |
|---|---|---|
| Docker + Docker Compose | terbaru | menjalankan server + PostgreSQL |
| Go | 1.27 | menjalankan tanpa Docker, atau migrasi ke database produksi dari mesin lokal |
| Akun Neon, Vercel, Resend | — | deploy produksi |
| Vercel CLI (`npm i -g vercel`) | terbaru | deploy dari terminal |

## Menjalankan server secara lokal

```bash
cd server
cp .env.example .env          # sesuaikan bila perlu; nilai bawaan cukup untuk development
docker compose up --build     # urutan: db -> migrate -> api
```

Server berjalan di `http://localhost:8080`.

```bash
curl http://localhost:8080/health
# {"status":"ok","database":"ok"}
```

Di development, `RESEND_API_KEY` boleh kosong: kode OTP lupa password dicetak ke log container `api`
(`docker compose logs -f api`). Di production OTP **tidak pernah** dicetak.

Alternatif tanpa Docker untuk `api`:

```bash
cd server
docker compose up db          # hanya PostgreSQL
go run ./cmd/migrate
go run ./cmd/api
```

### Migrasi database

Migrasi (GORM AutoMigrate) **tidak** berjalan otomatis saat `api` start. Jalankan:

```bash
docker compose run --rm migrate     # lewat Docker
go run ./cmd/migrate                # tanpa Docker
```

AutoMigrate menambah tabel, kolom, index, dan constraint, tetapi tidak menghapus kolom. Perubahan destruktif dilakukan manual.
Migrasi memakai `DATABASE_URL_UNPOOLED` bila diisi, selain itu `DATABASE_URL`.

### Pemeriksaan kode

```bash
cd server
gofmt -l .        # harus kosong
go build ./...
go vet ./...
```

Proyek ini sengaja tidak memiliki file test; pengujian dilakukan manual.

## Variabel lingkungan (`server/.env`)

| Variabel | Default | Keterangan |
|---|---|---|
| `APP_ENV` | `development` | `development` atau `production`. Production menolak start bila konfigurasi di bawah belum lengkap. |
| `PORT` | `8080` | Port HTTP. Di Vercel **wajib** diisi (lihat deploy). |
| `APP_TIMEZONE` | `Asia/Jakarta` | Zona waktu bisnis: pengelompokan dashboard, tanggal nomor order, filter tanggal. |
| `DATABASE_URL` | — (wajib) | Koneksi runtime. Di produksi gunakan connection string **pooled** Neon. |
| `DATABASE_URL_UNPOOLED` | kosong | Koneksi direct untuk migrasi. Kosong = pakai `DATABASE_URL`. |
| `DB_MAX_OPEN_CONNS` / `DB_MAX_IDLE_CONNS` | `10` / `5` | Pool koneksi per instance. Di Vercel gunakan kecil (`5` / `2`). |
| `JWT_ACCESS_SECRET` | — (wajib) | Rahasia penanda access token, minimal 32 karakter. Di production nilai contoh (`change-me...`) ditolak. |
| `JWT_ACCESS_TTL` | `15m` | Umur access token. |
| `REFRESH_TOKEN_TTL` | `720h` | Umur refresh token (30 hari). |
| `OTP_SECRET` | — (wajib) | Rahasia HMAC OTP, minimal 32 karakter. Di production nilai contoh ditolak. |
| `OTP_TTL` | `10m` | Masa berlaku OTP lupa password. |
| `CLIENT_IP_HEADER` | kosong | Header berisi IP klien di belakang proxy (Vercel: `X-Real-IP`). Kosong = tidak mempercayai header apa pun (lokal). Dipakai rate limiter. |
| `RESEND_API_KEY` | kosong | Wajib di production. Kosong di development = OTP dicetak ke log. |
| `MAIL_FROM` | — | Pengirim email, mis. `Jesi Laundry <no-reply@domain-anda.com>`. Wajib di production; domain harus terverifikasi di Resend. |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | `jesi` / `jesi` / `jesi_laundry` | Hanya dipakai `docker-compose` untuk container PostgreSQL. |

Buat secret acak, mis. `openssl rand -base64 48`. Gunakan nilai berbeda untuk `JWT_ACCESS_SECRET` dan `OTP_SECRET`.

## Deploy ke Vercel (Container Runtime) + Neon

Vercel Container Runtime berstatus **Beta**. Vercel membangun image dari `server/Dockerfile` yang sama dengan lokal.

1. **Database (Neon).** Buat project Neon (dari Vercel Marketplace: `vercel integration add neon`, atau dari console Neon).
   Simpan dua connection string: **pooled** (`DATABASE_URL`) dan **direct/unpooled** (`DATABASE_URL_UNPOOLED`).
2. **Resend.** Buat API key dan verifikasi domain pengirim agar `MAIL_FROM` bisa dipakai.
3. **Migrasi** dari mesin lokal (sebelum deploy, dan setiap kali model berubah):
   ```bash
   cd server
   DATABASE_URL="<neon-unpooled-url>" go run ./cmd/migrate
   ```
   `cmd/migrate` hanya butuh `DATABASE_URL`, `DATABASE_URL_UNPOOLED`, `APP_TIMEZONE`, `APP_ENV` — tanpa secret JWT/OTP.
4. **Project Vercel.** Impor repo, set **Root Directory = `server`**.
5. **Preset Container.** Paksa preset container (folder berisi `go.mod`):
   ```bash
   vercel project update --framework container --yes
   ```
6. **Environment variables** (Production dan Preview):
   `APP_ENV=production`, `PORT=8080`, `APP_TIMEZONE=Asia/Jakarta`, `JWT_ACCESS_SECRET`, `JWT_ACCESS_TTL=15m`,
   `REFRESH_TOKEN_TTL=720h`, `OTP_SECRET`, `OTP_TTL=10m`, `CLIENT_IP_HEADER=X-Real-IP`, `RESEND_API_KEY`, `MAIL_FROM`,
   `DB_MAX_OPEN_CONNS=5`, `DB_MAX_IDLE_CONNS=2`, `DATABASE_URL` (pooled), `DATABASE_URL_UNPOOLED`.

   `PORT=8080` wajib: tanpa itu Vercel mengarahkan traffic ke port 80, yang tidak bisa dibuka user non-root di image ini.
7. **Deploy:** `vercel deploy --prod` (atau push ke branch production), lalu cek:
   ```bash
   curl https://<project>.vercel.app/health
   ```
8. **Cek rate limit per IP.** Kirim 11 login salah dari satu jaringan sampai `RATE_LIMITED`, lalu coba dari jaringan lain
   (mis. data seluler). Bila jaringan kedua ikut terblokir, IP klien tidak terbaca benar — lihat `server/BACKEND.md` §9.5 dan §13.
9. **Mobile:** arahkan `API_BASE_URL` ke `https://<project>.vercel.app`.

Catatan operasional:

- Instance di-scale-down setelah ±5 menit tanpa traffic (production) sehingga request pertama setelah idle bisa lebih lambat.
- Rate limiter bersifat **per instance** (memori); perlindungan utama brute force OTP adalah batas percobaan di database.
- Static IP dan Secure Compute belum didukung untuk container di Vercel, jadi database Neon tidak dapat dibatasi ke IP tetap.
- Image berupa Docker standar (listen di `PORT`, stateless, konfigurasi lewat env) sehingga bisa dipindah ke VPS, Render, Fly.io, dll tanpa mengubah kode.

### Paket Vercel

Paket **Hobby (gratis) Vercel hanya untuk penggunaan pribadi non-komersial**. Aplikasi operasional usaha laundry termasuk
penggunaan komersial dan membutuhkan paket **Pro**. Pemilik proyek bertanggung jawab memilih paket yang sesuai.
