/// Pantalla de Autenticación Unificada (frontend/lib/features/auth/presentation/screens/login_screen.dart).
/// Replica fielmente la identidad visual, colores y flujo de acceso único de la plataforma Web (index.html).
/// Permite el ingreso por la misma vista a los tres roles del municipio:
/// 1. GENERADOR (Hogar / Negocio)
/// 2. RECICLADOR (Reciclador de Oficio)
/// 3. ADMINISTRADOR (Coordinador PGIRS Alcaldía)
///
/// Incluye selector de pestañas (Iniciar sesión / Registrarme), indicador de Red activa
/// y tarjetas de acceso rápido con las cuentas reales verificadas en la base de datos municipal.
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../generator/presentation/screens/generator_home_screen.dart';
import '../../../recycler/presentation/screens/recycler_home_screen.dart';
import '../../data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;

  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService;

  // Estado de pestañas: 0 = Iniciar sesión, 1 = Registrarme
  int _activeTabIndex = 0;

  // Controladores - Login
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;
  bool _isLoading = false;

  // Controladores - Registro
  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regAddressController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  String _regRole = 'GENERADOR';
  String _regUserTypeDetail = 'HOGAR';
  String _regNeighborhood = AppConstants.ecoconectaNeighborhoods.first;
  bool _regHabeasDataAccepted = false;
  bool _regObscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    // Pre-carga amigable idéntica a la vista web para demostraciones
    _loginEmailController.text = 'maria.cordoba@ecoconecta.co';
    _loginPasswordController.text = 'EcoPassword2026';
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    _regEmailController.dispose();
    _regAddressController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  void _routeByRole(AuthSessionResult session) {
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
  }

  Future<void> _submitLogin({String? emailOverride, String? passwordOverride}) async {
    final String email = emailOverride ?? _loginEmailController.text;
    final String password = passwordOverride ?? _loginPasswordController.text;

    if (emailOverride == null && !_loginFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthSessionResult session = await _authService.login(
        email: email,
        password: password,
      );
      _routeByRole(session);
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

  Future<void> _submitRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    if (!_regHabeasDataAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.errorRed,
          content: Text(
            'Debe autorizar el tratamiento de datos personales (Ley 1581/2012) para continuar.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthSessionResult session = await _authService.registerUser(
        fullName: _regNameController.text,
        email: _regEmailController.text,
        phone: _regPhoneController.text,
        password: _regPasswordController.text,
        role: _regRole,
        userTypeDetail: _regUserTypeDetail,
        neighborhood: _regNeighborhood,
        addressReference: _regAddressController.text,
        habeasDataAccepted: _regHabeasDataAccepted,
      );

      _routeByRole(session);
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

  /// Encabezado institucional idéntico a la barra superior del portal web, adaptable a móvil y escritorio
  Widget _buildBrandHeader() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 400;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: <Widget>[
            // Emblema circular verde con ícono de reciclaje ♻
            Container(
              width: isCompact ? 38 : 44,
              height: isCompact ? 38 : 44,
              decoration: BoxDecoration(
                color: const Color(0xFF15803D),
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF15803D).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.recycling,
                  color: Colors.white,
                  size: isCompact ? 22 : 26,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'EcoConecta',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Diseño e implementación de una plataforma digital para optimizar la coordinación de la recolección de residuos aprovechables en el municipio de Chigorodó, Antioquia.',
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Indicador de red activa responsivo
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 10,
                vertical: isCompact ? 4 : 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isCompact ? 'Red activa' : 'Red activa en el municipio',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pestañas de cambio: Iniciar sesión / Registrarme
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTabIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeTabIndex == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _activeTabIndex == 0
                      ? <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Iniciar sesión',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _activeTabIndex == 0
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTabIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _activeTabIndex == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _activeTabIndex == 1
                      ? <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Registrarme',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _activeTabIndex == 1
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de usuario real para selección instantánea (igual a la vista web)
  Widget _buildRealUserCard({
    required String name,
    required String email,
    required String location,
    required String roleLabel,
    required Color tagTextColor,
    required Color tagBgColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 18,
                backgroundColor: tagBgColor,
                child: Icon(icon, color: tagTextColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$email • $location',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: tagTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Vista de Iniciar Sesión (idéntica a la vista web)
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Ingresa con tu cuenta registrada para coordinar la entrega o recolección de materiales reciclables en el municipio.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'tucorreo@ejemplo.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (String? val) {
              if (val == null || !val.contains('@')) {
                return 'Ingrese un correo electrónico válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() => _obscureLoginPassword = !_obscureLoginPassword);
                },
              ),
            ),
            validator: (String? val) {
              if (val == null || val.isEmpty) {
                return 'Ingrese su contraseña.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _submitLogin(),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Entrar a EcoConecta',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),
          const Text(
            'O selecciona un usuario para iniciar sesión:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Cuentas reales registradas en la base de datos del municipio:',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          // USUARIO 1: GENERADOR
          _buildRealUserCard(
            name: 'María Fernanda Córdoba',
            email: 'maria.cordoba@ecoconecta.co',
            location: 'Barrio Kennedy',
            roleLabel: 'Hogar / Negocio',
            tagTextColor: const Color(0xFF0369A1),
            tagBgColor: const Color(0xFFE0F2FE),
            icon: Icons.home_work_outlined,
            onTap: () {
              _loginEmailController.text = 'maria.cordoba@ecoconecta.co';
              _loginPasswordController.text = 'EcoPassword2026';
              _submitLogin(
                emailOverride: 'maria.cordoba@ecoconecta.co',
                passwordOverride: 'EcoPassword2026',
              );
            },
          ),
          // USUARIO 2: RECICLADOR
          _buildRealUserCard(
            name: 'Carlos Andrés Mena',
            email: 'carlos.mena@recicladoresuraba.org',
            location: 'Barrio El Bosque',
            roleLabel: 'Reciclador de Oficio',
            tagTextColor: const Color(0xFF15803D),
            tagBgColor: const Color(0xFFDCFCE7),
            icon: Icons.recycling_outlined,
            onTap: () {
              _loginEmailController.text = 'carlos.mena@recicladoresuraba.org';
              _loginPasswordController.text = 'EcoPassword2026';
              _submitLogin(
                emailOverride: 'carlos.mena@recicladoresuraba.org',
                passwordOverride: 'EcoPassword2026',
              );
            },
          ),
          // USUARIO 3: ADMINISTRADOR PGIRS
          _buildRealUserCard(
            name: 'Coordinador PGIRS Municipio',
            email: 'pgirs@alcaldia.gov.co',
            location: 'Alcaldía Municipal',
            roleLabel: 'Administrador Total',
            tagTextColor: const Color(0xFFB45309),
            tagBgColor: const Color(0xFFFEF3C7),
            icon: Icons.admin_panel_settings_outlined,
            onTap: () {
              _loginEmailController.text = 'pgirs@alcaldia.gov.co';
              _loginPasswordController.text = 'EcoPassword2026';
              _submitLogin(
                emailOverride: 'pgirs@alcaldia.gov.co',
                passwordOverride: 'EcoPassword2026',
              );
            },
          ),
        ],
      ),
    );
  }

  /// Vista de Registro (idéntica a la sección web)
  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Únete a la red de reciclaje del municipio. Selecciona cómo participas:',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // Selector de perfil: Hogar o Comercio vs Reciclador de Oficio
          Row(
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _regRole = 'GENERADOR';
                      _regUserTypeDetail = 'HOGAR';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _regRole == 'GENERADOR'
                          ? const Color(0xFFF0FDF4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _regRole == 'GENERADOR'
                            ? const Color(0xFF15803D)
                            : const Color(0xFFCBD5E1),
                        width: _regRole == 'GENERADOR' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Hogar o Comercio',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _regRole == 'GENERADOR'
                                ? const Color(0xFF15803D)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Separo material en casa o negocio.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _regRole = 'RECICLADOR';
                      _regUserTypeDetail = 'OFICIO';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _regRole == 'RECICLADOR'
                          ? const Color(0xFFF0FDF4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _regRole == 'RECICLADOR'
                            ? const Color(0xFF15803D)
                            : const Color(0xFFCBD5E1),
                        width: _regRole == 'RECICLADOR' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Reciclador de Oficio',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _regRole == 'RECICLADOR'
                                ? const Color(0xFF15803D)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hago recolección en rutas del municipio.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _regNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre o razón social',
              hintText: 'Ejemplo: Tienda La 98 o Juan Pérez',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (String? val) {
              if (val == null || val.trim().length < 3) {
                return 'Ingrese un nombre válido (mínimo 3 caracteres).';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono celular',
              hintText: '3101234567',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (String? val) {
              if (val == null || val.trim().length < 7) {
                return 'Ingrese un número telefónico válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _regNeighborhood,
            decoration: const InputDecoration(
              labelText: 'Barrio en el municipio',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            items: AppConstants.ecoconectaNeighborhoods.map((String b) {
              return DropdownMenuItem<String>(
                value: b,
                child: Text('Barrio $b'),
              );
            }).toList(),
            onChanged: (String? val) {
              if (val != null) {
                setState(() => _regNeighborhood = val);
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regAddressController,
            decoration: const InputDecoration(
              labelText: 'Dirección o referencia',
              hintText: 'Frente al parque o Calle 100 #20-10',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            validator: (String? val) {
              if (val == null || val.trim().length < 4) {
                return 'Ingrese una dirección o referencia válida.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'tucorreo@ejemplo.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (String? val) {
              if (val == null || !val.contains('@')) {
                return 'Ingrese un correo electrónico válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regPasswordController,
            obscureText: _regObscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña (mínimo 6 caracteres)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _regObscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() => _regObscurePassword = !_regObscurePassword);
                },
              ),
            ),
            validator: (String? val) {
              if (val == null || val.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              value: _regHabeasDataAccepted,
              onChanged: (bool? val) {
                setState(() => _regHabeasDataAccepted = val ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Autorizo el tratamiento de mis datos personales según la Ley 1581 de 2012 y la política del municipio.',
                style: TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitRegister,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Crear mi cuenta en EcoConecta',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 400;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: <Widget>[
          _buildBrandHeader(),
          _buildTabBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: 6,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isCompact ? 16 : 20),
                child: _activeTabIndex == 0 ? _buildLoginForm() : _buildRegisterForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
