import 'package:dio/dio.dart';

/// Adds `Accept-Language` (`id` or `en`) from the active app language.
class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._languageCode);

  final String Function() _languageCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _languageCode();
    handler.next(options);
  }
}
