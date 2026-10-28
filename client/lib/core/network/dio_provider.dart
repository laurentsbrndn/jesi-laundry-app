import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../config/app_config.dart';
import '../l10n/locale_controller.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'locale_interceptor.dart';
import 'session_events.dart';

BaseOptions _baseOptions() => BaseOptions(
  baseUrl: AppConfig.apiUrl,
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 20),
  headers: {'Accept': 'application/json'},
);

/// Dio without the auth interceptor. Used for `/auth/refresh` and to repeat a
/// request after a refresh. Deliberately has no logging of headers or bodies.
final plainDioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(
    LocaleInterceptor(
      () => ref.read(localeControllerProvider.notifier).resolvedLanguageCode,
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

final dioProvider = Provider<Dio>((ref) {
  final plain = ref.watch(plainDioProvider);
  final dio = Dio(_baseOptions());
  dio.interceptors.addAll([
    LocaleInterceptor(
      () => ref.read(localeControllerProvider.notifier).resolvedLanguageCode,
    ),
    AuthInterceptor(
      storage: ref.watch(tokenStorageProvider),
      events: ref.watch(sessionEventsProvider),
      refresh: AuthRepository(dio: plain, plainDio: plain).refresh,
      retryDio: plain,
    ),
  ]);
  ref.onDispose(dio.close);
  return dio;
});
