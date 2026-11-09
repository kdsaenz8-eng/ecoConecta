/// Pruebas de Widget (TDD) para LoginScreen en Flutter.
/// Valida que la pantalla unificada de ingreso reproduzca la identidad visual de la web:
/// Emblema de reciclaje, títulos, indicador de red activa, selector de pestañas (Iniciar sesión / Registrarme)
/// y las 3 tarjetas de acceso rápido para roles reales (Generador, Reciclador y Administrador PGIRS).
library;

import 'package:ecoconecta_frontend/core/theme/app_theme.dart';
import 'package:ecoconecta_frontend/features/auth/data/auth_service.dart';
import 'package:ecoconecta_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthService extends Fake implements AuthService {
  String? lastLoginEmail;
  String? lastLoginPassword;

  @override
  Future<AuthSessionResult> login({
    required String email,
    required String password,
  }) async {
    lastLoginEmail = email;
    lastLoginPassword = password;

    String role = 'GENERADOR';
    if (email.contains('recicladoresuraba')) {
      role = 'RECICLADOR';
    } else if (email.contains('alcaldia')) {
      role = 'ADMINISTRADOR';
    }

    return AuthSessionResult(
      accessToken: 'mock_jwt_token_test_123',
      role: role,
      fullName: 'Usuario Prueba',
      email: email,
      neighborhood: 'Barrio Kennedy',
    );
  }
}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createSubject() {
    return MaterialApp(
      theme: AppTheme.accessibleTheme,
      home: LoginScreen(authService: mockAuthService),
    );
  }

  testWidgets(
    'LoginScreen muestra emblema de reciclaje, marca EcoConecta y estado de red activa',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('EcoConecta'), findsWidgets);
      expect(
        find.text(
          'Diseño e implementación de una plataforma digital para optimizar la coordinación de la recolección de residuos aprovechables en el municipio de Chigorodó, Antioquia.',
        ),
        findsOneWidget,
      );
      expect(find.text('Red activa en el municipio'), findsOneWidget);
      expect(find.byIcon(Icons.recycling), findsWidgets);
    },
  );

  testWidgets(
    'LoginScreen muestra las pestañas Iniciar sesión y Registrarme',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsWidgets);
      expect(find.text('Registrarme'), findsWidgets);
    },
  );

  testWidgets(
    'LoginScreen muestra las 3 tarjetas de usuarios reales con sus roles y credenciales',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Título de la sección de cuentas reales
      expect(find.text('O selecciona un usuario para iniciar sesión:'), findsOneWidget);
      expect(find.text('Cuentas reales registradas en la base de datos del municipio:'), findsOneWidget);

      // Tarjeta 1: María Fernanda Córdoba (Generador)
      expect(find.text('María Fernanda Córdoba'), findsOneWidget);
      expect(find.textContaining('maria.cordoba@ecoconecta.co'), findsWidgets);
      expect(find.text('Hogar / Negocio'), findsOneWidget);

      // Tarjeta 2: Carlos Andrés Mena (Reciclador)
      expect(find.text('Carlos Andrés Mena'), findsOneWidget);
      expect(find.textContaining('carlos.mena@recicladoresuraba.org'), findsWidgets);
      expect(find.text('Reciclador de Oficio'), findsOneWidget);

      // Tarjeta 3: Coordinador PGIRS Municipio (Admin)
      expect(find.text('Coordinador PGIRS Municipio'), findsOneWidget);
      expect(find.textContaining('pgirs@alcaldia.gov.co'), findsWidgets);
      expect(find.text('Administrador Total'), findsOneWidget);
    },
  );

  testWidgets(
    'Al presionar la tarjeta de Carlos Andrés Mena autentica al Reciclador',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final Finder carlosCard = find.text('Carlos Andrés Mena');
      await tester.ensureVisible(carlosCard);
      await tester.pumpAndSettle();
      await tester.tap(carlosCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(mockAuthService.lastLoginEmail, 'carlos.mena@recicladoresuraba.org');
      expect(mockAuthService.lastLoginPassword, 'EcoPassword2026');
    },
  );
}

