/// Constantes normativas (Resolución 2184 de 2019 y Ley 1581 de 2012),
/// sectores barriales del municipio (Antioquia) y configuración de endpoints API.
library;

import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'EcoConecta';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  // Coordenadas centrales de referencia: Parque Principal del municipio, Antioquia
  static const double ecoconectaDefaultLat = 7.6669;
  static const double ecoconectaDefaultLon = -76.6811;

  // Barrios representativos del municipio del municipio
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

  // Categorías de Bolsa Blanca según Resolución 2184 de 2019
  static const List<Map<String, dynamic>> res2184WasteCategories = <Map<String, dynamic>>[
    {
      'code': 'PLASTICO',
      'label': 'Plástico (Botellas PET, Envases)',
      'icon': Icons.local_drink_outlined,
    },
    {
      'code': 'CARTON',
      'label': 'Papel y Cartón Limpio',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'code': 'VIDRIO',
      'label': 'Vidrio (Botellas, Frascos)',
      'icon': Icons.wine_bar_outlined,
    },
    {
      'code': 'METAL',
      'label': 'Metal (Latas de Aluminio, Chatarra)',
      'icon': Icons.hardware_outlined,
    },
  ];

  // Opciones rápidas de volumen estimado (Baja carga cognitiva)
  static const List<String> volumeOptions = <String>[
    '1 a 2 bolsas medianas',
    '3 a 4 bolsas grandes',
    '1 bulto / costal completo',
    'Más de 2 bultos (Comercio / Acopio)',
  ];

  // Texto simplificado de la Política de Tratamiento de Datos Personales (Ley 1581 de 2012)
  static const String habeasDataPolicyTitle =
      'Política de Privacidad y Tratamiento de Datos Personales (Ley 1581 de 2012)';

  static const String habeasDataPolicySummary = '''
En cumplimiento de la Ley Estatutaria 1581 de 2012 y el Decreto 1377 de 2013 (Régimen de Protección de Datos Personales de Colombia), EcoConecta informa:

1. Finalidad Exclusiva: Sus datos de identificación, teléfono, barrio y coordenadas GPS se recolectan única y exclusivamente para coordinar la entrega y recolección de residuos sólidos aprovechables entre habitantes/comercios (Generadores) y Recicladores de Oficio en el municipio del municipio, Antioquia.

2. Privacidad por Diseño en el Mapa: Mientras su solicitud de recolección se encuentre en estado PENDIENTE, los recicladores solo verán su barrio aproximado y el tipo de material reciclable. Su dirección exacta y número telefónico permanecerán ocultos y solo se revelarán al reciclador verificado que acepte y bloquee formalmente su solicitud.

3. Derechos ARCO (Habeas Data): Como titular de los datos, usted tiene derecho a conocer, actualizar, rectificar y solicitar la supresión de su información personal o revocar esta autorización en cualquier momento desde su perfil.

4. Auditoría: Al marcar la casilla de aceptación, el sistema registra de forma inmutable la fecha, hora UTC y versión de esta política como soporte legal de su consentimiento previo, expreso e informado.
''';
}

