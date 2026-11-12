/// Pruebas unitarias y de widgets (TDD) para validar que no existan datos simulados
/// y que las pantallas muestren los estados vacíos limpios ante colecciones vacías de la API.
library;

import 'package:ecoconecta_frontend/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'AdminDashboardScreen muestra estados vacíos ante colecciones vacías sin datos simulados',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminDashboardScreen(userName: 'Coordinador PGIRS'),
          ),
        ),
      );
      await tester.pump();

      // Verifica que no aparezcan datos simulados antiguos
      expect(find.text('SOL-01'), findsNothing);
      expect(find.text('SOL-02'), findsNothing);
      expect(find.text('SOL-03'), findsNothing);

      // Verifica que se muestre el estado vacío formal
      expect(find.text('No hay solicitudes registradas.'), findsOneWidget);
      expect(find.text('No hay registros de auditoría reportados.'), findsOneWidget);
    },
  );
}
