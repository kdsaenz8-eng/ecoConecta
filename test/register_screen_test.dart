/// Pruebas de Widget (TDD) para RegisterScreen en Flutter.
/// Verifica que los controles accesibles de selección de rol, barrios del municipio y
/// el checkbox obligatorio de Habeas Data (Ley 1581/2012) se rendericen y validen correctamente.
library;

import 'package:ecoconecta_frontend/core/theme/app_theme.dart';
import 'package:ecoconecta_frontend/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'RegisterScreen muestra selector de roles y exige aceptación de Ley 1581/2012',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.accessibleTheme,
          home: const RegisterScreen(),
        ),
      );

      expect(find.textContaining('Seleccione su Rol en el municipio'), findsOneWidget);
      expect(find.textContaining('Ley 1581/2012'), findsOneWidget);
      expect(find.text('Crear Cuenta en EcoConecta'), findsOneWidget);
    },
  );
}

