// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Jesi Laundry';

  @override
  String get splashLoading => 'Memuat…';

  @override
  String get loginTitle => 'Masuk';

  @override
  String get configErrorTitle => 'Konfigurasi belum lengkap';

  @override
  String get configErrorBody =>
      'API_BASE_URL belum diatur. Jalankan aplikasi dengan --dart-define=API_BASE_URL=<alamat server>.';

  @override
  String get errorBadRequest => 'Permintaan tidak dapat diproses.';

  @override
  String get errorValidationError =>
      'Data yang dimasukkan belum valid. Periksa kembali isian Anda.';

  @override
  String get errorUnauthorized => 'Sesi tidak valid. Silakan masuk kembali.';

  @override
  String get errorTokenExpired => 'Sesi telah berakhir. Silakan masuk kembali.';

  @override
  String get errorInvalidRefreshToken =>
      'Sesi telah berakhir. Silakan masuk kembali.';

  @override
  String get errorInvalidCredentials => 'Email atau password salah.';

  @override
  String get errorAccountInactive => 'Akun Anda dinonaktifkan. Hubungi owner.';

  @override
  String get errorForbidden => 'Anda tidak memiliki akses untuk tindakan ini.';

  @override
  String get errorNotFound => 'Data tidak ditemukan.';

  @override
  String get errorEmailTaken => 'Email sudah digunakan.';

  @override
  String get errorOwnerAlreadyExists => 'Owner sudah terdaftar.';

  @override
  String get errorOutletCodeTaken => 'Kode outlet sudah digunakan.';

  @override
  String get errorServiceNameTaken => 'Nama layanan sudah ada di outlet ini.';

  @override
  String get errorOutletInactive =>
      'Outlet nonaktif dan tidak dapat menerima order.';

  @override
  String get errorServiceInactive =>
      'Layanan nonaktif, dihapus, atau bukan milik outlet order.';

  @override
  String get errorDuplicateKiloService =>
      'Layanan kiloan yang sama tidak boleh muncul lebih dari sekali dalam satu order.';

  @override
  String get errorInvalidStatusTransition =>
      'Perpindahan status tidak diizinkan.';

  @override
  String get errorPaymentRequired =>
      'Order harus lunas sebelum ditandai diambil.';

  @override
  String get errorOrderNotEditable =>
      'Order yang sudah lunas atau diambil tidak dapat diedit.';

  @override
  String get errorSystemServiceNotDeletable =>
      'Layanan kiloan bawaan tidak dapat dihapus.';

  @override
  String get errorOtpInvalid => 'Kode OTP salah.';

  @override
  String get errorOtpExpired => 'Kode OTP sudah kedaluwarsa. Minta kode baru.';

  @override
  String get errorOtpTooManyAttempts =>
      'Terlalu banyak percobaan. Minta kode baru.';

  @override
  String get errorRateLimited =>
      'Terlalu banyak permintaan. Coba lagi sebentar lagi.';

  @override
  String get errorInternalError =>
      'Terjadi kesalahan pada server. Coba lagi nanti.';

  @override
  String get errorNetworkError =>
      'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';

  @override
  String get errorUnknown => 'Terjadi kesalahan yang tidak diketahui.';

  @override
  String get serviceCategoryWashIron => 'Cuci Setrika';

  @override
  String get serviceCategoryIronOnly => 'Setrika';

  @override
  String get serviceCategoryWashFold => 'Cuci Lipat';

  @override
  String get serviceCategoryUnit => 'Satuan';

  @override
  String get serviceSpeedRegular => 'Reguler';

  @override
  String get serviceSpeedExpress => 'Express';

  @override
  String get orderStatusReceived => 'Diterima';

  @override
  String get orderStatusProcessing => 'Diproses';

  @override
  String get orderStatusDone => 'Selesai';

  @override
  String get orderStatusPickedUp => 'Diambil';

  @override
  String get paymentStatusUnpaid => 'Belum Lunas';

  @override
  String get paymentStatusPaid => 'Lunas';

  @override
  String get pricingUnitPiece => 'pcs';

  @override
  String get pricingUnitSqm => 'm²';

  @override
  String get unitKg => 'kg';

  @override
  String get unitPcs => 'pcs';

  @override
  String get unitSqm => 'm²';

  @override
  String get themeSystem => 'Ikuti sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get languageSystem => 'Ikuti sistem';

  @override
  String get languageIndonesian => 'Indonesia';

  @override
  String get languageEnglish => 'English';

  @override
  String get commonRetry => 'Coba lagi';

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonConfirm => 'Ya';

  @override
  String get commonEmptyTitle => 'Belum ada data';

  @override
  String get validationRequired => 'Wajib diisi';

  @override
  String get validationInvalidEmail => 'Format email tidak valid';

  @override
  String get validationPasswordTooShort => 'Password minimal 8 karakter';

  @override
  String get validationPasswordNeedsLetterAndDigit =>
      'Password harus mengandung huruf dan angka';

  @override
  String get validationPasswordMismatch => 'Konfirmasi password tidak sama';

  @override
  String get validationInvalidNumber => 'Angka tidak valid';

  @override
  String validationMinLength(int min) {
    return 'Minimal $min karakter';
  }

  @override
  String validationMaxLength(int max) {
    return 'Maksimal $max karakter';
  }

  @override
  String get splashSlowHint =>
      'Server mungkin sedang bangun. Mohon tunggu sebentar…';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Konfirmasi password';

  @override
  String get authNewPasswordLabel => 'Password baru';

  @override
  String get authNameLabel => 'Nama';

  @override
  String get authShowPassword => 'Tampilkan password';

  @override
  String get authHidePassword => 'Sembunyikan password';

  @override
  String get loginSubmit => 'Masuk';

  @override
  String get loginForgotPassword => 'Lupa password?';

  @override
  String get loginRegisterOwner => 'Daftar sebagai Owner';

  @override
  String get loginSessionExpired => 'Sesi berakhir, silakan masuk lagi';

  @override
  String get registerOwnerTitle => 'Daftar sebagai Owner';

  @override
  String get registerOwnerAccountSection => 'Akun owner';

  @override
  String get registerOwnerOutletSection => 'Outlet pertama';

  @override
  String get registerOwnerOutletNameLabel => 'Nama outlet';

  @override
  String get registerOwnerOutletCodeLabel => 'Kode outlet';

  @override
  String get registerOwnerOutletCodeHelper => '2–5 huruf atau angka';

  @override
  String get registerOwnerOutletAddressLabel => 'Alamat outlet (opsional)';

  @override
  String get registerOwnerOutletPhoneLabel => 'Telepon outlet (opsional)';

  @override
  String get registerOwnerSubmit => 'Daftar';

  @override
  String get forgotPasswordTitle => 'Lupa password';

  @override
  String get forgotPasswordBody =>
      'Masukkan email akun Anda. Jika terdaftar, kami akan mengirim kode verifikasi 6 digit.';

  @override
  String get forgotPasswordSubmit => 'Kirim kode';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String resetPasswordBody(String email) {
    return 'Masukkan kode 6 digit yang dikirim ke $email dan password baru Anda.';
  }

  @override
  String get resetPasswordOtpLabel => 'Kode OTP';

  @override
  String get resetPasswordResend => 'Kirim ulang kode';

  @override
  String resetPasswordResendIn(int seconds) {
    return 'Kirim ulang kode dalam $seconds dtk';
  }

  @override
  String get resetPasswordResent =>
      'Jika email terdaftar, kode baru telah dikirim.';

  @override
  String get resetPasswordSubmit => 'Reset password';

  @override
  String get resetPasswordSuccess => 'Password berhasil diubah. Silakan masuk.';

  @override
  String get userRoleOwner => 'Owner';

  @override
  String get userRoleStaff => 'Staff';

  @override
  String get validationPasswordTooLong =>
      'Password terlalu panjang (maksimal 72 byte)';

  @override
  String get validationOtpLength => 'Kode harus 6 digit';

  @override
  String get validationOutletCode => 'Kode outlet 2–5 huruf atau angka';

  @override
  String get validationServerInvalid => 'Isian tidak valid';

  @override
  String get dashboardPlaceholderTitle => 'Dashboard';

  @override
  String get dashboardPlaceholderNotice =>
      'Layar sementara. Dashboard lengkap menyusul.';

  @override
  String get dashboardPlaceholderRoleLabel => 'Peran';

  @override
  String get dashboardPlaceholderOutletLabel => 'Outlet';

  @override
  String get shellTabDashboard => 'Dashboard';

  @override
  String get shellTabOrders => 'Order';

  @override
  String get shellTabSettings => 'Pengaturan';

  @override
  String get ordersPlaceholderTitle => 'Order';

  @override
  String get ordersPlaceholderMessage => 'Fitur order segera tersedia';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsSectionAccount => 'Akun';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsChangePassword => 'Ubah Password';

  @override
  String get settingsSectionAppearance => 'Tampilan';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsSectionManage => 'Kelola';

  @override
  String get settingsManageServices => 'Layanan & Harga';

  @override
  String get settingsManageCustomers => 'Pelanggan';

  @override
  String get settingsManageStaff => 'Staff';

  @override
  String get settingsManageOutlets => 'Outlet';

  @override
  String get settingsLogout => 'Keluar';

  @override
  String get settingsLogoutConfirmTitle => 'Keluar dari akun?';

  @override
  String get settingsLogoutConfirmBody =>
      'Anda perlu masuk lagi untuk memakai aplikasi.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileRoleLabel => 'Peran';

  @override
  String get profileOutletLabel => 'Outlet';

  @override
  String get profileAllOutlets => 'Semua outlet';

  @override
  String get profileSave => 'Simpan';

  @override
  String get profileSaved => 'Profil berhasil disimpan';

  @override
  String get changePasswordTitle => 'Ubah Password';

  @override
  String get changePasswordCurrentLabel => 'Password saat ini';

  @override
  String get changePasswordSubmit => 'Ubah password';

  @override
  String get changePasswordCurrentWrong => 'Password saat ini salah';

  @override
  String get changePasswordSuccess => 'Password berhasil diubah';

  @override
  String get commonSearch => 'Cari';

  @override
  String get commonClear => 'Hapus teks';

  @override
  String get commonActive => 'Aktif';

  @override
  String get commonInactive => 'Nonaktif';

  @override
  String get commonSave => 'Simpan';

  @override
  String get commonDelete => 'Hapus';

  @override
  String get commonContinue => 'Lanjutkan';

  @override
  String commonDays(int days) {
    return '$days hari';
  }

  @override
  String validationRange(int min, int max) {
    return 'Isi angka $min–$max';
  }

  @override
  String get timeAgoJustNow => 'Baru saja';

  @override
  String timeAgoMinutes(int minutes) {
    return '$minutes menit lalu';
  }

  @override
  String timeAgoHours(int hours) {
    return '$hours jam lalu';
  }

  @override
  String timeAgoDays(int days) {
    return '$days hari lalu';
  }

  @override
  String get outletsTitle => 'Outlet';

  @override
  String get outletsAdd => 'Tambah outlet';

  @override
  String get outletsEmpty => 'Belum ada outlet';

  @override
  String get outletFormAddTitle => 'Tambah Outlet';

  @override
  String get outletFormEditTitle => 'Ubah Outlet';

  @override
  String get outletFormAddressLabel => 'Alamat (opsional)';

  @override
  String get outletFormPhoneLabel => 'Telepon (opsional)';

  @override
  String get outletFormCodeLocked => 'Kode tidak dapat diubah';

  @override
  String get outletFormCreated =>
      'Outlet dibuat. Katalog layanan default dibuat otomatis.';

  @override
  String get outletFormSaved => 'Outlet disimpan';

  @override
  String get outletDeactivateTitle => 'Nonaktifkan outlet?';

  @override
  String get outletDeactivateBody =>
      'Outlet nonaktif tidak dapat menerima order baru.';

  @override
  String get outletDeactivateConfirm => 'Nonaktifkan';

  @override
  String get outletFilterAll => 'Semua outlet';

  @override
  String get outletFilterTooltip => 'Pilih outlet';

  @override
  String get outletPickerLabel => 'Outlet';

  @override
  String get outletPickerTitle => 'Pilih outlet';

  @override
  String get servicesTitle => 'Layanan & Harga';

  @override
  String get servicesAddUnit => 'Tambah satuan';

  @override
  String get servicesSectionKilo => 'Kiloan';

  @override
  String get servicesSectionUnit => 'Satuan';

  @override
  String get servicesUnitEmpty => 'Belum ada layanan satuan';

  @override
  String get servicesBadgeSystem => 'Sistem';

  @override
  String get servicesDeleteTitle => 'Hapus layanan?';

  @override
  String servicesDeleteBody(String name) {
    return 'Layanan \"$name\" akan dihapus. Order lama tidak terpengaruh.';
  }

  @override
  String get servicesDeleted => 'Layanan dihapus';

  @override
  String get serviceFormAddTitle => 'Tambah Layanan Satuan';

  @override
  String get serviceFormEditTitle => 'Ubah Layanan';

  @override
  String get serviceFormNameLabel => 'Nama layanan';

  @override
  String get serviceFormUnitLabel => 'Satuan';

  @override
  String get serviceFormUnitLocked => 'Satuan tidak dapat diubah';

  @override
  String serviceFormRegularPriceLabel(String unit) {
    return 'Harga reguler (per $unit)';
  }

  @override
  String serviceFormExpressPriceLabel(String unit) {
    return 'Harga express (per $unit)';
  }

  @override
  String get serviceFormRegularDaysLabel => 'Durasi reguler (hari)';

  @override
  String get serviceFormExpressDaysLabel => 'Durasi express (hari)';

  @override
  String get serviceFormMinQuantityLabel => 'Minimal kuantitas (kg)';

  @override
  String get serviceFormMinQuantityHelper => '0 = tanpa minimum';

  @override
  String get serviceFormCreated => 'Layanan ditambahkan';

  @override
  String get serviceFormSaved => 'Layanan disimpan';

  @override
  String get serviceFormDeactivateKiloTitle => 'Nonaktifkan layanan?';

  @override
  String get serviceFormDeactivateKiloBody =>
      'Layanan nonaktif tidak dapat dipilih saat membuat order baru.';

  @override
  String get serviceFormDeactivateConfirm => 'Nonaktifkan';

  @override
  String get staffTitle => 'Staff';

  @override
  String get staffAdd => 'Tambah staff';

  @override
  String get staffSearchHint => 'Cari nama atau email';

  @override
  String get staffEmpty => 'Belum ada staff';

  @override
  String get staffFormAddTitle => 'Tambah Staff';

  @override
  String get staffFormEditTitle => 'Ubah Staff';

  @override
  String get staffFormCreated => 'Staff ditambahkan';

  @override
  String get staffFormSaved => 'Staff disimpan';

  @override
  String get staffSessionEndsTitle => 'Akhiri sesi staff?';

  @override
  String get staffSessionEndsBody =>
      'Sesi staff ini akan berakhir dan ia harus masuk lagi.';

  @override
  String get staffResetPassword => 'Reset password';

  @override
  String get staffResetPasswordTitle => 'Reset password staff';

  @override
  String get staffResetPasswordBody =>
      'Masukkan password baru. Semua sesi staff ini akan berakhir.';

  @override
  String get staffResetPasswordDone => 'Password staff direset';

  @override
  String get customersTitle => 'Pelanggan';

  @override
  String get customersSearchHint => 'Cari nama atau nomor HP';

  @override
  String get customersEmptyTitle => 'Belum ada pelanggan';

  @override
  String get customersEmptyMessage =>
      'Pelanggan muncul otomatis saat order dibuat.';

  @override
  String customersLastOrder(String when) {
    return 'Order terakhir: $when';
  }

  @override
  String get customerEditTitle => 'Ubah Pelanggan';

  @override
  String get customerEditSaved => 'Pelanggan disimpan';

  @override
  String get customerEditPhoneLabel => 'Nomor HP (opsional)';
}
