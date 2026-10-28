# Jesi Laundry App

Aplikasi mobile internal (Android & iOS) untuk mencatat cucian masuk harian di Jesi Laundry, lengkap dengan dashboard dan grafik. Monorepo ini berisi:

- `server/` — backend Go (Fiber v3 + GORM + PostgreSQL). Spesifikasi: [`server/BACKEND.md`](server/BACKEND.md).
- `client/` — aplikasi Flutter (Android & iOS). Spesifikasi: [`client/FRONTEND.md`](client/FRONTEND.md).
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — dokumen induk (prinsip, kontrak API, hak akses).

Bagian server ada di bawah; bagian [Client (Flutter)](#client-flutter) ada di akhir dokumen.

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

## Client (Flutter)

Aplikasi mobile Android & iOS di `client/`. Spesifikasi: [`client/FRONTEND.md`](client/FRONTEND.md).

### Prasyarat

| Kebutuhan | Versi | Untuk |
|---|---|---|
| Flutter | 3.47.x stable (Dart 3.13) | semua |
| Android Studio / Android SDK | API 34+ (minSdk 34) | build & run Android |
| Xcode | iOS 18+ SDK | build & run iOS (macOS saja) |
| Server lokal berjalan | lihat bagian server di atas | development |

### Alamat API (`API_BASE_URL`)

Alamat server **hanya** dibaca dari `--dart-define=API_BASE_URL=...` dan tidak punya nilai bawaan.
Jika kosong, aplikasi menampilkan layar error konfigurasi. Tulis tanpa `/api/v1` dan tanpa garis miring di akhir.
Tidak ada secret yang disimpan di klien.

### Menjalankan secara lokal

Jalankan server lokal dulu (`docker compose up --build` di `server/`, port 8080), lalu:

```bash
cd client
flutter pub get

# Emulator Android (10.0.2.2 = localhost mesin host)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Simulator iOS
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# Perangkat fisik (Android/iOS) di jaringan Wi-Fi yang sama dengan komputer
# Ganti 192.168.1.10 dengan IP LAN komputer Anda
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

HTTP (tanpa TLS) hanya diizinkan pada build debug. Di iOS, `NSAllowsLocalNetworking` mengizinkan alamat jaringan lokal.
Build release hanya menerima HTTPS.

### Menjalankan terhadap server hosting

Server sudah live di Vercel. Alamat server **tidak** ada di kode; berikan lewat `--dart-define`:

```bash
cd client
flutter run -d <id-perangkat> --dart-define=API_BASE_URL=https://jesi-laundry-app-server.vercel.app
```

Cari `<id-perangkat>` dengan `flutter devices`.

Android Studio: **Run > Edit Configurations... > Flutter > main.dart**, lalu isi kolom **Additional run args** dengan:

```
--dart-define=API_BASE_URL=https://jesi-laundry-app-server.vercel.app
```

Aturan penulisan URL: skema + host saja (`https://...`), **tanpa** `/api/v1` dan **tanpa** garis miring di akhir.
Aplikasi menambahkan `/api/v1` sendiri.

Catatan penting:

- Server hosting berisi data nyata. Data uji yang dibuat saat pengembangan harus dibersihkan sebelum go-live.
- Owner sudah terdaftar di server hosting, jadi tombol dan layar **Daftar sebagai Owner** tidak akan muncul
  (layar itu hanya tampil selama `GET /auth/setup-status` mengembalikan `owner_exists = false`).
- **Lupa password** benar-benar mengirim email OTP dan **reset password mengubah password akun nyata**.
  Jangan dicoba pada akun yang masih dipakai.

### Build rilis

Build rilis **hanya menerima alamat HTTPS**. Jika `API_BASE_URL` kosong atau bukan `https://...`, aplikasi
menampilkan layar error konfigurasi dan tidak memanggil server. Build debug masih boleh memakai HTTP untuk
server lokal.

#### Android

1. Buat keystore **di luar repo** (jangan di folder proyek), simpan baik-baik beserta kata sandinya:

   ```bash
   keytool -genkey -v -keystore ~/keystores/jesi-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Buat `client/android/key.properties` (sudah di-gitignore, jangan di-commit) dengan isi:

   ```properties
   storeFile=/path/absolut/ke/jesi-upload.jks
   storePassword=<kata sandi keystore>
   keyAlias=upload
   keyPassword=<kata sandi key>
   ```

3. Bangun:

   ```bash
   cd client
   flutter build appbundle --release --dart-define=API_BASE_URL=https://<alamat-server-https>   # untuk Play Store
   flutter build apk --release --dart-define=API_BASE_URL=https://<alamat-server-https>         # APK langsung
   ```

Tanpa `key.properties`, build rilis tetap jadi tetapi ditandatangani dengan kunci **debug** dan Gradle mencetak
peringatan. Hasil seperti itu hanya untuk verifikasi, **jangan diunggah ke Play Store**.

#### iOS

```bash
cd client
flutter build ipa --release --dart-define=API_BASE_URL=https://<alamat-server-https>
```

`flutter build ipa` membutuhkan Apple Developer Team yang sudah diatur di Xcode
(`ios/Runner.xcworkspace` > Runner > Signing & Capabilities). Di mesin tanpa itu, gunakan
`flutter build ios --release --no-codesign --dart-define=API_BASE_URL=https://<alamat-server-https>` hanya
untuk memverifikasi bahwa proyek dapat dibangun.

### Distribusi internal

- **Android:** bagikan APK rilis (`build/app/outputs/flutter-apk/app-release.apk`) langsung; penerima perlu
  mengizinkan pemasangan dari sumber tidak dikenal. Untuk distribusi terkelola gunakan jalur uji internal Play Console.
- **iOS:** unggah ke App Store Connect lalu bagikan lewat TestFlight, atau gunakan distribusi Ad Hoc (perangkat
  harus didaftarkan di akun Apple Developer).

Jangan pernah menaruh keystore, kata sandi, atau `key.properties` di repo atau di pesan/dokumen yang dibagikan.

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

## Client (Flutter)

Aplikasi mobile Android & iOS di `client/`. Spesifikasi: [`client/FRONTEND.md`](client/FRONTEND.md).

### Prasyarat

| Kebutuhan | Versi | Untuk |
|---|---|---|
| Flutter | 3.47.x stable (Dart 3.13) | semua |
| Android Studio / Android SDK | API 34+ (minSdk 34) | build & run Android |
| Xcode | iOS 18+ SDK | build & run iOS (macOS saja) |
| Server lokal berjalan | lihat bagian server di atas | development |

### Alamat API (`API_BASE_URL`)

Alamat server **hanya** dibaca dari `--dart-define=API_BASE_URL=...` dan tidak punya nilai bawaan.
Jika kosong, aplikasi menampilkan layar error konfigurasi. Tulis tanpa `/api/v1` dan tanpa garis miring di akhir.
Tidak ada secret yang disimpan di klien.

### Menjalankan secara lokal

Jalankan server lokal dulu (`docker compose up --build` di `server/`, port 8080), lalu:

```bash
cd client
flutter pub get

# Emulator Android (10.0.2.2 = localhost mesin host)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# Simulator iOS
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# Perangkat fisik (Android/iOS) di jaringan Wi-Fi yang sama dengan komputer
# Ganti 192.168.1.10 dengan IP LAN komputer Anda
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

HTTP (tanpa TLS) hanya diizinkan pada build debug. Di iOS, `NSAllowsLocalNetworking` mengizinkan alamat jaringan lokal.
Build release hanya menerima HTTPS.

### Menjalankan terhadap server hosting

Server sudah live di Vercel. Alamat server **tidak** ada di kode; berikan lewat `--dart-define`:

```bash
cd client
flutter run -d <id-perangkat> --dart-define=API_BASE_URL=https://jesi-laundry-app-server.vercel.app
```

Cari `<id-perangkat>` dengan `flutter devices`.

Android Studio: **Run > Edit Configurations... > Flutter > main.dart**, lalu isi kolom **Additional run args** dengan:

```
--dart-define=API_BASE_URL=https://jesi-laundry-app-server.vercel.app
```

Aturan penulisan URL: skema + host saja (`https://...`), **tanpa** `/api/v1` dan **tanpa** garis miring di akhir.
Aplikasi menambahkan `/api/v1` sendiri.

Catatan penting:

- Server hosting berisi data nyata. Data uji yang dibuat saat pengembangan harus dibersihkan sebelum go-live.
- Owner sudah terdaftar di server hosting, jadi tombol dan layar **Daftar sebagai Owner** tidak akan muncul
  (layar itu hanya tampil selama `GET /auth/setup-status` mengembalikan `owner_exists = false`).
- **Lupa password** benar-benar mengirim email OTP dan **reset password mengubah password akun nyata**.
  Jangan dicoba pada akun yang masih dipakai.

### Build rilis

```bash
cd client
flutter build appbundle --release --dart-define=API_BASE_URL=https://<alamat-server-https>
flutter build ipa --release --dart-define=API_BASE_URL=https://<alamat-server-https>
```

Penandatanganan Android (`key.properties`) dan langkah rilis iOS ditambahkan pada fase F7.

### Pemeriksaan kode

```bash
cd client
dart format .
flutter analyze
```

### Catatan lingkungan (macOS)

Jika `flutter create` / `flutter build` gagal dengan pesan `openssl x509 ... incorrect architecture`, ada `openssl`
berarsitektur x86_64 (mis. milik XAMPP) yang mendahului `/opt/homebrew/bin` di `PATH`. Dahulukan
`/opt/homebrew/bin` di `PATH` untuk sesi terminal tersebut, atau pasang Rosetta.
