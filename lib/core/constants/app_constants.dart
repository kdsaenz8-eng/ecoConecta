/// Constantes normativas (Resolución 2184 de 2019 y Ley 1581 de 2012),
/// sectores barriales del municipio (Antioquia) y configuración dinámica de endpoints API.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'EcoConecta';

  static const String prodApiUrl = 'https://ecoconecta.quantumcore.com.co/api/v1';

  /// Determina dinámicamente la URL del Backend según la plataforma y el entorno de exportación:
  /// 1. Prioridad: Variable explícita `--dart-define=API_BASE_URL=...`
  /// 2. En producción / Remoto (APK, Web en ecoconecta.softsaenz.com o cualquier host fuera de localhost):
  ///    SIEMPRE apunta al backend oficial: https://ecoconecta.quantumcore.com.co/api/v1
  /// 3. En desarrollo local (Web en localhost o 127.0.0.1): apunta a http://localhost:8080/api/v1
  static String get baseUrl {
    const String fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kReleaseMode) {
      return prodApiUrl;
    }

    if (kIsWeb) {
      final String host = Uri.base.host;
      // Solo en entorno local de pruebas apuntar a localhost:8080
      if (host == 'localhost' || host == '127.0.0.1' || host.startsWith('192.168.')) {
        return 'http://localhost:8080/api/v1';
      }
      // En cualquier dominio remoto (ej. ecoconecta.softsaenz.com): producción oficial
      return prodApiUrl;
    }

    // Para dispositivos móviles (APK o ejecución física): siempre producción
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
