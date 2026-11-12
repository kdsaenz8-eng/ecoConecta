/// Pruebas unitarias (TDD) para validar la normalización bidireccional de categorías de residuos
/// entre las etiquetas de UI de la Resolución 2184 y los Enums de la API Backend ('PLASTICO', 'CARTON', 'VIDRIO', 'METAL').
library;

import 'package:ecoconecta_frontend/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Normalización de Categorías de Residuos (Resolución 2184 a Backend Enums)', () {
    test('Convierte etiquetas de interfaz a Enums esperados por la API', () {
      expect(AppConstants.normalizeCategoryToApi('Plástico y Botellas'), 'PLASTICO');
      expect(AppConstants.normalizeCategoryToApi('Papel y Cartón Limpio'), 'CARTON');
      expect(AppConstants.normalizeCategoryToApi('Cartón y Papel'), 'CARTON');
      expect(AppConstants.normalizeCategoryToApi('Vidrio y Envases'), 'VIDRIO');
      expect(AppConstants.normalizeCategoryToApi('Latas y Metales'), 'METAL');
    });

    test('Mapea correctamente subcadenas o variaciones de entrada', () {
      expect(AppConstants.normalizeCategoryToApi('plásticos variados'), 'PLASTICO');
      expect(AppConstants.normalizeCategoryToApi('cajas de cartón'), 'CARTON');
      expect(AppConstants.normalizeCategoryToApi('botellas de vidrio'), 'VIDRIO');
      expect(AppConstants.normalizeCategoryToApi('latas de aluminio'), 'METAL');
    });

    test('Convierte Enums del Backend a etiquetas amigables para el usuario', () {
      expect(AppConstants.formatCategoryFromApi('PLASTICO'), 'Plástico y Botellas');
      expect(AppConstants.formatCategoryFromApi('CARTON'), 'Papel y Cartón Limpio');
      expect(AppConstants.formatCategoryFromApi('VIDRIO'), 'Vidrio y Envases');
      expect(AppConstants.formatCategoryFromApi('METAL'), 'Latas y Metales');
    });
  });
}
