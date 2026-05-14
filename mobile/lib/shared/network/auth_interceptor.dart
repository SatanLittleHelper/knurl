import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/shared/network/api_exception.dart';
import 'package:knurl/shared/network/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: _mapError(err),
        type: err.type,
        response: err.response,
      ),
    );
  }

  ApiException _mapError(DioException err) {
    final statusCode = err.response?.statusCode;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return ApiException(
        code: ApiErrorCode.networkError,
        message: 'Нет соединения с сервером',
      );
    }

    return switch (statusCode) {
      401 => ApiException(
          code: ApiErrorCode.unauthorized,
          message: 'Требуется авторизация',
          statusCode: statusCode,
        ),
      404 => ApiException(
          code: ApiErrorCode.notFound,
          message: 'Ресурс не найден',
          statusCode: statusCode,
        ),
      _ when statusCode != null && statusCode >= 500 => ApiException(
          code: ApiErrorCode.serverError,
          message: 'Ошибка сервера',
          statusCode: statusCode,
        ),
      _ => ApiException(
          code: ApiErrorCode.networkError,
          message: err.message ?? 'Неизвестная ошибка сети',
          statusCode: statusCode,
        ),
    };
  }
}

final authInterceptorProvider = Provider<AuthInterceptor>(
  (ref) => AuthInterceptor(ref.watch(tokenStorageProvider)),
);
