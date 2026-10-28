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

  /// No description provided for @dashboardPlaceholderTitle.
  ///
  /// In id, this message translates to:
  /// **'Dashboard'**
  String get dashboardPlaceholderTitle;

  /// No description provided for @dashboardPlaceholderNotice.
  ///
  /// In id, this message translates to:
  /// **'Layar sementara. Dashboard lengkap menyusul.'**
  String get dashboardPlaceholderNotice;

  /// No description provided for @dashboardPlaceholderRoleLabel.
  ///
  /// In id, this message translates to:
  /// **'Peran'**
  String get dashboardPlaceholderRoleLabel;

  /// No description provided for @dashboardPlaceholderOutletLabel.
  ///
  /// In id, this message translates to:
  /// **'Outlet'**
  String get dashboardPlaceholderOutletLabel;

  /// No description provided for @dashboardPlaceholderLogout.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get dashboardPlaceholderLogout;

  /// No description provided for @dashboardPlaceholderLogoutConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari akun?'**
  String get dashboardPlaceholderLogoutConfirmTitle;

  /// No description provided for @dashboardPlaceholderLogoutConfirmBody.
  ///
  /// In id, this message translates to:
  /// **'Anda perlu masuk lagi untuk memakai aplikasi.'**
  String get dashboardPlaceholderLogoutConfirmBody;
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
