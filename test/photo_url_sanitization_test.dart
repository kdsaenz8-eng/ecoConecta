/// Pruebas unitarias (TDD) para validar la sanitización de photo_url
/// garantizando el cumplimiento del contrato del backend (VARCHAR(500) / max_length: 500).
library;

import 'package:ecoconecta_frontend/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sanitización de photo_url para Contrato Backend (<= 500 caracteres)', () {
    test('Retorna null si el photo_url es null o vacío', () {
      expect(AppConstants.sanitizePhotoUrl(null), isNull);
      expect(AppConstants.sanitizePhotoUrl(''), isNull);
      expect(AppConstants.sanitizePhotoUrl('   '), isNull);
    });

    test('Conserva URLs HTTP/HTTPS válidas menores o iguales a 500 caracteres', () {
      const String validUrl = 'https://storage.ecoconecta.co/evidencias/bolsa_blanca_01.jpg';
      expect(AppConstants.sanitizePhotoUrl(validUrl), validUrl);
    });

    test('Permite cadenas Data URI base64 reales para persistencia en el backend', () {
      const String dummyBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      final String? sanitized = AppConstants.sanitizePhotoUrl(dummyBase64);

      expect(sanitized, isNotNull);
      expect(sanitized!.startsWith('data:image/'), isTrue);
    });

    test('Descarta URLs arbitrarias mayores a 500 caracteres sin inventar datos simulados', () {
      final String over500Url = 'https://example.com/very/long/path/${'x' * 600}.jpg';
      final String? sanitized = AppConstants.sanitizePhotoUrl(over500Url);

      expect(sanitized, isNull);
    });

    test('resolvePhotoUrl convierte rutas relativas del backend en URLs absolutas alcanzables', () {
      expect(AppConstants.resolvePhotoUrl(null), isNull);
      expect(AppConstants.resolvePhotoUrl(''), isNull);
      expect(
        AppConstants.resolvePhotoUrl('https://images.unsplash.com/photo-123'),
        'https://images.unsplash.com/photo-123',
      );
      expect(
        AppConstants.resolvePhotoUrl('/api/v1/uploads/evidence_123.jpg'),
        'https://ecoconecta.quantumcore.com.co/api/v1/uploads/evidence_123.jpg',
      );
    });
  });
}

