import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/network/api_exception.dart';
import 'package:knurl/shared/network/auth_interceptor.dart';
import 'package:knurl/shared/network/token_storage.dart';

class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([this._token]);

  final String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}
}

class CapturingErrorHandler extends ErrorInterceptorHandler {
  DioException? rejected;

  @override
  void reject(DioException err, {bool callFollowingErrorInterceptor = false}) {
    rejected = err;
  }
}

void main() {
  group('AuthInterceptor', () {
    test('добавляет Authorization заголовок если токен есть', () async {
      final interceptor = AuthInterceptor(FakeTokenStorage('my-token'));
      final options = RequestOptions(path: '/test');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer my-token');
    });

    test('не добавляет заголовок если токена нет', () async {
      final interceptor = AuthInterceptor(FakeTokenStorage(null));
      final options = RequestOptions(path: '/test');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('DioException 404 → ApiException(notFound)', () {
      final interceptor = AuthInterceptor(FakeTokenStorage());
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );
      final handler = CapturingErrorHandler();

      interceptor.onError(dioError, handler);

      expect(handler.rejected?.error, isA<ApiException>());
      expect((handler.rejected?.error as ApiException).code, ApiErrorCode.notFound);
    });

    test('DioException 401 → ApiException(unauthorized)', () {
      final interceptor = AuthInterceptor(FakeTokenStorage());
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
      final handler = CapturingErrorHandler();

      interceptor.onError(dioError, handler);

      expect(handler.rejected?.error, isA<ApiException>());
      expect((handler.rejected?.error as ApiException).code, ApiErrorCode.unauthorized);
    });

    test('DioException 500 → ApiException(serverError)', () {
      final interceptor = AuthInterceptor(FakeTokenStorage());
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );
      final handler = CapturingErrorHandler();

      interceptor.onError(dioError, handler);

      expect(handler.rejected?.error, isA<ApiException>());
      expect((handler.rejected?.error as ApiException).code, ApiErrorCode.serverError);
    });

    test('connectionTimeout → ApiException(networkError)', () {
      final interceptor = AuthInterceptor(FakeTokenStorage());
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final handler = CapturingErrorHandler();

      interceptor.onError(dioError, handler);

      expect(handler.rejected?.error, isA<ApiException>());
      expect((handler.rejected?.error as ApiException).code, ApiErrorCode.networkError);
    });

    test('receiveTimeout → ApiException(networkError)', () {
      final interceptor = AuthInterceptor(FakeTokenStorage());
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.receiveTimeout,
      );
      final handler = CapturingErrorHandler();

      interceptor.onError(dioError, handler);

      expect(handler.rejected?.error, isA<ApiException>());
      expect((handler.rejected?.error as ApiException).code, ApiErrorCode.networkError);
    });

    test('connectionError → ApiException(networkError)', () {
      final interceptor = AuthInterceptor(FakeTokenStorage());
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );
      final handler = CapturingErrorHandler();

      interceptor.onError(dioError, handler);

      expect(handler.rejected?.error, isA<ApiException>());
      expect((handler.rejected?.error as ApiException).code, ApiErrorCode.networkError);
    });
  });
}
