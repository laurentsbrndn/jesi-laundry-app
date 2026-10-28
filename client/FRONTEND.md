# Jesi Laundry App — Spesifikasi Frontend (Flutter)

> Lokasi file: `jesi-laundry-app/client/FRONTEND.md`. Baca `../ARCHITECTURE.md` terlebih dahulu, dan gunakan `../server/BACKEND.md` §10–§11 sebagai kontrak API.
> Platform: **Android & iOS saja**. Flutter 3.47.x stable (Dart 3.13).

---

## 1. Tujuan & Batasan

- Aplikasi mobile untuk owner & staff: input order, tracking status & pembayaran, dashboard + grafik, pengelolaan katalog/staff/outlet (owner).
- Hanya Android (minimal Android 14, API 34) dan iOS (minimal iOS 18). Jangan generate folder `web/`, `linux/`, `macos/`, `windows/`.
- Arsitektur **feature-first** dengan dua lapisan per fitur: `data/` (model + repository) dan `presentation/` (controller Riverpod + screen + widget). Tanpa domain/usecase layer.
- Tanpa code generation kecuali `gen-l10n` bawaan Flutter (tidak memakai freezed, json_serializable, riverpod_generator, build_runner).
- **Tidak ada file test.** Hapus folder `test/` dan dependency `flutter_test` hasil `flutter create`.
- Satu model per file.
- Semua teks yang dilihat pengguna dari ARB (id & en). Tidak ada string UI hard-coded.

---

## 2. Versi, Platform & Material UI

### 2.1 Membuat Proyek

```bash
flutter create --platforms=android,ios --org com.jesilaundry --project-name jesi_laundry_app client
```

Setelah itu ubah identifier agar persis `com.jesilaundry.app`:

- **Android** (`android/app/build.gradle.kts`): `namespace = "com.jesilaundry.app"`, `applicationId = "com.jesilaundry.app"`, `minSdk = 34`. Pindahkan `MainActivity.kt` ke `android/app/src/main/kotlin/com/jesilaundry/app/` dan sesuaikan `package`.
- **iOS** (Runner target, semua build configuration): `PRODUCT_BUNDLE_IDENTIFIER = com.jesilaundry.app`, `IPHONEOS_DEPLOYMENT_TARGET = 18.0`. Jika proyek memakai CocoaPods, set `platform :ios, '18.0'` di `ios/Podfile`.

### 2.2 Konfigurasi Platform

Android:

- `android/app/src/main/AndroidManifest.xml`: permission `android.permission.INTERNET`, `android:label="Jesi Laundry"`.
- `android/app/src/debug/AndroidManifest.xml`: `android:usesCleartextTraffic="true"` dengan `tools:replace="android:usesCleartextTraffic"` (deklarasi `xmlns:tools`), agar menimpa nilai `false` di manifest utama (hanya debug, untuk server lokal HTTP).

iOS (`ios/Runner/Info.plist`):

- `CFBundleDisplayName` = `Jesi Laundry`.
- `CFBundleLocalizations` = `id`, `en`.
- `NSAppTransportSecurity` → `NSAllowsLocalNetworking = true` (untuk server lokal saat development; produksi memakai HTTPS).

Kedua platform: orientasi **portrait saja** (set juga lewat `SystemChrome.setPreferredOrientations` di `main.dart`).

### 2.3 Material UI Standalone (Flutter 3.47)

Material kini tersedia sebagai paket `material_ui`, dan library bawaan SDK dijadwalkan deprecated. Aturan:

- Selalu `import 'package:material_ui/material_ui.dart';` — **jangan** `package:flutter/material.dart`.
- Tidak memakai Cupertino; tidak perlu `cupertino_ui`.
- Bungkus app dengan `MaterialUiCompatibilityBridge` di `MaterialApp.router(builder: ...)`, karena sebagian dependency (mis. `go_router`, `fl_chart`) mungkin masih mengimpor library Material lama.
- Delegasi lokalisasi: `localizationsDelegates: [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]` dengan `GlobalMaterialLocalizations` dari `material_ui`. **Jangan** memakai `AppLocalizations.localizationsDelegates` hasil generate (merujuk ke delegasi `flutter_localizations` lama). Jangan mengimpor `flutter_localizations` di kode aplikasi.
- Jika ada error tipe (type mismatch) dari dependency yang mengekspos tipe Material lama di API publiknya, laporkan di ringkasan fase beserta solusi yang dipilih.

---

## 3. Dependency

Tambahkan dengan `flutter pub add <nama>` (versi stabil terbaru). Jangan menambah package lain tanpa alasan tertulis.

| Package | Kegunaan |
|---|---|
| `material_ui` | Widget Material 3 |
| `flutter_localizations` (sdk) + `intl` | Dibutuhkan `gen-l10n`, format angka & tanggal |
| `flutter_riverpod` (3.x) | State management |
| `go_router` | Routing + redirect guard |
| `dio` | HTTP client + interceptor |
| `flutter_secure_storage` | Simpan access & refresh token |
| `shared_preferences` | Simpan preferensi tema & bahasa |
| `fl_chart` | Grafik dashboard |

Dev dependency: `flutter_lints` (bawaan). Hapus `flutter_test`.

`pubspec.yaml`: `flutter: generate: true`.

---

## 4. Struktur Folder

```
client/
├── FRONTEND.md
├── pubspec.yaml
├── l10n.yaml
├── analysis_options.yaml
├── android/
├── ios/
└── lib/
    ├── main.dart                                  # init binding, orientasi, SharedPreferences, ProviderScope
    ├── app.dart                                   # MaterialApp.router: theme, themeMode, locale, delegates, bridge
    ├── l10n/
    │   ├── app_id.arb                             # template
    │   ├── app_en.arb
    │   └── gen/                                   # output gen-l10n (jangan diedit manual)
    ├── core/
    │   ├── config/
    │   │   └── app_config.dart                    # API_BASE_URL dari --dart-define
    │   ├── network/
    │   │   ├── dio_provider.dart                  # Dio utama (+ interceptor) & Dio polos untuk refresh
    │   │   ├── auth_interceptor.dart              # pasang Bearer, tangani TOKEN_EXPIRED (single-flight refresh)
    │   │   ├── locale_interceptor.dart            # header Accept-Language
    │   │   ├── api_exception.dart                 # ApiException {code, message, statusCode, details}
    │   │   ├── api_error_code.dart                # konstanta kode error dari ARCHITECTURE.md §8.1
    │   │   ├── field_error.dart                   # detail VALIDATION_ERROR per field
    │   │   └── paginated.dart                     # Paginated<T> {items, page, limit, total, hasMore}
    │   ├── storage/
    │   │   ├── token_storage.dart                 # flutter_secure_storage wrapper
    │   │   └── preferences_storage.dart           # shared_preferences wrapper
    │   ├── router/
    │   │   ├── app_router.dart                    # GoRouter + redirect
    │   │   ├── app_routes.dart                    # konstanta path
    │   │   └── router_refresh_listenable.dart     # jembatan auth state → refreshListenable
    │   ├── theme/
    │   │   ├── app_theme.dart                     # ThemeData light & dark (Material 3)
    │   │   ├── app_theme_preference.dart          # enum system/light/dark
    │   │   └── theme_mode_controller.dart
    │   ├── l10n/
    │   │   ├── app_language_preference.dart       # enum system/id/en
    │   │   ├── locale_controller.dart
    │   │   ├── l10n_extension.dart                # context.l10n
    │   │   └── error_message.dart                 # ApiException/kode → teks terlokalisasi
    │   ├── utils/
    │   │   ├── currency_format.dart               # Rp 12.000 (selalu id_ID, 0 desimal)
    │   │   ├── date_format.dart                   # format tanggal/jam sesuai locale aplikasi
    │   │   ├── quantity_format.dart               # 2,5 kg / 3 pcs / 5 m² sesuai locale
    │   │   ├── decimal_input.dart                 # parse "2,5" & "2.5", batasi 2 desimal
    │   │   └── form_validators.dart
    │   └── widgets/
    │       ├── async_value_view.dart              # loading / error (+retry) / data
    │       ├── error_view.dart
    │       ├── empty_view.dart
    │       ├── loading_button.dart
    │       ├── confirm_dialog.dart
    │       └── section_card.dart
    └── features/
        ├── auth/
        │   ├── data/
        │   │   ├── auth_repository.dart
        │   │   └── models/
        │   │       ├── app_user.dart
        │   │       ├── user_role.dart
        │   │       ├── outlet_ref.dart            # {id, code, name} ringkas
        │   │       └── auth_session.dart
        │   └── presentation/
        │       ├── auth_state.dart                # sealed: Authenticated / Unauthenticated
        │       ├── auth_controller.dart
        │       ├── setup_status_provider.dart
        │       ├── splash_screen.dart
        │       ├── login_screen.dart
        │       ├── register_owner_screen.dart
        │       ├── forgot_password_screen.dart
        │       └── reset_password_screen.dart
        ├── shell/
        │   └── main_shell.dart                    # NavigationBar: Dashboard, Order, Pengaturan
        ├── dashboard/
        │   ├── data/
        │   │   ├── dashboard_repository.dart
        │   │   └── models/
        │   │       ├── dashboard_range.dart
        │   │       ├── dashboard_bucket.dart
        │   │       ├── dashboard_summary.dart
        │   │       ├── dashboard_totals.dart
        │   │       ├── category_stat.dart
        │   │       ├── unit_service_stat.dart
        │   │       ├── speed_stat.dart
        │   │       ├── status_stat.dart
        │   │       ├── series_point.dart
        │   │       └── operational_stat.dart
        │   └── presentation/
        │       ├── dashboard_controller.dart
        │       ├── dashboard_screen.dart
        │       └── widgets/
        │           ├── range_selector.dart
        │           ├── operational_cards.dart
        │           ├── summary_cards.dart
        │           ├── series_chart.dart
        │           ├── category_breakdown.dart
        │           ├── unit_service_breakdown.dart
        │           └── status_breakdown.dart
        ├── orders/
        │   ├── data/
        │   │   ├── order_repository.dart
        │   │   └── models/
        │   │       ├── order_status.dart
        │   │       ├── payment_status.dart
        │   │       ├── service_speed.dart
        │   │       ├── order_list_item.dart
        │   │       ├── order_detail.dart
        │   │       ├── order_item.dart
        │   │       ├── order_filter.dart
        │   │       ├── order_draft.dart           # state form (customer, speed, items, notes, paid)
        │   │       └── order_draft_item.dart
        │   └── presentation/
        │       ├── orders_list_controller.dart
        │       ├── order_detail_provider.dart
        │       ├── order_form_controller.dart
        │       ├── order_pricing_preview.dart     # rumus pratinjau total (cermin BACKEND.md §8.1)
        │       ├── orders_list_screen.dart
        │       ├── order_detail_screen.dart
        │       ├── order_form_screen.dart
        │       └── widgets/
        │           ├── order_list_tile.dart
        │           ├── order_status_chip.dart
        │           ├── payment_status_chip.dart
        │           ├── order_filter_bar.dart
        │           ├── speed_selector.dart
        │           ├── kilo_items_section.dart
        │           ├── unit_items_section.dart
        │           ├── unit_item_picker_sheet.dart
        │           ├── order_total_bar.dart
        │           ├── order_items_table.dart
        │           ├── status_timeline.dart
        │           └── order_actions_bar.dart
        ├── customers/
        │   ├── data/
        │   │   ├── customer_repository.dart
        │   │   └── models/
        │   │       └── customer.dart
        │   └── presentation/
        │       ├── customer_autocomplete_field.dart
        │       ├── customers_list_controller.dart
        │       ├── customers_screen.dart          # owner
        │       └── customer_edit_screen.dart      # owner
        ├── catalog/
        │   ├── data/
        │   │   ├── catalog_repository.dart
        │   │   └── models/
        │   │       ├── laundry_service.dart
        │   │       ├── service_category.dart
        │   │       └── pricing_unit.dart
        │   └── presentation/
        │       ├── services_provider.dart         # layanan aktif per outlet (dipakai form order)
        │       ├── services_screen.dart           # owner
        │       └── service_form_screen.dart       # owner
        ├── users/
        │   ├── data/
        │   │   └── user_repository.dart           # memakai model AppUser
        │   └── presentation/
        │       ├── staff_list_controller.dart
        │       ├── staff_list_screen.dart
        │       └── staff_form_screen.dart
        ├── outlets/
        │   ├── data/
        │   │   ├── outlet_repository.dart
        │   │   └── models/
        │   │       └── outlet.dart
        │   └── presentation/
        │       ├── outlets_provider.dart
        │       ├── outlets_screen.dart
        │       ├── outlet_form_screen.dart
        │       └── widgets/
        │           └── outlet_filter_dropdown.dart # dipakai dashboard, order, layanan (owner, >1 outlet)
        └── settings/
            └── presentation/
                ├── settings_screen.dart
                ├── profile_screen.dart
                └── change_password_screen.dart
```

---

## 5. Arsitektur & Konvensi

### 5.1 Model

- Kelas immutable (`final` fields, constructor `const` bila memungkinkan), factory `fromJson(Map<String, dynamic>)`, dan `toJson()` hanya jika dikirim ke server. Tulis manual.
- `copyWith` hanya untuk model yang dipakai sebagai state form (`OrderDraft`, `OrderDraftItem`).
- Enum dengan `final String value` + `static X fromValue(String)`; nilai harus sama persis dengan API.
- Angka desimal dari API dibaca sebagai `num` lalu `.toDouble()`. Uang dibaca sebagai `int`.
- Waktu: `DateTime.parse(...).toLocal()`.

### 5.2 Riverpod 3 (tanpa codegen)

| Kebutuhan | Pola |
|---|---|
| Dependency (Dio, storage, repository) | `Provider` |
| Data sekali ambil berparameter (detail order) | `FutureProvider.autoDispose.family` |
| List dengan filter & pagination | `AsyncNotifierProvider.autoDispose` dengan method `refresh()`, `loadMore()`, `setFilter()` |
| Auth, tema, bahasa | `AsyncNotifierProvider` / `NotifierProvider` (bukan autoDispose) |
| State form | `NotifierProvider.autoDispose` |

- Jangan memakai `StateProvider` / `StateNotifierProvider` (legacy).
- Setelah mutasi (buat/edit/hapus order, ubah status/bayar), panggil `ref.invalidate` pada list order, detail order terkait, dan dashboard.
- Widget memakai `ConsumerWidget` / `ConsumerStatefulWidget`. Controller tidak memegang `BuildContext`.
- Error dari repository dilempar sebagai `ApiException`; UI menampilkan lewat `errorMessage(context, error)` (snackbar untuk aksi, `ErrorView` + tombol coba lagi untuk pemuatan data).

### 5.3 Repository

- Satu repository per fitur, menerima `Dio`, mengembalikan model (bukan `Response`).
- Memetakan `DioException` → `ApiException` (gunakan `code` dari envelope error; timeout/tanpa koneksi → kode lokal `NETWORK_ERROR`).

---

## 6. Networking & Auth

- `AppConfig.apiBaseUrl` = `String.fromEnvironment('API_BASE_URL')`; base URL Dio = `$apiBaseUrl/api/v1`. Timeout connect 15 detik, receive 20 detik.
- `LocaleInterceptor` menambahkan `Accept-Language` sesuai locale aplikasi aktif (`id`/`en`).
- Endpoint publik (`/auth/setup-status`, `/auth/register-owner`, `/auth/login`, `/auth/refresh`, `/auth/forgot-password`, `/auth/reset-password`, `/auth/logout`) tidak memakai `AuthInterceptor`: tanpa header Bearer dan tanpa logika refresh.
- `AuthInterceptor` (`QueuedInterceptor`, untuk endpoint selain di atas):
  1. Tambahkan `Authorization: Bearer <access_token>` jika ada.
  2. Pada respons `401` dengan `code = TOKEN_EXPIRED`: jalankan **satu** proses refresh (gunakan satu `Future` bersama agar request paralel tidak memicu refresh ganda) memakai Dio polos tanpa interceptor ke `POST /auth/refresh`.
  3. Berhasil → simpan token baru, ulangi request asli sekali.
  4. Gagal (`INVALID_REFRESH_TOKEN`, `ACCOUNT_INACTIVE`, dll) → hapus token, set auth state `Unauthenticated` (router otomatis ke login).
- `TokenStorage` menyimpan `access_token`, `refresh_token`, dan waktu kedaluwarsanya di `flutter_secure_storage`.
- `AuthController` (`AsyncNotifier<AuthState>`):
  - `build()`: baca token; jika ada panggil `GET /me` → `Authenticated(user)`. Gagal karena auth (401/403) → hapus token → `Unauthenticated`. Gagal karena jaringan/timeout/5xx → token **tidak** dihapus; `build()` melempar error sehingga splash menampilkan `ErrorView` dengan tombol coba lagi.
  - `applySession(AuthSession)` menyimpan token ke `TokenStorage` dan mengubah state menjadi `Authenticated`; dipakai oleh `login`, `registerOwner`, dan Ubah Password (server mencabut semua refresh token lama dan mengembalikan sesi baru).
  - `login`, `registerOwner`, `logout` (panggil `/auth/logout` lalu hapus token walau request gagal), `updateUser` (setelah edit profil).
- Peran dan outlet user diambil dari `AppUser` (`role`, `outlet`).

---

## 7. Routing (go_router)

| Path | Screen | Akses |
|---|---|---|
| `/splash` | SplashScreen | semua |
| `/login` | LoginScreen | belum login |
| `/register-owner` | RegisterOwnerScreen | belum login & `owner_exists = false` |
| `/forgot-password` | ForgotPasswordScreen | belum login |
| `/reset-password` | ResetPasswordScreen (`extra`: email) | belum login |
| `/dashboard` | DashboardScreen (tab 1) | login |
| `/orders` | OrdersListScreen (tab 2) | login |
| `/orders/new` | OrderFormScreen (mode buat) | login |
| `/orders/:id` | OrderDetailScreen | login |
| `/orders/:id/edit` | OrderFormScreen (mode edit) | owner |
| `/settings` | SettingsScreen (tab 3) | login |
| `/settings/profile` | ProfileScreen | login |
| `/settings/change-password` | ChangePasswordScreen | login |
| `/settings/services` | ServicesScreen | owner |
| `/settings/services/new`, `/settings/services/:id` | ServiceFormScreen | owner |
| `/settings/customers` | CustomersScreen | owner |
| `/settings/customers/:id` | CustomerEditScreen | owner |
| `/settings/staff` | StaffListScreen | owner |
| `/settings/staff/new`, `/settings/staff/:id` | StaffFormScreen | owner |
| `/settings/outlets` | OutletsScreen | owner |
| `/settings/outlets/new`, `/settings/outlets/:id` | OutletFormScreen | owner |

- Tab utama memakai `StatefulShellRoute.indexedStack` + `MainShell` (`NavigationBar`), sehingga state tiap tab terjaga. Layar detail di atas tab (mis. `/settings/profile`, `/settings/change-password`, dan layar kelola/form order) memakai `parentNavigatorKey` = root navigator, sehingga `NavigationBar` tersembunyi saat layar itu terbuka.
- `redirect`:
  - Auth masih loading → `/splash`.
  - Belum login & bukan rute auth → `/login`.
  - Sudah login & berada di rute auth/splash → `/dashboard`.
  - Staff membuka rute owner → `/dashboard` (daftar prefix di `AppRoutes.ownerOnlyPrefixes` + pola `/orders/:id/edit`).
- `refreshListenable` = `RouterRefreshListenable` yang mendengarkan `authControllerProvider`.

---

## 8. Lokalisasi

`l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_id.arb
output-localization-file: app_localizations.dart
output-dir: lib/l10n/gen
nullable-getter: false
```

- Bahasa didukung: `id` (template) dan `en`. Kedua file ARB **harus** memiliki key yang sama persis.
- Penamaan key camelCase berprefix fitur: `loginTitle`, `orderStatusReceived`, `dashboardRange24h`, `errorInvalidCredentials`, dst. Gunakan placeholder ICU untuk nilai dinamis dan plural (mis. `ordersCount`).
- Setiap kode error di ARCHITECTURE.md §8.1 + `NETWORK_ERROR` punya key `error<NamaKode>`; kode tidak dikenal → `errorUnknown`.
- Label enum (status, pembayaran, kecepatan, kategori, unit) juga dari ARB, lewat extension `label(BuildContext)` pada setiap enum.
- Preferensi bahasa (`AppLanguagePreference`): `system` (default), `id`, `en`. Disimpan di `shared_preferences`.
  - `system`: pakai bahasa perangkat jika `id` atau `en`, selain itu `id`.
  - Nilai `MaterialApp.locale` = `null` untuk `system` (gunakan `localeResolutionCallback` dengan fallback `id`), atau `Locale('id')`/`Locale('en')`.

Teks penting (contoh nilai id / en):

| Konsep | id | en |
|---|---|---|
| Cuci Setrika / Setrika / Cuci Lipat / Satuan | Cuci Setrika / Setrika / Cuci Lipat / Satuan | Wash & Iron / Iron Only / Wash & Fold / Unit Items |
| Reguler / Express | Reguler / Express | Regular / Express |
| Status | Diterima / Diproses / Selesai / Diambil | Received / Processing / Ready / Picked Up |
| Pembayaran | Belum Lunas / Lunas | Unpaid / Paid |

Catatan: nama layanan (mis. "Bed Cover") adalah data dari server dan **tidak** diterjemahkan.

---

## 9. Tema

- Material 3, `ColorScheme.fromSeed(seedColor: Color(0xFF0277BD))` untuk light & dark.
- `ThemeData` konsisten: input `OutlineInputBorder` radius 12, card radius 12, `FilledButton` sebagai tombol utama, `NavigationBar` di shell.
- Warna status didefinisikan sekali di `app_theme.dart` lewat satu `ThemeExtension` kecil `StatusColors` (versi light & dark), lalu dipakai chip/timeline lewat `Theme.of(context).extension<StatusColors>()`. Jangan menulis hex warna di widget. Pemetaan: received → `secondaryContainer`, processing → `tertiaryContainer`, done → `primaryContainer`, picked_up → `surfaceContainerHighest`, unpaid → `errorContainer`, paid → hijau (didefinisikan di extension untuk light & dark).
- Preferensi tema (`AppThemePreference`): `system` (default), `light`, `dark` → `ThemeMode`. Disimpan di `shared_preferences` dan diterapkan tanpa restart.
- Pastikan semua layar terbaca baik di mode gelap (tidak ada warna teks/latar hard-coded).

---

## 10. Format & Input

- Mata uang: selalu `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)` → `Rp 12.000`, apa pun bahasa aplikasinya.
- Kuantitas & tanggal: ikut locale aplikasi (`id`: `2,5 kg`, `27 Okt 2026 15.12`; `en`: `2.5 kg`, `Oct 27, 2026 3:12 PM`). Tampilkan maksimal 2 desimal tanpa nol berlebih (`3 kg`, `2,5 kg`).
- Input desimal (kg, panjang, lebar): `TextInputType.numberWithOptions(decimal: true)`, terima `,` dan `.`, batasi 2 desimal lewat `TextInputFormatter`, kirim ke API sebagai `double`.
- Input pcs: bilangan bulat dengan tombol stepper − / +.
- Nomor HP: `TextInputType.phone`, opsional. Tampilkan apa adanya dari server.
- Tombol aksi menampilkan loading dan nonaktif selama request berjalan (cegah submit ganda).

---

## 11. Spesifikasi Layar

### 11.1 Auth

**Splash** — logo + indikator loading selama `AuthController` memeriksa sesi.

**Login** — field email & password (toggle lihat password), tombol Masuk, tautan Lupa Password. Tombol **Daftar sebagai Owner** hanya tampil jika `GET /auth/setup-status` → `owner_exists = false`. Pesan error dari kode (`INVALID_CREDENTIALS`, `ACCOUNT_INACTIVE`, `RATE_LIMITED`).

**Register Owner** — nama, email, password, konfirmasi password, nama outlet, kode outlet (default `JL`, otomatis kapital, 2–5 karakter), alamat & telepon outlet (opsional). Sukses → langsung masuk dashboard.

**Lupa Password** — field email → kirim → pindah ke Reset Password membawa email.

**Reset Password** — input OTP 6 digit (angka saja), password baru + konfirmasi, tombol **Kirim ulang kode** dengan hitung mundur dari `retry_after_seconds`. Sukses → kembali ke login dengan snackbar sukses. Tangani `OTP_INVALID`, `OTP_EXPIRED`, `OTP_TOO_MANY_ATTEMPTS`.

Validasi password di client sama dengan server: minimal 8 karakter, ada huruf dan angka.

### 11.2 Shell

`NavigationBar` 3 tab: **Dashboard**, **Order**, **Pengaturan**. FAB **Order Baru** ada di layar Order (bukan di shell).

### 11.3 Dashboard

- AppBar: judul + `OutletFilterDropdown` (owner, jika > 1 outlet; opsi "Semua outlet").
- `RangeSelector`: baris `ChoiceChip` yang bisa di-scroll horizontal (6 opsi terlalu sempit untuk `SegmentedButton` di layar kecil): 1J · 24J · 7H · 30H · 1T · Semua (en: 1h · 24h · 7d · 30d · 1y · All). Nilai API: `1h`, `24h`, `7d`, `30d`, `1y`, `all`. Default `24h`. Enum `DashboardBucket` mendukung `5m`, `hour`, `day`, `month`, `year`.
- **Kartu operasional** (kondisi saat ini): Sedang diproses, Siap diambil, Belum lunas (+ nominal untuk owner).
- **Kartu ringkasan** (sesuai range): Jumlah order, Total kg, Total pcs, Total m², Pendapatan (owner saja; tampilkan juga lunas vs belum lunas).
- **Grafik** (`fl_chart` `BarChart`): toggle metrik Order / Kg / Pendapatan (Pendapatan hanya owner). Label sumbu X sesuai bucket: `5m`/`hour` → `HH:mm`, `day` → `dd/MM`, `month` → nama bulan singkat (tambahkan 2 digit tahun pada range `all`, mis. `Okt 26`), `year` → 4 digit tahun. Tooltip menampilkan nilai terformat. Tampilkan label sumbu X secara selang-seling jika titik > 12.
- **Per kategori**: 4 baris (Cuci Setrika, Setrika, Cuci Lipat, Satuan) dengan jumlah order, kuantitas (kg untuk 3 kategori kiloan; untuk Satuan **jangan** tampilkan `quantity` karena server menjumlahkan pcs dan m² jadi satu angka, cukup jumlah order dan pendapatan — rinciannya ada di bagian per jenis satuan), progress bar proporsi order, pendapatan (owner).
- **Per jenis satuan**: daftar layanan satuan (Bed Cover, Boneka, Karpet, …) dengan kuantitas + unit, jumlah order, pendapatan (owner). Sembunyikan bagian ini jika kosong.
- **Per status**: 4 chip dengan jumlah.
- Pull-to-refresh. Kondisi kosong yang jelas jika tidak ada order dalam rentang.
- Untuk staff, UI tidak boleh menampilkan placeholder pendapatan; field memang tidak dikirim server.

### 11.4 Daftar Order

- Kolom pencarian (debounce 400 ms) untuk nomor order / nama pelanggan.
- Filter chip status: Semua, Diterima, Diproses, Selesai, Diambil. Filter bayar: Semua, Lunas, Belum Lunas. `OutletFilterDropdown` untuk owner (> 1 outlet).
- Infinite scroll (20 per halaman) + pull-to-refresh.
- Tile: nomor order, nama pelanggan, total, chip status, chip bayar, estimasi selesai (warna `error` jika sudah lewat dan status belum `done`/`picked_up`), waktu masuk relatif.
- FAB **Order Baru** → `/orders/new`.

### 11.5 Form Order (buat & edit)

Bagian dari atas ke bawah:

1. **Outlet** — dropdown hanya untuk owner dengan > 1 outlet aktif; jika hanya 1, otomatis dipilih dan disembunyikan.
2. **Pelanggan** — `CustomerAutocompleteField`: ketik nama → `GET /customers?search=` (debounce 300 ms, min 1 karakter, 10 hasil) menampilkan nama + no. HP. Opsi terakhir **"Tambah pelanggan baru: {nama}"** memunculkan field No. HP (opsional). Memilih pelanggan lama menampilkan no. HP-nya (read-only) dan tombol ganti.
3. **Kecepatan** — `SegmentedButton` Reguler / Express. Tampilkan estimasi selesai (berdasarkan durasi terpanjang item terpilih).
4. **Kiloan** — satu baris per layanan kiloan aktif (Cuci Setrika, Setrika, Cuci Lipat): field kg + harga/kg sesuai kecepatan. Jika `0 < kg < min_quantity` tampilkan helper "Ditagih {min} kg".
5. **Satuan** — tombol **Tambah item satuan** membuka `UnitItemPickerSheet` (daftar layanan satuan aktif):
   - `piece` → jumlah dengan stepper.
   - `sqm` → field panjang (m) & lebar (m), luas dihitung otomatis.
   - Item yang sudah ditambahkan tampil sebagai daftar yang bisa diubah / dihapus. Layanan satuan yang sama boleh ditambahkan berkali-kali.
6. **Catatan** (opsional, maks 500 karakter).
7. **Sudah Lunas** — switch (hanya mode buat).

`OrderTotalBar` menempel di bawah: pratinjau total + tombol Simpan. Pratinjau dihitung oleh `order_pricing_preview.dart` dengan rumus yang sama seperti server (BACKEND.md §8.1). Nilai yang ditampilkan setelah simpan **selalu** dari respons server.

Validasi: nama pelanggan wajib; minimal 1 item dengan kuantitas > 0. Sukses buat → ganti ke `/orders/:id` dengan snackbar. Mode edit (owner) memuat data order, menyembunyikan switch Lunas, dan memberi catatan bahwa harga dihitung ulang dengan harga terbaru.

### 11.6 Detail Order

- Header: nomor order, outlet (owner), waktu masuk, dibuat oleh.
- Pelanggan: nama, no. HP.
- `StatusTimeline`: 4 tahap dengan waktu masing-masing; estimasi selesai.
- `OrderItemsTable`: nama layanan, kuantitas (mis. `2,5 kg · ditagih 3 kg`, `2 × 2,5 m = 5 m²`, `1 pcs`), harga satuan, subtotal; total di bawah.
- Status bayar + waktu lunas.
- `OrderActionsBar`:
  - Tombol utama tahap berikutnya: **Mulai Proses** → **Tandai Selesai** → **Tandai Diambil**.
  - Jika menekan Tandai Diambil saat belum lunas → dialog "Pelanggan sudah membayar?" → jika ya, panggil `/payment` (paid) lalu `/status` (picked_up).
  - Tombol **Tandai Lunas** jika belum lunas.
  - Menu owner (⋮): Edit (hanya jika belum lunas & belum diambil), Ubah status (pilih status sebelumnya), Batalkan Lunas, Hapus (dengan konfirmasi).
- Setiap aksi menampilkan konfirmasi singkat lewat snackbar dan me-refresh data.

### 11.7 Pengaturan

- **Akun**: Profil (ubah nama, tampilkan email & peran), Ubah Password.
- **Tampilan**: Tema (Ikuti sistem / Terang / Gelap), Bahasa (Ikuti sistem / Indonesia / English).
- **Kelola** (owner saja): Layanan & Harga, Pelanggan, Staff, Outlet.
- **Keluar** (dengan konfirmasi).

### 11.8 Layar Owner

**Layanan & Harga** — `OutletFilterDropdown` (jika > 1 outlet). Dua seksi:

- *Kiloan*: 3 layanan sistem; tap → form edit nama, harga reguler & express, durasi reguler & express (hari), minimal kg, aktif.
- *Satuan*: daftar dengan switch aktif; tap → edit; menu hapus (konfirmasi). FAB **Tambah satuan** → form: nama, unit (pcs / m², tidak bisa diubah setelah dibuat), harga reguler & express, durasi reguler & express, aktif.
- Layanan nonaktif ditampilkan redup dengan label "Nonaktif".
- Penyimpangan F4: form tambah satuan tidak memiliki switch aktif (layanan baru selalu aktif; switch hanya saat ubah). Form ubah layanan membaca layanan dari daftar `GET /services` (tidak ada `GET /services/:id`); rute ubah membawa `outletId` sebagai query parameter. Ubah/tambah mengirim hanya field yang berubah. Menonaktifkan layanan kiloan, outlet, atau staff meminta konfirmasi.

**Pelanggan** — daftar + pencarian; tap → edit nama & no. HP.

**Staff** — daftar (nama, email, outlet, status aktif). FAB tambah → form nama, email, password, outlet. Edit: nama, outlet, aktif; tombol **Reset password** (dialog password baru).

**Outlet** — daftar (kode, nama, aktif). Tambah: kode (kapital, 2–5, tidak bisa diubah), nama, alamat, telepon. Edit: nama, alamat, telepon, aktif.

---

## 12. UI Berdasarkan Peran

- Staff tidak melihat menu Kelola, menu ⋮ owner di detail order, filter outlet, maupun angka pendapatan di dashboard.
- Penyembunyian di UI hanya untuk kenyamanan; keamanan tetap ditegakkan server.
- Gunakan helper `isOwner` dari `AppUser` (bukan perbandingan string tersebar).

---

## 13. Menjalankan & Build

```bash
# Android emulator ke server lokal
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# iOS simulator ke server lokal
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# Release
flutter build appbundle --release --dart-define=API_BASE_URL=https://<project>.vercel.app
flutter build ipa --release --dart-define=API_BASE_URL=https://<project>.vercel.app
```

Jika `API_BASE_URL` kosong, tampilkan error konfigurasi yang jelas saat startup (jangan crash diam-diam).

---

## 14. Fase Implementasi

Setiap fase: `dart format .` dan `flutter analyze` tanpa issue, aplikasi berjalan di emulator Android dan simulator iOS, tanpa file test. Akhiri fase dengan ringkasan file (path lengkap) + cara mencoba manual, lalu **berhenti**.

### F1 — Setup Proyek & Core

- `flutter create` (§2.1), identifier, minSdk 34, iOS 18, konfigurasi manifest/Info.plist, orientasi portrait.
- Dependency §3, hapus `test/` & `flutter_test`, migrasi ke `material_ui`.
- `core/` lengkap: config, network, storage, theme, l10n (ARB awal id/en), utils, widgets, router kerangka.
- **Selesai jika**: app tampil dengan splash → layar login placeholder, tema & bahasa mengikuti sistem.

### F2 — Auth

- Semua layar & alur §11.1, `AuthController`, `AuthInterceptor` dengan refresh single-flight, redirect router.
- **Selesai jika**: register owner, login, logout, sesi bertahan setelah app ditutup, refresh token otomatis, lupa/reset password dengan OTP berjalan.

### F3 — Shell & Pengaturan

- `MainShell` 3 tab, Settings, Profil, Ubah Password, preferensi tema & bahasa tersimpan.
- **Selesai jika**: ganti tema/bahasa langsung berlaku dan tetap setelah restart; menu Kelola hanya tampil untuk owner.

### F4 — Fitur Owner

- Outlet, Layanan & Harga, Staff, Pelanggan (§11.8), `OutletFilterDropdown`.
- **Selesai jika**: owner dapat mengubah harga kiloan, menambah/nonaktifkan/menghapus satuan, membuat staff yang kemudian bisa login.

### F5 — Order

- Form order (§11.5) termasuk autocomplete pelanggan, daftar order (§11.4), detail & aksi (§11.6), edit & hapus owner.
- **Selesai jika**: order campuran kiloan + pcs + m² tersimpan dengan total sama dengan pratinjau, minimum 3 kg diterapkan, alur status & pembayaran sesuai peran.

### F6 — Dashboard

- Semua komponen §11.3 dengan 5 range dan filter outlet.
- **Selesai jika**: grafik & ringkasan sesuai data, staff tidak melihat pendapatan, tampil baik di mode terang & gelap.

### F7 — Polishing & Release

- Lengkapi & samakan key ARB id/en, empty/error state di semua layar, aksesibilitas dasar (label semantik pada ikon tombol), nama & ikon aplikasi, cek layout di layar kecil.
- Konfigurasi build release Android (signing via `key.properties` yang di-gitignore) dan catatan langkah build iOS.
- **Selesai jika**: `flutter build appbundle --release` dan `flutter build ipa --release` berhasil.