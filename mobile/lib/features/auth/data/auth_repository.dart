import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/shared/network/api_client.dart';
import 'package:knurl/shared/network/token_storage.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<void> signIn(String email, String password) =>
      _authenticate('/auth/login', email, password);

  Future<void> signUp(String email, String password) =>
      _authenticate('/auth/register', email, password);

  Future<void> _authenticate(String path, String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: <String, String>{'email': email, 'password': password},
    );
    final token = _extractToken(response.data);
    await _tokenStorage.write(token);
  }

  String _extractToken(Map<String, dynamic>? data) {
    final token = data?['token'];
    if (token is String && token.isNotEmpty) {
      return token;
    }

    throw StateError('Missing auth token in response');
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);
