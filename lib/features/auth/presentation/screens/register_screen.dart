/// Pantalla de Registro Público e Inclusivo (frontend/lib/features/auth/presentation/screens/register_screen.dart).
/// Cumple con WCAG 2.2 AA (alto contraste #2E7D32 / #F9FBF9 / #1A1A1A, botones >= 50dp),
/// selección visual de rol mediante tarjetas grandes e implementación estricta de la Ley 1581 de 2012.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/auth_service.dart';
import '../../../generator/presentation/screens/generator_home_screen.dart';
import '../../../recycler/presentation/screens/recycler_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService? authService;

  const RegisterScreen({super.key, this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final AuthService _authService;

  // Controladores de formulario
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Estado del selector de rol y barrio en el municipio
  String _selectedRole = 'GENERADOR';
  String _selectedUserTypeDetail = 'HOGAR';
  String _selectedNeighborhood = AppConstants.ecoconectaNeighborhoods.first;
  bool _habeasDataAccepted = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectRole(String role, String defaultDetail) {
    setState(() {
      _selectedRole = role;
      _selectedUserTypeDetail = defaultDetail;
    });
  }

  /// Despliega el diálogo modal con el texto simplificado de la Política de Tratamiento
  /// de Datos Personales conforme a la Ley 1581 de 2012.
  Future<void> _showHabeasDataModal() async {
    final bool? acceptedInModal = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: <Widget>[
              Icon(Icons.verified_user, color: AppTheme.primaryGreen, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppConstants.habeasDataPolicyTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              AppConstants.habeasDataPolicySummary,
              style: TextStyle(fontSize: 15, height: 1.45),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 50),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Acepto la Política'),
            ),
          ],
        );
      },
    );

    if (acceptedInModal == true && mounted) {
      setState(() {
        _habeasDataAccepted = true;
      });
    }
  }

  /// Ejecuta el registro contra el Backend FastAPI, almacena el JWT en FlutterSecureStorage
  /// y redirige automáticamente según el rol autenticado (`GENERADOR` vs `RECICLADOR`).
  Future<void> _handleRegisterSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_habeasDataAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.errorRed,
          content: Text(
            'Es obligatorio autorizar el tratamiento de datos personales (Ley 1581/2012).',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final AuthSessionResult session = await _authService.registerUser(
        fullName: _fullNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        role: _selectedRole,
        userTypeDetail: _selectedUserTypeDetail,
        neighborhood: _selectedNeighborhood,
        addressReference: _addressController.text,
        habeasDataAccepted: _habeasDataAccepted,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryGreen,
          content: Text('¡Bienvenido a EcoConecta, ${session.fullName}!'),
        ),
      );

      // Redirección automática según el rol del usuario autenticado
      if (session.role == 'RECICLADOR') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RecyclerHomeScreen(userName: session.fullName),
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
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro en EcoConecta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  '1. Seleccione su Rol en el municipio',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.highContrastText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Elija cómo participará en la cadena de aprovechamiento de residuos:',
                  style: TextStyle(fontSize: 15, color: AppTheme.highContrastText),
                ),
                const SizedBox(height: 14),

                // Tarjetas interactivas grandes para selección de Rol (Accesibilidad WCAG 2.2)
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _RoleSelectCard(
                        title: 'Generador\n(Hogar / Comercio)',
                        subtitle: 'Entrego material reciclable limpio',
                        icon: Icons.home_work_outlined,
                        isSelected: _selectedRole == 'GENERADOR',
                        onTap: () => _selectRole('GENERADOR', 'HOGAR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleSelectCard(
                        title: 'Reciclador\nde Oficio',
                        subtitle: 'Recolecto material en rutas y barrios',
                        icon: Icons.recycling,
                        isSelected: _selectedRole == 'RECICLADOR',
                        onTap: () =>
                            _selectRole('RECICLADOR', 'RECICLADOR_INDEPENDIENTE'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Selector de subtipo (Hogar vs Comercio / Independiente vs Asociación)
                Wrap(
                  spacing: 10,
                  children: _selectedRole == 'GENERADOR'
                      ? <Widget>[
                          ChoiceChip(
                            label: const Text('Hogar / Vivienda'),
                            selected: _selectedUserTypeDetail == 'HOGAR',
                            onSelected: (_) =>
                                setState(() => _selectedUserTypeDetail = 'HOGAR'),
                          ),
                          ChoiceChip(
                            label: const Text('Comercio / Negocio'),
                            selected: _selectedUserTypeDetail == 'COMERCIO',
                            onSelected: (_) =>
                                setState(() => _selectedUserTypeDetail = 'COMERCIO'),
                          ),
                        ]
                      : <Widget>[
                          ChoiceChip(
                            label: const Text('Reciclador Independiente'),
                            selected:
                                _selectedUserTypeDetail == 'RECICLADOR_INDEPENDIENTE',
                            onSelected: (_) => setState(
                              () => _selectedUserTypeDetail =
                                  'RECICLADOR_INDEPENDIENTE',
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Asociación / Agremiado'),
                            selected: _selectedUserTypeDetail == 'ASOCIACION',
                            onSelected: (_) => setState(
                              () => _selectedUserTypeDetail = 'ASOCIACION',
                            ),
                          ),
                        ],
                ),
                const SizedBox(height: 24),

                const Text(
                  '2. Datos de Contacto y Ubicación',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.highContrastText,
                  ),
                ),
                const SizedBox(height: 14),

                // Nombre completo o Razón Social
                TextFormField(
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo o Razón social *',
                    hintText: 'Ej. María Córdoba o Tienda El Sol',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Ingrese su nombre completo o razón social (mínimo 3 letras).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Teléfono con teclado numérico
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Teléfono celular de contacto *',
                    hintText: 'Ej. 3101234567',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().length < 7) {
                      return 'Ingrese un número telefónico válido de contacto.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Correo electrónico
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico *',
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (String? value) {
                    final String email = (value ?? '').trim();
                    final RegExp emailRegex =
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(email)) {
                      return 'Ingrese un correo electrónico válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Desplegable de Barrios del municipio
                DropdownButtonFormField<String>(
                  initialValue: _selectedNeighborhood,
                  decoration: const InputDecoration(
                    labelText: 'Sector / Barrio en el municipio *',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: AppConstants.ecoconectaNeighborhoods
                      .map(
                        (String barrio) => DropdownMenuItem<String>(
                          value: barrio,
                          child: Text(barrio),
                        ),
                      )
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedNeighborhood = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Dirección y punto de referencia
                TextFormField(
                  controller: _addressController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Dirección o referencia en el barrio *',
                    hintText: 'Ej. Calle 98 # 102-15, frente a la cancha',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().length < 5) {
                      return 'Indique una dirección o referencia clara (mínimo 5 caracteres).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contraseña segura (mínimo 8 caracteres, alfanumérica)
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña segura (mín. 8 caracteres) *',
                    hintText: 'Combine letras y números',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (String? value) {
                    final String pass = (value ?? '').trim();
                    if (pass.length < 8) {
                      return 'La contraseña debe tener mínimo 8 caracteres.';
                    }
                    final bool hasLetter = RegExp(r'[A-Za-z]').hasMatch(pass);
                    final bool hasNumber = RegExp(r'\d').hasMatch(pass);
                    if (!hasLetter || !hasNumber) {
                      return 'La contraseña debe incluir letras y números.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                // Checkbox vinculante de Habeas Data (Ley 1581 de 2012)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _habeasDataAccepted
                          ? AppTheme.primaryGreen
                          : const Color(0xFF9E9E9E),
                      width: 1.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Material(
                        color: Colors.transparent,
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.primaryGreen,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _habeasDataAccepted,
                          onChanged: (bool? checked) {
                            setState(() {
                              _habeasDataAccepted = checked ?? false;
                            });
                          },
                          title: const Text(
                            'Autorizo el tratamiento de mis datos de contacto para la coordinación del reciclaje en el municipio (Ley 1581/2012)',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.highContrastText,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _showHabeasDataModal,
                          icon: const Icon(Icons.policy_outlined, size: 20),
                          label: const Text(
                            'Leer Política de Tratamiento de Datos Personales (Ley 1581)',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón principal accesible (altura mínima >= 50dp)
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleRegisterSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 24),
                    label: Text(
                      _isSubmitting
                          ? 'Registrando cuenta...'
                          : 'Crear Cuenta en EcoConecta',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta interactiva accesible para selección de rol (Generador vs Reciclador).
class _RoleSelectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 148),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : const Color(0xFFBDBDBD),
              width: isSelected ? 3.0 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 40,
                color: isSelected
                    ? AppTheme.primaryGreen
                    : const Color(0xFF424242),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? AppTheme.secondaryAccent
                      : AppTheme.highContrastText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.highContrastText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

