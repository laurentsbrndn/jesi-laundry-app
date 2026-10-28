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
  String get dashboardPlaceholderLogout => 'Keluar';

  @override
  String get dashboardPlaceholderLogoutConfirmTitle => 'Keluar dari akun?';

  @override
  String get dashboardPlaceholderLogoutConfirmBody =>
      'Anda perlu masuk lagi untuk memakai aplikasi.';
}
