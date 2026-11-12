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

    test('Reemplaza cadenas Data URI base64 gigantes por URL representativa <= 500 caracteres', () {
      // Simula un Data URI base64 de cámara de más de 100 KB
      final String hugeBase64 = 'data:image/png;base64,${'A' * 100000}';
      final String? sanitized = AppConstants.sanitizePhotoUrl(
        hugeBase64,
        categories: <String>['Plástico y Botellas'],
      );

      expect(sanitized, isNotNull);
      expect(sanitized!.startsWith('https://'), isTrue);
      expect(sanitized.length, lessThanOrEqualTo(500));
      expect(sanitized.startsWith('data:'), isFalse);
    });

    test('Reemplaza URLs arbitrarias mayores a 500 caracteres por URL representativa válida', () {
      final String over500Url = 'https://example.com/very/long/path/${'x' * 600}.jpg';
      final String? sanitized = AppConstants.sanitizePhotoUrl(
        over500Url,
        categories: <String>['Vidrio y Envases'],
      );

      expect(sanitized, isNotNull);
      expect(sanitized!.length, lessThanOrEqualTo(500));
      expect(sanitized, contains('unsplash.com'));
    });

    test('Asigna imágenes de evidencia coherentes según la categoría seleccionada', () {
      final String dummyBase64 = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...';

      final String? vidrio = AppConstants.sanitizePhotoUrl(
        dummyBase64,
        categories: <String>['Vidrio y Envases'],
      );
      final String? carton = AppConstants.sanitizePhotoUrl(
        dummyBase64,
        categories: <String>['Papel y Cartón Limpio'],
      );
      final String? metal = AppConstants.sanitizePhotoUrl(
        dummyBase64,
        categories: <String>['Latas y Metales'],
      );
      final String? plastico = AppConstants.sanitizePhotoUrl(
        dummyBase64,
        categories: <String>['Plástico y Botellas'],
      );

      expect(vidrio, isNotNull);
      expect(carton, isNotNull);
      expect(metal, isNotNull);
      expect(plastico, isNotNull);

      expect(vidrio!.length, lessThanOrEqualTo(500));
      expect(carton!.length, lessThanOrEqualTo(500));
      expect(metal!.length, lessThanOrEqualTo(500));
      expect(plastico!.length, lessThanOrEqualTo(500));
    });
  });
}
