/// Servicio de Autenticación y Persistencia Segura (frontend/lib/features/auth/data/auth_service.dart).
/// Gestiona el cliente Dio con interceptor JWT, el almacenamiento cifrado en FlutterSecureStorage
/// y la traducción de excepciones HTTP (401, 409, 422, red) a mensajes claros para el usuario.
library;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_client.dart';

/// Excepción de dominio para errores de autenticación y registro.
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Modelo de sesión autenticada retornado tras registro o login exitoso.
class AuthSessionResult {
  final String accessToken;
  final String role;
  final String fullName;
  final String email;
  final String neighborhood;

  const AuthSessionResult({
    required this.accessToken,
    required this.role,
    required this.fullName,
    required this.email,
    required this.neighborhood,
  });

  factory AuthSessionResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> userMap =
        (json['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return AuthSessionResult(
      accessToken: (json['access_token'] as String?) ?? '',
      role: (json['role'] as String?) ?? (userMap['role'] as String?) ?? 'GENERADOR',
      fullName: (userMap['full_name'] as String?) ?? 'Usuario EcoConecta',
      email: (userMap['email'] as String?) ?? '',
      neighborhood: (userMap['neighborhood'] as String?) ?? 'Municipio',
    );
  }
}

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  AuthService({
    DioClient? dioClient,
    FlutterSecureStorage? secureStorage,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _dio = (dioClient ?? DioClient(customStorage: secureStorage)).dio;

  /// Registra un nuevo usuario (`GENERADOR` o `RECICLADOR`) validando Habeas Data (Ley 1581/2012)
  /// y persiste inmediatamente el token JWT en `FlutterSecureStorage`.
  Future<AuthSessionResult> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    required String userTypeDetail,
    required String neighborhood,
    required String addressReference,
    required bool habeasDataAccepted,
  }) async {
    if (!habeasDataAccepted) {
      throw const AuthException(
        'Debe autorizar el tratamiento de datos personales (Ley 1581/2012) para continuar.',
        statusCode: 422,
      );
    }

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/register',
        data: <String, dynamic>{
          'full_name': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'password': password,
          'role': role,
          'user_type_detail': userTypeDetail,
          'neighborhood': neighborhood,
          'address_reference': addressReference.trim(),
          'habeas_data_accepted': habeasDataAccepted,
        },
      );

      final AuthSessionResult session = AuthSessionResult.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _persistSession(session);
      return session;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('Ocurrió un error inesperado al procesar el registro.');
    }
  }

  /// Autentica a un usuario existente y almacena el JWT en almacenamiento seguro.
  Future<AuthSessionResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/auth/login',
        data: <String, dynamic>{
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final AuthSessionResult session = AuthSessionResult.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _persistSession(session);
      return session;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('No fue posible iniciar sesión. Verifique su conexión.');
    }
  }

  /// Obtiene el perfil actual validando el token JWT contra `/api/v1/auth/me`.
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>('/auth/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Persiste de forma segura el token JWT y metadatos básicos de sesión.
  Future<void> _persistSession(AuthSessionResult session) async {
    await _secureStorage.write(
      key: DioClient.tokenStorageKey,
      value: session.accessToken,
    );
    await _secureStorage.write(
      key: DioClient.roleStorageKey,
      value: session.role,
    );
    await _secureStorage.write(
      key: DioClient.userNameStorageKey,
      value: session.fullName,
    );
  }

  /// Recupera el rol almacenado en sesión segura (`GENERADOR`, `RECICLADOR`, `ADMINISTRADOR`).
  Future<String?> getSavedRole() async {
    return _secureStorage.read(key: DioClient.roleStorageKey);
  }

  /// Recupera el token JWT almacenado.
  Future<String?> getSavedToken() async {
    return _secureStorage.read(key: DioClient.tokenStorageKey);
  }

  /// Elimina las credenciales seguras al cerrar sesión.
  Future<void> logout() async {
    await _secureStorage.delete(key: DioClient.tokenStorageKey);
    await _secureStorage.delete(key: DioClient.roleStorageKey);
    await _secureStorage.delete(key: DioClient.userNameStorageKey);
  }

  /// Traduce errores de red y respuestas HTTP del Backend a `AuthException` legibles.
  AuthException _mapDioException(DioException error) {
    final int? code = error.response?.statusCode;
    final dynamic data = error.response?.data;

    String? serverDetail;
    if (data is Map<String, dynamic>) {
      if (data['detail'] is String) {
        serverDetail = data['detail'] as String;
      } else if (data['detail'] is List && (data['detail'] as List).isNotEmpty) {
        final dynamic firstErr = (data['detail'] as List).first;
        if (firstErr is Map<String, dynamic> && firstErr['msg'] != null) {
          serverDetail = firstErr['msg'].toString();
        }
      }
    }

    if (code == 409) {
      return AuthException(
        serverDetail ?? 'Este correo electrónico ya está registrado en EcoConecta.',
        statusCode: 409,
      );
    }
    if (code == 422) {
      return AuthException(
        serverDetail ??
            'Por favor verifique los datos ingresados y la aceptación de la Ley 1581/2012.',
        statusCode: 422,
      );
    }
    if (code == 401) {
      return AuthException(
        serverDetail ?? 'Credenciales inválidas o sesión expirada.',
        statusCode: 401,
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const AuthException(
        'Sin conexión con el servidor EcoConecta. Verifique su red en el municipio.',
      );
    }
    return AuthException(
      serverDetail ?? 'Error de comunicación con el servidor (Código: ${code ?? "N/A"}).',
      statusCode: code,
    );
  }
}

