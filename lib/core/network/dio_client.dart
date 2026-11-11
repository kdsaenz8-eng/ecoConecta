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
          // Garantizar que en cualquier plataforma (Web, Android, iOS) siempre apunte a la API correcta
          final String baseUrl = AppConstants.baseUrl;
          final String path = options.path;
          if (!path.startsWith('http://') && !path.startsWith('https://')) {
            final String cleanBase =
                baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
            final String cleanPath = path.startsWith('/') ? path : '/$path';
            if (cleanPath.startsWith('/api/v1/')) {
              final String host = cleanBase.replaceAll(RegExp(r'/api/v1/?$'), '');
              options.path = '$host$cleanPath';
            } else {
              options.path = '$cleanBase$cleanPath';
            }
          }

          final String? token = await secureStorage.read(key: tokenStorageKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          if (err.response?.statusCode == 401) {
            // Token inválido o expirado: purgar sesión local
            await secureStorage.delete(key: tokenStorageKey);
            await secureStorage.delete(key: roleStorageKey);
            await secureStorage.delete(key: userNameStorageKey);
          }
          handler.next(err);
        },
      ),
    );
  }
}

