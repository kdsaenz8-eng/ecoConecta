/// Componente de Encabezado Institucional Unificado de EcoConecta.
/// Idéntico a la cabecera visual de la plataforma Web (index.html).
/// Muestra el emblema circular ♻, títulos de la alcaldía, indicador de red activa,
/// chip con nombre/rol del usuario y botón de cerrar sesión.
library;

import 'package:flutter/material.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

class InstitutionalHeader extends StatelessWidget {
  final String userName;
  final String roleLabel;
  final VoidCallback? onLogout;

  const InstitutionalHeader({
    super.key,
    required this.userName,
    required this.roleLabel,
    this.onLogout,
  });

  Future<void> _handleLogout(BuildContext context) async {
    if (onLogout != null) {
      onLogout!();
      return;
    }
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 400;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            // Fila 1: Marca + Red activa
            Row(
              children: <Widget>[
                Container(
                  width: isCompact ? 34 : 38,
                  height: isCompact ? 34 : 38,
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
                      size: isCompact ? 20 : 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                          fontSize: isCompact ? 16 : 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Coordinación de reciclaje municipal',
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 7 : 8,
                    vertical: isCompact ? 3.5 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompact ? 'Red activa' : 'Red activa en el municipio',
                        style: TextStyle(
                          fontSize: isCompact ? 10 : 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Fila 2: Chip de usuario + botón salir
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.person, size: 16, color: Color(0xFF15803D)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '• $roleLabel',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    foregroundColor: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFFEE2E2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout, size: 14),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

