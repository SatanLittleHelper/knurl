import 'package:dio/dio.dart';

const _apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8080',
);

final dio = Dio(
  BaseOptions(
    baseUrl: _apiUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ),
);
