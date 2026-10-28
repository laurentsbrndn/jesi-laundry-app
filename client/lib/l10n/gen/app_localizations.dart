import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appName.
  ///
  /// In id, this message translates to:
  /// **'Jesi Laundry'**
  String get appName;

  /// No description provided for @splashLoading.
  ///
  /// In id, this message translates to:
  /// **'Memuat…'**
  String get splashLoading;

  /// No description provided for @loginTitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get loginTitle;

  /// No description provided for @configErrorTitle.
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi belum lengkap'**
  String get configErrorTitle;

  /// No description provided for @configErrorBody.
  ///
  /// In id, this message translates to:
  /// **'API_BASE_URL belum diatur. Jalankan aplikasi dengan --dart-define=API_BASE_URL=<alamat server>.'**
  String get configErrorBody;

  /// No description provided for @errorBadRequest.
  ///
  /// In id, this message translates to:
  /// **'Permintaan tidak dapat diproses.'**
  String get errorBadRequest;

  /// No description provided for @errorValidationError.
  ///
  /// In id, this message translates to:
  /// **'Data yang dimasukkan belum valid. Periksa kembali isian Anda.'**
  String get errorValidationError;

  /// No description provided for @errorUnauthorized.
  ///
  /// In id, this message translates to:
  /// **'Sesi tidak valid. Silakan masuk kembali.'**
  String get errorUnauthorized;

  /// No description provided for @errorTokenExpired.
  ///
  /// In id, this message translates to:
  /// **'Sesi telah berakhir. Silakan masuk kembali.'**
  String get errorTokenExpired;

  /// No description provided for @errorInvalidRefreshToken.
  ///
  /// In id, this message translates to:
  /// **'Sesi telah berakhir. Silakan masuk kembali.'**
  String get errorInvalidRefreshToken;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In id, this message translates to:
  /// **'Email atau password salah.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorAccountInactive.
  ///
  /// In id, this message translates to:
  /// **'Akun Anda dinonaktifkan. Hubungi owner.'**
  String get errorAccountInactive;

  /// No description provided for @errorForbidden.
  ///
  /// In id, this message translates to:
  /// **'Anda tidak memiliki akses untuk tindakan ini.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In id, this message translates to:
  /// **'Data tidak ditemukan.'**
  String get errorNotFound;

  /// No description provided for @errorEmailTaken.
  ///
  /// In id, this message translates to:
  /// **'Email sudah digunakan.'**
  String get errorEmailTaken;

  /// No description provided for @errorOwnerAlreadyExists.
  ///
  /// In id, this message translates to:
  /// **'Owner sudah terdaftar.'**
  String get errorOwnerAlreadyExists;

  /// No description provided for @errorOutletCodeTaken.
  ///
  /// In id, this message translates to:
  /// **'Kode outlet sudah digunakan.'**
  String get errorOutletCodeTaken;

  /// No description provided for @errorServiceNameTaken.
  ///
  /// In id, this message translates to:
  /// **'Nama layanan sudah ada di outlet ini.'**
  String get errorServiceNameTaken;

  /// No description provided for @errorOutletInactive.
  ///
  /// In id, this message translates to:
  /// **'Outlet nonaktif dan tidak dapat menerima order.'**
  String get errorOutletInactive;

  /// No description provided for @errorServiceInactive.
  ///
  /// In id, this message translates to:
  /// **'Layanan nonaktif, dihapus, atau bukan milik outlet order.'**
  String get errorServiceInactive;

  /// No description provided for @errorDuplicateKiloService.
  ///
  /// In id, this message translates to:
  /// **'Layanan kiloan yang sama tidak boleh muncul lebih dari sekali dalam satu order.'**
  String get errorDuplicateKiloService;

  /// No description provided for @errorInvalidStatusTransition.
  ///
  /// In id, this message translates to:
  /// **'Perpindahan status tidak diizinkan.'**
  String get errorInvalidStatusTransition;

  /// No description provided for @errorPaymentRequired.
  ///
  /// In id, this message translates to:
  /// **'Order harus lunas sebelum ditandai diambil.'**
  String get errorPaymentRequired;

  /// No description provided for @errorOrderNotEditable.
  ///
  /// In id, this message translates to:
  /// **'Order yang sudah lunas atau diambil tidak dapat diedit.'**
  String get errorOrderNotEditable;

  /// No description provided for @errorSystemServiceNotDeletable.
  ///
  /// In id, this message translates to:
  /// **'Layanan kiloan bawaan tidak dapat dihapus.'**
  String get errorSystemServiceNotDeletable;

  /// No description provided for @errorOtpInvalid.
  ///
  /// In id, this message translates to:
  /// **'Kode OTP salah.'**
  String get errorOtpInvalid;

  /// No description provided for @errorOtpExpired.
  ///
  /// In id, this message translates to:
  /// **'Kode OTP sudah kedaluwarsa. Minta kode baru.'**
  String get errorOtpExpired;

  /// No description provided for @errorOtpTooManyAttempts.
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan. Minta kode baru.'**
  String get errorOtpTooManyAttempts;

  /// No description provided for @errorRateLimited.
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak permintaan. Coba lagi sebentar lagi.'**
  String get errorRateLimited;

  /// No description provided for @errorInternalError.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan pada server. Coba lagi nanti.'**
  String get errorInternalError;

  /// No description provided for @errorNetworkError.
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.'**
  String get errorNetworkError;

  /// No description provided for @errorUnknown.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan yang tidak diketahui.'**
  String get errorUnknown;

  /// No description provided for @serviceCategoryWashIron.
  ///
  /// In id, this message translates to:
  /// **'Cuci Setrika'**
  String get serviceCategoryWashIron;

  /// No description provided for @serviceCategoryIronOnly.
  ///
  /// In id, this message translates to:
  /// **'Setrika'**
  String get serviceCategoryIronOnly;

  /// No description provided for @serviceCategoryWashFold.
  ///
  /// In id, this message translates to:
  /// **'Cuci Lipat'**
  String get serviceCategoryWashFold;

  /// No description provided for @serviceCategoryUnit.
  ///
  /// In id, this message translates to:
  /// **'Satuan'**
  String get serviceCategoryUnit;

  /// No description provided for @serviceSpeedRegular.
  ///
  /// In id, this message translates to:
  /// **'Reguler'**
  String get serviceSpeedRegular;

  /// No description provided for @serviceSpeedExpress.
  ///
  /// In id, this message translates to:
  /// **'Express'**
  String get serviceSpeedExpress;

  /// No description provided for @orderStatusReceived.
  ///
  /// In id, this message translates to:
  /// **'Diterima'**
  String get orderStatusReceived;

  /// No description provided for @orderStatusProcessing.
  ///
  /// In id, this message translates to:
  /// **'Diproses'**
  String get orderStatusProcessing;

  /// No description provided for @orderStatusDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get orderStatusDone;

  /// No description provided for @orderStatusPickedUp.
  ///
  /// In id, this message translates to:
  /// **'Diambil'**
  String get orderStatusPickedUp;

  /// No description provided for @paymentStatusUnpaid.
  ///
  /// In id, this message translates to:
  /// **'Belum Lunas'**
  String get paymentStatusUnpaid;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get paymentStatusPaid;

  /// No description provided for @pricingUnitPiece.
  ///
  /// In id, this message translates to:
  /// **'pcs'**
  String get pricingUnitPiece;

  /// No description provided for @pricingUnitSqm.
  ///
  /// In id, this message translates to:
  /// **'m²'**
  String get pricingUnitSqm;

  /// No description provided for @unitKg.
  ///
  /// In id, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitPcs.
  ///
  /// In id, this message translates to:
  /// **'pcs'**
  String get unitPcs;

  /// No description provided for @unitSqm.
  ///
  /// In id, this message translates to:
  /// **'m²'**
  String get unitSqm;

  /// No description provided for @themeSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get themeDark;

  /// No description provided for @languageSystem.
  ///
  /// In id, this message translates to:
  /// **'Ikuti sistem'**
  String get languageSystem;

  /// No description provided for @languageIndonesian.
  ///
  /// In id, this message translates to:
  /// **'Indonesia'**
  String get languageIndonesian;

  /// No description provided for @languageEnglish.
  ///
  /// In id, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @commonRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In id, this message translates to:
  /// **'Ya'**
  String get commonConfirm;

  /// No description provided for @commonEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data'**
  String get commonEmptyTitle;

  /// No description provided for @validationRequired.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi'**
  String get validationRequired;

  /// No description provided for @validationInvalidEmail.
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid'**
  String get validationInvalidEmail;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In id, this message translates to:
  /// **'Password minimal 8 karakter'**
  String get validationPasswordTooShort;

  /// No description provided for @validationPasswordNeedsLetterAndDigit.
  ///
  /// In id, this message translates to:
  /// **'Password harus mengandung huruf dan angka'**
  String get validationPasswordNeedsLetterAndDigit;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password tidak sama'**
  String get validationPasswordMismatch;

  /// No description provided for @validationInvalidNumber.
  ///
  /// In id, this message translates to:
  /// **'Angka tidak valid'**
  String get validationInvalidNumber;

  /// No description provided for @validationMinLength.
  ///
  /// In id, this message translates to:
  /// **'Minimal {min} karakter'**
  String validationMinLength(int min);

  /// No description provided for @validationMaxLength.
  ///
  /// In id, this message translates to:
  /// **'Maksimal {max} karakter'**
  String validationMaxLength(int max);

  /// No description provided for @splashSlowHint.
  ///
  /// In id, this message translates to:
  /// **'Server mungkin sedang bangun. Mohon tunggu sebentar…'**
  String get splashSlowHint;

  /// No description provided for @authEmailLabel.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In id, this message translates to:
  /// **'Password baru'**
  String get authNewPasswordLabel;

  /// No description provided for @authNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get authNameLabel;

  /// No description provided for @authShowPassword.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan password'**
  String get authHidePassword;

  /// No description provided for @loginSubmit.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get loginSubmit;

  /// No description provided for @loginForgotPassword.
  ///
  /// In id, this message translates to:
  /// **'Lupa password?'**
  String get loginForgotPassword;

  /// No description provided for @loginRegisterOwner.
  ///
  /// In id, this message translates to:
  /// **'Daftar sebagai Owner'**
  String get loginRegisterOwner;

  /// No description provided for @loginSessionExpired.
  ///
  /// In id, this message translates to:
  /// **'Sesi berakhir, silakan masuk lagi'**
  String get loginSessionExpired;

  /// No description provided for @registerOwnerTitle.
  ///
  /// In id, this message translates to:
  /// **'Daftar sebagai Owner'**
  String get registerOwnerTitle;

  /// No description provided for @registerOwnerAccountSection.
  ///
  /// In id, this message translates to:
  /// **'Akun owner'**
  String get registerOwnerAccountSection;

  /// No description provided for @registerOwnerOutletSection.
  ///
  /// In id, this message translates to:
  /// **'Outlet pertama'**
  String get registerOwnerOutletSection;

  /// No description provided for @registerOwnerOutletNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama outlet'**
  String get registerOwnerOutletNameLabel;

  /// No description provided for @registerOwnerOutletCodeLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode outlet'**
  String get registerOwnerOutletCodeLabel;

  /// No description provided for @registerOwnerOutletCodeHelper.
  ///
  /// In id, this message translates to:
  /// **'2–5 huruf atau angka'**
  String get registerOwnerOutletCodeHelper;

  /// No description provided for @registerOwnerOutletAddressLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat outlet (opsional)'**
  String get registerOwnerOutletAddressLabel;

  /// No description provided for @registerOwnerOutletPhoneLabel.
  ///
  /// In id, this message translates to:
  /// **'Telepon outlet (opsional)'**
  String get registerOwnerOutletPhoneLabel;

  /// No description provided for @registerOwnerSubmit.
  ///
  /// In id, this message translates to:
  /// **'Daftar'**
  String get registerOwnerSubmit;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In id, this message translates to:
  /// **'Lupa password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordBody.
  ///
  /// In id, this message translates to:
  /// **'Masukkan email akun Anda. Jika terdaftar, kami akan mengirim kode verifikasi 6 digit.'**
  String get forgotPasswordBody;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In id, this message translates to:
  /// **'Kirim kode'**
  String get forgotPasswordSubmit;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In id, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordBody.
  ///
  /// In id, this message translates to:
  /// **'Masukkan kode 6 digit yang dikirim ke {email} dan password baru Anda.'**
  String resetPasswordBody(String email);

  /// No description provided for @resetPasswordOtpLabel.
  ///
  /// In id, this message translates to:
  /// **'Kode OTP'**
  String get resetPasswordOtpLabel;

  /// No description provided for @resetPasswordResend.
  ///
  /// In id, this message translates to:
  /// **'Kirim ulang kode'**
  String get resetPasswordResend;

  /// No description provided for @resetPasswordResendIn.
  ///
  /// In id, this message translates to:
  /// **'Kirim ulang kode dalam {seconds} dtk'**
  String resetPasswordResendIn(int seconds);

  /// No description provided for @resetPasswordResent.
  ///
  /// In id, this message translates to:
  /// **'Jika email terdaftar, kode baru telah dikirim.'**
  String get resetPasswordResent;

  /// No description provided for @resetPasswordSubmit.
  ///
  /// In id, this message translates to:
  /// **'Reset password'**
  String get resetPasswordSubmit;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In id, this message translates to:
  /// **'Password berhasil diubah. Silakan masuk.'**
  String get resetPasswordSuccess;

  /// No description provided for @userRoleOwner.
  ///
  /// In id, this message translates to:
  /// **'Owner'**
  String get userRoleOwner;

  /// No description provided for @userRoleStaff.
  ///
  /// In id, this message translates to:
  /// **'Staff'**
  String get userRoleStaff;

  /// No description provided for @validationPasswordTooLong.
  ///
  /// In id, this message translates to:
  /// **'Password terlalu panjang (maksimal 72 byte)'**
  String get validationPasswordTooLong;

  /// No description provided for @validationOtpLength.
  ///
  /// In id, this message translates to:
  /// **'Kode harus 6 digit'**
  String get validationOtpLength;

  /// No description provided for @validationOutletCode.
  ///
  /// In id, this message translates to:
  /// **'Kode outlet 2–5 huruf atau angka'**
  String get validationOutletCode;

  /// No description provided for @validationServerInvalid.
  ///
  /// In id, this message translates to:
  /// **'Isian tidak valid'**
  String get validationServerInvalid;

  /// No description provided for @shellTabDashboard.
  ///
  /// In id, this message translates to:
  /// **'Dashboard'**
  String get shellTabDashboard;

  /// No description provided for @shellTabOrders.
  ///
  /// In id, this message translates to:
  /// **'Order'**
  String get shellTabOrders;

  /// No description provided for @shellTabSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get shellTabSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get settingsSectionAccount;

  /// No description provided for @settingsProfile.
  ///
  /// In id, this message translates to:
  /// **'Profil'**
  String get settingsProfile;

  /// No description provided for @settingsChangePassword.
  ///
  /// In id, this message translates to:
  /// **'Ubah Password'**
  String get settingsChangePassword;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In id, this message translates to:
  /// **'Tampilan'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In id, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsLanguage.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get settingsLanguage;

  /// No description provided for @settingsSectionManage.
  ///
  /// In id, this message translates to:
  /// **'Kelola'**
  String get settingsSectionManage;

  /// No description provided for @settingsManageServices.
  ///
  /// In id, this message translates to:
  /// **'Layanan & Harga'**
  String get settingsManageServices;

  /// No description provided for @settingsManageCustomers.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get settingsManageCustomers;

  /// No description provided for @settingsManageStaff.
  ///
  /// In id, this message translates to:
  /// **'Staff'**
  String get settingsManageStaff;

  /// No description provided for @settingsManageOutlets.
  ///
  /// In id, this message translates to:
  /// **'Outlet'**
  String get settingsManageOutlets;

  /// No description provided for @settingsLogout.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari akun?'**
  String get settingsLogoutConfirmTitle;

  /// No description provided for @settingsLogoutConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Anda perlu masuk lagi untuk memakai aplikasi.'**
  String get settingsLogoutConfirmBody;

  /// No description provided for @profileTitle.
  ///
  /// In id, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileRoleLabel.
  ///
  /// In id, this message translates to:
  /// **'Peran'**
  String get profileRoleLabel;

  /// No description provided for @profileOutletLabel.
  ///
  /// In id, this message translates to:
  /// **'Outlet'**
  String get profileOutletLabel;

  /// No description provided for @profileAllOutlets.
  ///
  /// In id, this message translates to:
  /// **'Semua outlet'**
  String get profileAllOutlets;

  /// No description provided for @profileSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get profileSave;

  /// No description provided for @profileSaved.
  ///
  /// In id, this message translates to:
  /// **'Profil berhasil disimpan'**
  String get profileSaved;

  /// No description provided for @changePasswordTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In id, this message translates to:
  /// **'Password saat ini'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In id, this message translates to:
  /// **'Ubah password'**
  String get changePasswordSubmit;

  /// No description provided for @changePasswordCurrentWrong.
  ///
  /// In id, this message translates to:
  /// **'Password saat ini salah'**
  String get changePasswordCurrentWrong;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In id, this message translates to:
  /// **'Password berhasil diubah'**
  String get changePasswordSuccess;

  /// No description provided for @commonSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari'**
  String get commonSearch;

  /// No description provided for @commonClear.
  ///
  /// In id, this message translates to:
  /// **'Hapus teks'**
  String get commonClear;

  /// No description provided for @commonActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get commonActive;

  /// No description provided for @commonInactive.
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get commonInactive;

  /// No description provided for @commonSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get commonDelete;

  /// No description provided for @commonContinue.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan'**
  String get commonContinue;

  /// No description provided for @commonDays.
  ///
  /// In id, this message translates to:
  /// **'{days} hari'**
  String commonDays(int days);

  /// No description provided for @validationRange.
  ///
  /// In id, this message translates to:
  /// **'Isi angka {min}–{max}'**
  String validationRange(int min, int max);

  /// No description provided for @timeAgoJustNow.
  ///
  /// In id, this message translates to:
  /// **'Baru saja'**
  String get timeAgoJustNow;

  /// No description provided for @timeAgoMinutes.
  ///
  /// In id, this message translates to:
  /// **'{minutes} menit lalu'**
  String timeAgoMinutes(int minutes);

  /// No description provided for @timeAgoHours.
  ///
  /// In id, this message translates to:
  /// **'{hours} jam lalu'**
  String timeAgoHours(int hours);

  /// No description provided for @timeAgoDays.
  ///
  /// In id, this message translates to:
  /// **'{days} hari lalu'**
  String timeAgoDays(int days);

  /// No description provided for @outletsTitle.
  ///
  /// In id, this message translates to:
  /// **'Outlet'**
  String get outletsTitle;

  /// No description provided for @outletsAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah outlet'**
  String get outletsAdd;

  /// No description provided for @outletsEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada outlet'**
  String get outletsEmpty;

  /// No description provided for @outletFormAddTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Outlet'**
  String get outletFormAddTitle;

  /// No description provided for @outletFormEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Outlet'**
  String get outletFormEditTitle;

  /// No description provided for @outletFormAddressLabel.
  ///
  /// In id, this message translates to:
  /// **'Alamat (opsional)'**
  String get outletFormAddressLabel;

  /// No description provided for @outletFormPhoneLabel.
  ///
  /// In id, this message translates to:
  /// **'Telepon (opsional)'**
  String get outletFormPhoneLabel;

  /// No description provided for @outletFormCodeLocked.
  ///
  /// In id, this message translates to:
  /// **'Kode tidak dapat diubah'**
  String get outletFormCodeLocked;

  /// No description provided for @outletFormCreated.
  ///
  /// In id, this message translates to:
  /// **'Outlet dibuat. Katalog layanan default dibuat otomatis.'**
  String get outletFormCreated;

  /// No description provided for @outletFormSaved.
  ///
  /// In id, this message translates to:
  /// **'Outlet disimpan'**
  String get outletFormSaved;

  /// No description provided for @outletDeactivateTitle.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan outlet?'**
  String get outletDeactivateTitle;

  /// No description provided for @outletDeactivateBody.
  ///
  /// In id, this message translates to:
  /// **'Outlet nonaktif tidak dapat menerima order baru.'**
  String get outletDeactivateBody;

  /// No description provided for @outletDeactivateConfirm.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan'**
  String get outletDeactivateConfirm;

  /// No description provided for @outletFilterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua outlet'**
  String get outletFilterAll;

  /// No description provided for @outletFilterTooltip.
  ///
  /// In id, this message translates to:
  /// **'Pilih outlet'**
  String get outletFilterTooltip;

  /// No description provided for @outletPickerLabel.
  ///
  /// In id, this message translates to:
  /// **'Outlet'**
  String get outletPickerLabel;

  /// No description provided for @outletPickerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih outlet'**
  String get outletPickerTitle;

  /// No description provided for @servicesTitle.
  ///
  /// In id, this message translates to:
  /// **'Layanan & Harga'**
  String get servicesTitle;

  /// No description provided for @servicesAddUnit.
  ///
  /// In id, this message translates to:
  /// **'Tambah satuan'**
  String get servicesAddUnit;

  /// No description provided for @servicesSectionKilo.
  ///
  /// In id, this message translates to:
  /// **'Kiloan'**
  String get servicesSectionKilo;

  /// No description provided for @servicesSectionUnit.
  ///
  /// In id, this message translates to:
  /// **'Satuan'**
  String get servicesSectionUnit;

  /// No description provided for @servicesUnitEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada layanan satuan'**
  String get servicesUnitEmpty;

  /// No description provided for @servicesBadgeSystem.
  ///
  /// In id, this message translates to:
  /// **'Sistem'**
  String get servicesBadgeSystem;

  /// No description provided for @servicesDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus layanan?'**
  String get servicesDeleteTitle;

  /// No description provided for @servicesDeleteBody.
  ///
  /// In id, this message translates to:
  /// **'Layanan \"{name}\" akan dihapus. Order lama tidak terpengaruh.'**
  String servicesDeleteBody(String name);

  /// No description provided for @servicesDeleted.
  ///
  /// In id, this message translates to:
  /// **'Layanan dihapus'**
  String get servicesDeleted;

  /// No description provided for @serviceFormAddTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Layanan Satuan'**
  String get serviceFormAddTitle;

  /// No description provided for @serviceFormEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Layanan'**
  String get serviceFormEditTitle;

  /// No description provided for @serviceFormNameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama layanan'**
  String get serviceFormNameLabel;

  /// No description provided for @serviceFormUnitLabel.
  ///
  /// In id, this message translates to:
  /// **'Satuan'**
  String get serviceFormUnitLabel;

  /// No description provided for @serviceFormUnitLocked.
  ///
  /// In id, this message translates to:
  /// **'Satuan tidak dapat diubah'**
  String get serviceFormUnitLocked;

  /// No description provided for @serviceFormRegularPriceLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga reguler (per {unit})'**
  String serviceFormRegularPriceLabel(String unit);

  /// No description provided for @serviceFormExpressPriceLabel.
  ///
  /// In id, this message translates to:
  /// **'Harga express (per {unit})'**
  String serviceFormExpressPriceLabel(String unit);

  /// No description provided for @serviceFormRegularDaysLabel.
  ///
  /// In id, this message translates to:
  /// **'Durasi reguler (hari)'**
  String get serviceFormRegularDaysLabel;

  /// No description provided for @serviceFormExpressDaysLabel.
  ///
  /// In id, this message translates to:
  /// **'Durasi express (hari)'**
  String get serviceFormExpressDaysLabel;

  /// No description provided for @serviceFormMinQuantityLabel.
  ///
  /// In id, this message translates to:
  /// **'Minimal kuantitas (kg)'**
  String get serviceFormMinQuantityLabel;

  /// No description provided for @serviceFormMinQuantityHelper.
  ///
  /// In id, this message translates to:
  /// **'0 = tanpa minimum'**
  String get serviceFormMinQuantityHelper;

  /// No description provided for @serviceFormCreated.
  ///
  /// In id, this message translates to:
  /// **'Layanan ditambahkan'**
  String get serviceFormCreated;

  /// No description provided for @serviceFormSaved.
  ///
  /// In id, this message translates to:
  /// **'Layanan disimpan'**
  String get serviceFormSaved;

  /// No description provided for @serviceFormDeactivateKiloTitle.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan layanan?'**
  String get serviceFormDeactivateKiloTitle;

  /// No description provided for @serviceFormDeactivateKiloBody.
  ///
  /// In id, this message translates to:
  /// **'Layanan nonaktif tidak dapat dipilih saat membuat order baru.'**
  String get serviceFormDeactivateKiloBody;

  /// No description provided for @serviceFormDeactivateConfirm.
  ///
  /// In id, this message translates to:
  /// **'Nonaktifkan'**
  String get serviceFormDeactivateConfirm;

  /// No description provided for @staffTitle.
  ///
  /// In id, this message translates to:
  /// **'Staff'**
  String get staffTitle;

  /// No description provided for @staffAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah staff'**
  String get staffAdd;

  /// No description provided for @staffSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau email'**
  String get staffSearchHint;

  /// No description provided for @staffEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada staff'**
  String get staffEmpty;

  /// No description provided for @staffFormAddTitle.
  ///
  /// In id, this message translates to:
  /// **'Tambah Staff'**
  String get staffFormAddTitle;

  /// No description provided for @staffFormEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Staff'**
  String get staffFormEditTitle;

  /// No description provided for @staffFormCreated.
  ///
  /// In id, this message translates to:
  /// **'Staff ditambahkan'**
  String get staffFormCreated;

  /// No description provided for @staffFormSaved.
  ///
  /// In id, this message translates to:
  /// **'Staff disimpan'**
  String get staffFormSaved;

  /// No description provided for @staffSessionEndsTitle.
  ///
  /// In id, this message translates to:
  /// **'Akhiri sesi staff?'**
  String get staffSessionEndsTitle;

  /// No description provided for @staffSessionEndsBody.
  ///
  /// In id, this message translates to:
  /// **'Sesi staff ini akan berakhir dan ia harus masuk lagi.'**
  String get staffSessionEndsBody;

  /// No description provided for @staffResetPassword.
  ///
  /// In id, this message translates to:
  /// **'Reset password'**
  String get staffResetPassword;

  /// No description provided for @staffResetPasswordTitle.
  ///
  /// In id, this message translates to:
  /// **'Reset password staff'**
  String get staffResetPasswordTitle;

  /// No description provided for @staffResetPasswordBody.
  ///
  /// In id, this message translates to:
  /// **'Masukkan password baru. Semua sesi staff ini akan berakhir.'**
  String get staffResetPasswordBody;

  /// No description provided for @staffResetPasswordDone.
  ///
  /// In id, this message translates to:
  /// **'Password staff direset'**
  String get staffResetPasswordDone;

  /// No description provided for @customersTitle.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get customersTitle;

  /// No description provided for @customersSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau nomor HP'**
  String get customersSearchHint;

  /// No description provided for @customersEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pelanggan'**
  String get customersEmptyTitle;

  /// No description provided for @customersEmptyMessage.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan muncul otomatis saat order dibuat.'**
  String get customersEmptyMessage;

  /// No description provided for @customersLastOrder.
  ///
  /// In id, this message translates to:
  /// **'Order terakhir: {when}'**
  String customersLastOrder(String when);

  /// No description provided for @customerEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Ubah Pelanggan'**
  String get customerEditTitle;

  /// No description provided for @customerEditSaved.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan disimpan'**
  String get customerEditSaved;

  /// No description provided for @customerEditPhoneLabel.
  ///
  /// In id, this message translates to:
  /// **'Nomor HP (opsional)'**
  String get customerEditPhoneLabel;

  /// No description provided for @commonBack.
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get commonBack;

  /// No description provided for @commonOk.
  ///
  /// In id, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @ordersTitle.
  ///
  /// In id, this message translates to:
  /// **'Order'**
  String get ordersTitle;

  /// No description provided for @ordersNew.
  ///
  /// In id, this message translates to:
  /// **'Order Baru'**
  String get ordersNew;

  /// No description provided for @ordersSearchHint.
  ///
  /// In id, this message translates to:
  /// **'Cari nomor order atau pelanggan'**
  String get ordersSearchHint;

  /// No description provided for @ordersFilterAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get ordersFilterAll;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada order'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersEmptyMessage.
  ///
  /// In id, this message translates to:
  /// **'Ketuk Order Baru untuk membuat order pertama.'**
  String get ordersEmptyMessage;

  /// No description provided for @ordersEstimatedDone.
  ///
  /// In id, this message translates to:
  /// **'Estimasi selesai: {date}'**
  String ordersEstimatedDone(String date);

  /// No description provided for @orderActionStart.
  ///
  /// In id, this message translates to:
  /// **'Mulai Proses'**
  String get orderActionStart;

  /// No description provided for @orderActionFinish.
  ///
  /// In id, this message translates to:
  /// **'Tandai Selesai'**
  String get orderActionFinish;

  /// No description provided for @orderActionPickUp.
  ///
  /// In id, this message translates to:
  /// **'Tandai Diambil'**
  String get orderActionPickUp;

  /// No description provided for @orderActionMarkPaid.
  ///
  /// In id, this message translates to:
  /// **'Tandai Lunas'**
  String get orderActionMarkPaid;

  /// No description provided for @orderActionsMenu.
  ///
  /// In id, this message translates to:
  /// **'Menu order'**
  String get orderActionsMenu;

  /// No description provided for @orderActionEdit.
  ///
  /// In id, this message translates to:
  /// **'Edit'**
  String get orderActionEdit;

  /// No description provided for @orderActionChangeStatus.
  ///
  /// In id, this message translates to:
  /// **'Ubah status'**
  String get orderActionChangeStatus;

  /// No description provided for @orderActionUnpay.
  ///
  /// In id, this message translates to:
  /// **'Batalkan Lunas'**
  String get orderActionUnpay;

  /// No description provided for @orderActionDelete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get orderActionDelete;

  /// No description provided for @orderPaidQuestionTitle.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan sudah membayar?'**
  String get orderPaidQuestionTitle;

  /// No description provided for @orderPaidQuestionBody.
  ///
  /// In id, this message translates to:
  /// **'Order harus lunas sebelum ditandai diambil.'**
  String get orderPaidQuestionBody;

  /// No description provided for @orderPaidQuestionConfirm.
  ///
  /// In id, this message translates to:
  /// **'Ya, sudah lunas'**
  String get orderPaidQuestionConfirm;

  /// No description provided for @orderPaidButNotPickedUp.
  ///
  /// In id, this message translates to:
  /// **'Order sudah ditandai lunas, tetapi belum ditandai diambil.'**
  String get orderPaidButNotPickedUp;

  /// No description provided for @orderUnpayTitle.
  ///
  /// In id, this message translates to:
  /// **'Batalkan status lunas?'**
  String get orderUnpayTitle;

  /// No description provided for @orderUnpayBody.
  ///
  /// In id, this message translates to:
  /// **'Order akan kembali menjadi belum lunas.'**
  String get orderUnpayBody;

  /// No description provided for @orderDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus order?'**
  String get orderDeleteTitle;

  /// No description provided for @orderDeleteBody.
  ///
  /// In id, this message translates to:
  /// **'Order {number} akan dihapus dan tidak muncul lagi di daftar.'**
  String orderDeleteBody(String number);

  /// No description provided for @orderDeleted.
  ///
  /// In id, this message translates to:
  /// **'Order dihapus'**
  String get orderDeleted;

  /// No description provided for @orderDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Order'**
  String get orderDetailTitle;

  /// No description provided for @orderDetailOutlet.
  ///
  /// In id, this message translates to:
  /// **'Outlet'**
  String get orderDetailOutlet;

  /// No description provided for @orderDetailReceivedAt.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get orderDetailReceivedAt;

  /// No description provided for @orderDetailSpeed.
  ///
  /// In id, this message translates to:
  /// **'Kecepatan'**
  String get orderDetailSpeed;

  /// No description provided for @orderDetailCreatedBy.
  ///
  /// In id, this message translates to:
  /// **'Dibuat oleh'**
  String get orderDetailCreatedBy;

  /// No description provided for @orderDetailCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get orderDetailCustomer;

  /// No description provided for @orderDetailProgress.
  ///
  /// In id, this message translates to:
  /// **'Progres'**
  String get orderDetailProgress;

  /// No description provided for @orderDetailItems.
  ///
  /// In id, this message translates to:
  /// **'Item'**
  String get orderDetailItems;

  /// No description provided for @orderDetailTotal.
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get orderDetailTotal;

  /// No description provided for @orderDetailPayment.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get orderDetailPayment;

  /// No description provided for @orderDetailPaidAt.
  ///
  /// In id, this message translates to:
  /// **'Lunas pada'**
  String get orderDetailPaidAt;

  /// No description provided for @orderDetailNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get orderDetailNotes;

  /// No description provided for @orderItemDimensions.
  ///
  /// In id, this message translates to:
  /// **'{length} × {width} m = {area} m²'**
  String orderItemDimensions(String length, String width, String area);

  /// No description provided for @orderItemBilled.
  ///
  /// In id, this message translates to:
  /// **'ditagih {quantity} {unit}'**
  String orderItemBilled(String quantity, String unit);

  /// No description provided for @orderFormNewTitle.
  ///
  /// In id, this message translates to:
  /// **'Order Baru'**
  String get orderFormNewTitle;

  /// No description provided for @orderFormEditTitle.
  ///
  /// In id, this message translates to:
  /// **'Edit Order'**
  String get orderFormEditTitle;

  /// No description provided for @orderFormEditNote.
  ///
  /// In id, this message translates to:
  /// **'Harga dihitung ulang dengan harga terbaru saat disimpan.'**
  String get orderFormEditNote;

  /// No description provided for @orderFormCustomerSection.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get orderFormCustomerSection;

  /// No description provided for @orderFormCustomerLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama pelanggan'**
  String get orderFormCustomerLabel;

  /// No description provided for @orderFormCustomerPhoneLabel.
  ///
  /// In id, this message translates to:
  /// **'No. HP (opsional)'**
  String get orderFormCustomerPhoneLabel;

  /// No description provided for @orderFormCustomerAddNew.
  ///
  /// In id, this message translates to:
  /// **'Tambah pelanggan baru: {name}'**
  String orderFormCustomerAddNew(String name);

  /// No description provided for @orderFormCustomerChange.
  ///
  /// In id, this message translates to:
  /// **'Ganti'**
  String get orderFormCustomerChange;

  /// No description provided for @orderFormCustomerSearchFailed.
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat mencari pelanggan. Anda tetap bisa menambah pelanggan baru.'**
  String get orderFormCustomerSearchFailed;

  /// No description provided for @orderFormSpeedSection.
  ///
  /// In id, this message translates to:
  /// **'Kecepatan'**
  String get orderFormSpeedSection;

  /// No description provided for @orderFormEstimatedDone.
  ///
  /// In id, this message translates to:
  /// **'Perkiraan selesai: {date}'**
  String orderFormEstimatedDone(String date);

  /// No description provided for @orderFormPickOutlet.
  ///
  /// In id, this message translates to:
  /// **'Pilih outlet terlebih dahulu.'**
  String get orderFormPickOutlet;

  /// No description provided for @orderFormKiloSection.
  ///
  /// In id, this message translates to:
  /// **'Kiloan'**
  String get orderFormKiloSection;

  /// No description provided for @orderFormNoKiloServices.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada layanan kiloan aktif.'**
  String get orderFormNoKiloServices;

  /// No description provided for @orderFormBilledAs.
  ///
  /// In id, this message translates to:
  /// **'Ditagih {min} kg'**
  String orderFormBilledAs(String min);

  /// No description provided for @orderFormUnitSection.
  ///
  /// In id, this message translates to:
  /// **'Satuan'**
  String get orderFormUnitSection;

  /// No description provided for @orderFormAddUnitItem.
  ///
  /// In id, this message translates to:
  /// **'Tambah item satuan'**
  String get orderFormAddUnitItem;

  /// No description provided for @orderFormUnitPickerTitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih layanan satuan'**
  String get orderFormUnitPickerTitle;

  /// No description provided for @orderFormUnitPickerEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada layanan satuan aktif.'**
  String get orderFormUnitPickerEmpty;

  /// No description provided for @orderFormUnitAdd.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get orderFormUnitAdd;

  /// No description provided for @orderFormLengthLabel.
  ///
  /// In id, this message translates to:
  /// **'Panjang (m)'**
  String get orderFormLengthLabel;

  /// No description provided for @orderFormWidthLabel.
  ///
  /// In id, this message translates to:
  /// **'Lebar (m)'**
  String get orderFormWidthLabel;

  /// No description provided for @orderFormArea.
  ///
  /// In id, this message translates to:
  /// **'Luas: {area} {unit}'**
  String orderFormArea(String area, String unit);

  /// No description provided for @orderFormDecrease.
  ///
  /// In id, this message translates to:
  /// **'Kurangi'**
  String get orderFormDecrease;

  /// No description provided for @orderFormIncrease.
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get orderFormIncrease;

  /// No description provided for @orderFormRemoveItem.
  ///
  /// In id, this message translates to:
  /// **'Hapus item'**
  String get orderFormRemoveItem;

  /// No description provided for @orderFormInactiveWarning.
  ///
  /// In id, this message translates to:
  /// **'Layanan berikut sudah tidak aktif. Hapus sebelum menyimpan.'**
  String get orderFormInactiveWarning;

  /// No description provided for @orderFormNotesSection.
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get orderFormNotesSection;

  /// No description provided for @orderFormNotesHint.
  ///
  /// In id, this message translates to:
  /// **'Catatan untuk order ini (opsional)'**
  String get orderFormNotesHint;

  /// No description provided for @orderFormPaidSwitch.
  ///
  /// In id, this message translates to:
  /// **'Sudah Lunas'**
  String get orderFormPaidSwitch;

  /// No description provided for @orderFormEstimatedTotal.
  ///
  /// In id, this message translates to:
  /// **'Perkiraan total'**
  String get orderFormEstimatedTotal;

  /// No description provided for @orderFormOutletRequired.
  ///
  /// In id, this message translates to:
  /// **'Pilih outlet terlebih dahulu.'**
  String get orderFormOutletRequired;

  /// No description provided for @orderFormItemsRequired.
  ///
  /// In id, this message translates to:
  /// **'Tambahkan minimal satu item.'**
  String get orderFormItemsRequired;

  /// No description provided for @orderFormItemsInvalid.
  ///
  /// In id, this message translates to:
  /// **'Periksa kuantitas item. Isi dengan angka yang valid.'**
  String get orderFormItemsInvalid;

  /// No description provided for @orderFormRemoveInactive.
  ///
  /// In id, this message translates to:
  /// **'Hapus layanan yang sudah tidak aktif sebelum menyimpan.'**
  String get orderFormRemoveInactive;

  /// No description provided for @orderFormTooManyItems.
  ///
  /// In id, this message translates to:
  /// **'Satu order maksimal 50 item.'**
  String get orderFormTooManyItems;

  /// No description provided for @orderFormItemError.
  ///
  /// In id, this message translates to:
  /// **'Item \"{name}\" tidak valid. Periksa kuantitasnya.'**
  String orderFormItemError(String name);

  /// No description provided for @orderFormChangeOutletTitle.
  ///
  /// In id, this message translates to:
  /// **'Ganti outlet?'**
  String get orderFormChangeOutletTitle;

  /// No description provided for @orderFormChangeOutletBody.
  ///
  /// In id, this message translates to:
  /// **'Layanan berbeda di tiap outlet, jadi semua item akan dikosongkan.'**
  String get orderFormChangeOutletBody;

  /// No description provided for @orderFormDiscardTitle.
  ///
  /// In id, this message translates to:
  /// **'Buang perubahan?'**
  String get orderFormDiscardTitle;

  /// No description provided for @orderFormDiscardBody.
  ///
  /// In id, this message translates to:
  /// **'Data yang sudah diisi akan hilang.'**
  String get orderFormDiscardBody;

  /// No description provided for @orderFormDiscardConfirm.
  ///
  /// In id, this message translates to:
  /// **'Buang'**
  String get orderFormDiscardConfirm;

  /// No description provided for @orderFormCreated.
  ///
  /// In id, this message translates to:
  /// **'Order {number} dibuat'**
  String orderFormCreated(String number);

  /// No description provided for @orderFormSaved.
  ///
  /// In id, this message translates to:
  /// **'Order disimpan'**
  String get orderFormSaved;

  /// No description provided for @orderFormCreateUnknownTitle.
  ///
  /// In id, this message translates to:
  /// **'Hasil belum pasti'**
  String get orderFormCreateUnknownTitle;

  /// No description provided for @orderFormCreateUnknownBody.
  ///
  /// In id, this message translates to:
  /// **'Koneksi terputus. Order mungkin sudah tersimpan. Periksa daftar order sebelum mencoba lagi agar tidak dobel.'**
  String get orderFormCreateUnknownBody;

  /// No description provided for @dashboardTitle.
  ///
  /// In id, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardRange1h.
  ///
  /// In id, this message translates to:
  /// **'1J'**
  String get dashboardRange1h;

  /// No description provided for @dashboardRange24h.
  ///
  /// In id, this message translates to:
  /// **'24J'**
  String get dashboardRange24h;

  /// No description provided for @dashboardRange7d.
  ///
  /// In id, this message translates to:
  /// **'7H'**
  String get dashboardRange7d;

  /// No description provided for @dashboardRange30d.
  ///
  /// In id, this message translates to:
  /// **'30H'**
  String get dashboardRange30d;

  /// No description provided for @dashboardRange1y.
  ///
  /// In id, this message translates to:
  /// **'1T'**
  String get dashboardRange1y;

  /// No description provided for @dashboardRangeAll.
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get dashboardRangeAll;

  /// No description provided for @dashboardPeriod.
  ///
  /// In id, this message translates to:
  /// **'Periode: {from} – {to}'**
  String dashboardPeriod(String from, String to);

  /// No description provided for @dashboardOperationalNow.
  ///
  /// In id, this message translates to:
  /// **'Kondisi saat ini'**
  String get dashboardOperationalNow;

  /// No description provided for @dashboardInProgress.
  ///
  /// In id, this message translates to:
  /// **'Sedang diproses'**
  String get dashboardInProgress;

  /// No description provided for @dashboardReadyForPickup.
  ///
  /// In id, this message translates to:
  /// **'Siap diambil'**
  String get dashboardReadyForPickup;

  /// No description provided for @dashboardUnpaid.
  ///
  /// In id, this message translates to:
  /// **'Belum lunas'**
  String get dashboardUnpaid;

  /// No description provided for @dashboardSummary.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan periode'**
  String get dashboardSummary;

  /// No description provided for @dashboardTotalOrders.
  ///
  /// In id, this message translates to:
  /// **'Jumlah order'**
  String get dashboardTotalOrders;

  /// No description provided for @dashboardTotalKg.
  ///
  /// In id, this message translates to:
  /// **'Total kg'**
  String get dashboardTotalKg;

  /// No description provided for @dashboardTotalPcs.
  ///
  /// In id, this message translates to:
  /// **'Total pcs'**
  String get dashboardTotalPcs;

  /// No description provided for @dashboardTotalSqm.
  ///
  /// In id, this message translates to:
  /// **'Total m²'**
  String get dashboardTotalSqm;

  /// No description provided for @dashboardRevenue.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan'**
  String get dashboardRevenue;

  /// No description provided for @dashboardRevenuePaid.
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get dashboardRevenuePaid;

  /// No description provided for @dashboardRevenueUnpaid.
  ///
  /// In id, this message translates to:
  /// **'Belum lunas'**
  String get dashboardRevenueUnpaid;

  /// No description provided for @dashboardOrdersCount.
  ///
  /// In id, this message translates to:
  /// **'{count} order'**
  String dashboardOrdersCount(int count);

  /// No description provided for @dashboardChartTitle.
  ///
  /// In id, this message translates to:
  /// **'Grafik'**
  String get dashboardChartTitle;

  /// No description provided for @dashboardMetricOrders.
  ///
  /// In id, this message translates to:
  /// **'Order'**
  String get dashboardMetricOrders;

  /// No description provided for @dashboardMetricWeight.
  ///
  /// In id, this message translates to:
  /// **'Kg'**
  String get dashboardMetricWeight;

  /// No description provided for @dashboardMetricRevenue.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan'**
  String get dashboardMetricRevenue;

  /// No description provided for @dashboardByCategory.
  ///
  /// In id, this message translates to:
  /// **'Per kategori'**
  String get dashboardByCategory;

  /// No description provided for @dashboardByUnitService.
  ///
  /// In id, this message translates to:
  /// **'Per jenis satuan'**
  String get dashboardByUnitService;

  /// No description provided for @dashboardByStatus.
  ///
  /// In id, this message translates to:
  /// **'Per status'**
  String get dashboardByStatus;

  /// No description provided for @dashboardEmpty.
  ///
  /// In id, this message translates to:
  /// **'Belum ada order pada periode ini'**
  String get dashboardEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
