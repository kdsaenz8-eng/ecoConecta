/// Cliente HTTP Dio centralizado con Interceptor JWT conectado a FlutterSecureStorage.
library;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class DioClient {
  static const String tokenStorageKey = 'ecoconecta_jwt_token';
  static const String roleStorageKey = 'ecoconecta_user_role';
  static const String userNameStorageKey = 'ecoconecta_user_name';

  final Dio dio;
  final FlutterSecureStorage secureStorage;

  DioClient({
    Dio? customDio,
    FlutterSecureStorage? customStorage,
  })  : secureStorage = customStorage ?? const FlutterSecureStorage(),
        dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 12),
                headers: const <String, dynamic>{
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          final String? token = await secureStorage.read(key: tokenStorageKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }
}

