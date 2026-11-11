/// punto de entrada principal de la aplicación móvil EcoConecta (Flutter 3.22+ / Dart 3).
library;

import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EcoConectaApp());
}

class EcoConectaApp extends StatelessWidget {
  const EcoConectaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.accessibleTheme,
      home: const LoginScreen(),
    );
  }
}
