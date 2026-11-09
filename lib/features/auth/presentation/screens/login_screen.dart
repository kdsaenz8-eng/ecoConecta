/// Pantalla de Inicio de Sesión (frontend/lib/features/auth/presentation/screens/login_screen.dart).
/// Permite autenticar usuarios existentes y redirigirlos automáticamente según su rol
/// (`GENERADOR`, `RECICLADOR` o `ADMINISTRADOR`).
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../generator/presentation/screens/generator_home_screen.dart';
import '../../../recycler/presentation/screens/recycler_home_screen.dart';
import '../../data/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;

  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final AuthService _authService;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final AuthSessionResult session = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (session.role == 'RECICLADOR') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RecyclerHomeScreen(userName: session.fullName),
          ),
        );
      } else if (session.role == 'ADMINISTRADOR') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => AdminDashboardScreen(userName: session.fullName),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => GeneratorHomeScreen(
              userName: session.fullName,
              neighborhood: session.neighborhood,
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.errorRed,
          content: Text(e.message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresar a EcoConecta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Icon(
                  Icons.recycling,
                  size: 64,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Coordinación de Reciclaje en el municipio',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (String? val) =>
                      (val == null || !val.contains('@'))
                          ? 'Ingrese un correo electrónico válido.'
                          : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (String? val) =>
                      (val == null || val.isEmpty) ? 'Ingrese su contraseña.' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitLogin,
                  icon: const Icon(Icons.login),
                  label: Text(_isLoading ? 'Verificando...' : 'Iniciar Sesión'),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('¿No tienes cuenta? Regístrate aquí'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

