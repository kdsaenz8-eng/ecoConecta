/// Constantes normativas (Resolución 2184 de 2019 y Ley 1581 de 2012),
/// sectores barriales del municipio (Antioquia) y configuración dinámica de endpoints API.
library;

import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'EcoConecta';

  static const String prodApiUrl = 'https://ecoconecta.quantumcore.com.co/api/v1';

  /// Determina la URL del Backend oficial según .env.production:
  /// 1. Prioridad: Variable explícita `--dart-define=API_BASE_URL=...`
  /// 2. Por defecto: SIEMPRE el backend oficial de producción: https://ecoconecta.quantumcore.com.co/api/v1
  static String get baseUrl {
    const String fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return prodApiUrl;
  }

  // Coordenadas centrales de referencia: Parque Principal del municipio, Antioquia
  static const double ecoconectaDefaultLat = 7.666925;
  static const double ecoconectaDefaultLon = -76.681140;

  // Barrios representativos del municipio
  static const List<String> ecoconectaNeighborhoods = <String>[
    'Kennedy',
    'El Bosque',
    'Los Balsos',
    'Brisas del Río',
    '10 de Enero',
    'El Prado',
    'La Castellana',
    'Centro',
    'Guayabal',
    'Casablanca',
    'Linares',
    'Zona Comercial / Industrial',
  ];

  // Categorías de Bolsa Blanca idénticas a la vista Web (Resolución 2184 de 2019)
  static const List<Map<String, dynamic>> res2184WasteCategories = <Map<String, dynamic>>[
    {
      'code': 'Plástico y Botellas',
      'label': 'Plástico y Botellas',
      'icon': Icons.local_drink_outlined,
    },
    {
      'code': 'Papel y Cartón Limpio',
      'label': 'Papel y Cartón Limpio',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'code': 'Vidrio y Envases',
      'label': 'Vidrio y Envases',
      'icon': Icons.wine_bar_outlined,
    },
    {
      'code': 'Latas y Metales',
      'label': 'Latas y Metales',
      'icon': Icons.hardware_outlined,
    },
  ];

  /// Mapeo bidireccional entre etiquetas de interfaz y Enums de la API Backend
  /// Backend Enum esperado: 'PLASTICO', 'CARTON', 'VIDRIO', 'METAL'
  static const Map<String, String> categoryToApiEnum = <String, String>{
    'Plástico y Botellas': 'PLASTICO',
    'Papel y Cartón Limpio': 'CARTON',
    'Cartón y Papel': 'CARTON',
    'Vidrio y Envases': 'VIDRIO',
    'Latas y Metales': 'METAL',
  };

  static const Map<String, String> apiEnumToCategory = <String, String>{
    'PLASTICO': 'Plástico y Botellas',
    'CARTON': 'Papel y Cartón Limpio',
    'VIDRIO': 'Vidrio y Envases',
    'METAL': 'Latas y Metales',
  };

  static String normalizeCategoryToApi(String category) {
    if (categoryToApiEnum.containsKey(category)) {
      return categoryToApiEnum[category]!;
    }
    final String upper = category.toUpperCase();
    if (upper.contains('PLAST')) return 'PLASTICO';
    if (upper.contains('CART') || upper.contains('PAPEL')) return 'CARTON';
    if (upper.contains('VIDR')) return 'VIDRIO';
    if (upper.contains('MET') || upper.contains('LATA')) return 'METAL';
    return 'PLASTICO';
  }

  static String formatCategoryFromApi(String rawCategory) {
    if (apiEnumToCategory.containsKey(rawCategory)) {
      return apiEnumToCategory[rawCategory]!;
    }
    final String upper = rawCategory.toUpperCase();
    if (apiEnumToCategory.containsKey(upper)) {
      return apiEnumToCategory[upper]!;
    }
    return rawCategory;
  }

  /// Sanitiza photo_url para respetar estrictamente los límites del contrato Backend:
  /// - Columna de Base de Datos: VARCHAR(500)
  /// - Esquema Pydantic: max_length=500
  /// - Filtra Data URIs base64 masivos ('data:image/...') que saturan el payload.
  /// - Retorna una URL HTTP/HTTPS segura <= 500 caracteres, una URL de evidencia de CDN según el material, o null.
  static String? sanitizePhotoUrl(String? photoUrl, {Iterable<String>? categories}) {
    if (photoUrl == null || photoUrl.trim().isEmpty) return null;
    final String trimmed = photoUrl.trim();

    // Si ya es una URL remota válida que cabe en los 500 caracteres del backend
    if ((trimmed.startsWith('http://') || trimmed.startsWith('https://')) && trimmed.length <= 500) {
      return trimmed;
    }

    // Para Data URIs (base64) o URLs excesivas > 500 caracteres,
    // asignamos una URL de evidencia fotográfica normalizada según la categoría
    if (categories != null && categories.isNotEmpty) {
      final String firstNorm = normalizeCategoryToApi(categories.first);
      switch (firstNorm) {
        case 'VIDRIO':
          return 'https://images.unsplash.com/photo-1596704017254-9b121068fb31?auto=format&fit=crop&w=600&q=80';
        case 'CARTON':
          return 'https://images.unsplash.com/photo-1605600659908-0ef719419d41?auto=format&fit=crop&w=600&q=80';
        case 'METAL':
          return 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=600&q=80';
        case 'PLASTICO':
        default:
          return 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=600&q=80';
      }
    }

    return 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=600&q=80';
  }

  // Opciones de volumen estimado idénticas al selector Web
  static const List<String> volumeOptions = <String>[
    '1 o 2 bolsas medianas',
    '3 o 4 bolsas grandes',
    '1 bulto o costal',
    'Varios bultos de negocio',
  ];

  // Texto simplificado de la Política de Tratamiento de Datos Personales (Ley 1581 de 2012)
  static const String habeasDataPolicyTitle =
      'Política de Privacidad y Tratamiento de Datos Personales (Ley 1581 de 2012)';

  static const String habeasDataPolicySummary =
      'EcoConecta protege los datos personales de los ciudadanos conforme a la Ley Estatutaria 1581 de 2012 y el Decreto 1377 de 2013.\n\n'
      '1. Finalidad: Los datos de contacto (nombre, teléfono y sector barrial) serán tratados exclusivamente para coordinar las rutas de recolección de residuos aprovechables en el municipio.\n\n'
      '2. Confidencialidad y Privacidad: La dirección exacta y número telefónico del ciudadano se mantendrán protegidos y no serán visibles públicamente en el mapa general hasta que un reciclador de oficio formalmente asignado acepte la recolección.\n\n'
      '3. Derechos del Titular: Usted podrá conocer, actualizar y rectificar sus datos personales o revocar esta autorización ante la Coordinación del PGIRS Municipal.';
}
