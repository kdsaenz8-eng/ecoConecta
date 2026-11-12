/// Pantalla Operativa para el Rol ADMINISTRADOR (Coordinador PGIRS).
/// Replica fielmente la vista web (vista-administrador):
/// Encabezado institucional, indicadores clave de gestión municipal (Hogares vinculados y Recicladores activos),
/// tabla/lista de solicitudes con asignación directa de rutas a recicladores y auditoría de Habeas Data (Ley 1581/2012).
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/institutional_header.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String userName;
  final DioClient? dioClient;
  final bool autoLoad;

  const AdminDashboardScreen({
    super.key,
    required this.userName,
    this.dioClient,
    this.autoLoad = true,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final DioClient _dioClient;
  bool _isLoading = false;

  int _conteoGeneradores = 0;
  int _conteoRecicladores = 0;

  // Directorio cargado dinámicamente desde la API real
  List<Map<String, dynamic>> _recicladores = <Map<String, dynamic>>[];

  // Solicitudes cargadas desde la API real
  List<Map<String, dynamic>> _solicitudes = <Map<String, dynamic>>[];

  // Registro de auditoría cargado desde la API real
  List<Map<String, dynamic>> _auditLogs = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _dioClient = widget.dioClient ?? DioClient();
    if (widget.autoLoad) {
      _loadAllData();
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Cargar métricas
      try {
        final metricsResp = await _dioClient.dio.get<Map<String, dynamic>>('/metrics/pgirs-summary');
        if (metricsResp.data != null) {
          final roles = metricsResp.data!['users_by_role'] as Map<String, dynamic>?;
          if (roles != null) {
            setState(() {
              _conteoGeneradores = (roles['GENERADOR'] as num?)?.toInt() ?? 0;
              _conteoRecicladores = (roles['RECICLADOR'] as num?)?.toInt() ?? 0;
            });
          }
        }
      } catch (_) {}

      // 2. Directorio real de recicladores del municipio desde la API
      try {
        final recResp = await _dioClient.dio.get<List<dynamic>>('/users/recyclers');
        if (recResp.data != null && recResp.data is List) {
          setState(() {
            _recicladores = recResp.data!.cast<Map<String, dynamic>>();
            _conteoRecicladores = _recicladores.length;
          });
        }
      } catch (_) {}

      // 3. Cargar solicitudes
      try {
        dynamic pickupsData;
        try {
          final res = await _dioClient.dio.get<List<dynamic>>('/pickups');
          pickupsData = res.data;
        } catch (_) {
          final res = await _dioClient.dio.get<List<dynamic>>('/pickups/pending');
          pickupsData = res.data;
        }
        if (pickupsData != null && pickupsData is List) {
          setState(() {
            _solicitudes = pickupsData.cast<Map<String, dynamic>>();
          });
        } else {
          setState(() {
            _solicitudes = <Map<String, dynamic>>[];
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _solicitudes = <Map<String, dynamic>>[];
          });
        }
      }

      // 4. Cargar auditoría
      final auditResp = await _dioClient.dio.get<List<dynamic>>('/audit/logs');
      if (auditResp.data != null && auditResp.data!.isNotEmpty) {
        setState(() {
          _auditLogs = auditResp.data!.map((item) {
            final log = item as Map<String, dynamic>;
            return {
              'fecha': log['created_at']?.toString() ?? 'Reciente',
              'usuario': 'Usuario ID: ${log['user_id']}',
              'detalle': log['details']?.toString() ?? 'Aceptación Ley 1581/2012',
              'hash': 'ID: ${log['id']}',
            };
          }).toList();
        });
      }
    } catch (_) {
      // Mantiene datos locales de respaldo
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _asignarReciclador(String pickupId, String recyclerId, String recyclerName) async {
    try {
      await _dioClient.dio.post<dynamic>(
        '/pickups/$pickupId/assign',
        queryParameters: <String, dynamic>{'recycler_id': recyclerId},
        data: <String, dynamic>{
          'recycler_id': recyclerId,
          'status': 'Aceptada',
        },
      );

      setState(() {
        final int idx = _solicitudes.indexWhere((p) => p['id'].toString() == pickupId);
        if (idx != -1) {
          _solicitudes[idx]['recycler_id'] = recyclerId;
          _solicitudes[idx]['recycler_name'] = recyclerName;
          _solicitudes[idx]['status'] = 'Aceptada';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF15803D),
            content: Text('Ruta asignada con éxito a: $recyclerName'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Error al asignar reciclador: $e'),
          ),
        );
      }
    }
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label = status;

    if (status == 'Aceptada' || status == 'Aceptado') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
      label = 'Aceptada';
    } else if (status == 'En_Ruta' || status == 'En Camino' || status == 'EN_CAMINO') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      label = 'En Camino';
    } else if (status == 'Completada' || status == 'COMPLETADA') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      label = 'Completada';
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
      label = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: <Widget>[
          InstitutionalHeader(
            userName: widget.userName,
            roleLabel: 'Coordinador PGIRS',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // RESUMEN DE GESTIÓN MUNICIPAL (2 TARJETAS EN FILA)
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Hogares y comercios vinculados',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_conteoGeneradores',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Recicladores de oficio activos',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_conteoRecicladores',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D6A4F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // TODAS LAS SOLICITUDES Y ASIGNACIÓN DIRECTA
                Container(
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
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Todas las solicitudes de recolección',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            onPressed: _loadAllData,
                            tooltip: 'Actualizar solicitudes',
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, color: Color(0xFF15803D)),
                          ),
                        ],
                      ),
                      const Text(
                        'Supervisa las solicitudes de los barrios y asígnalas al reciclador que cubre cada sector.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 14),

                      if (_solicitudes.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          alignment: Alignment.center,
                          child: const Text(
                            'No hay solicitudes de recolección en el sistema municipal.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        ..._solicitudes.map((Map<String, dynamic> s) {
                        final String pId = s['id'].toString();
                        final String genName = s['generator_name']?.toString() ?? 'Ciudadano';
                        final String address = s['address_text']?.toString() ?? 'Municipio';
                        final dynamic cats = s['waste_categories'];
                        final String catsStr = cats is List
                            ? cats.map((dynamic c) => AppConstants.formatCategoryFromApi(c.toString())).join(', ')
                            : AppConstants.formatCategoryFromApi(cats.toString());
                        final String vol = s['estimated_volume']?.toString() ?? '1 bolsa';
                        final String status = s['status']?.toString() ?? 'Pendiente';
                        final String recName = s['recycler_name']?.toString() ?? 'Pendiente de asignar';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      genName,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  _buildStatusChip(status),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                address,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      '$catsStr • $vol',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.directions_bike, size: 16, color: Color(0xFF15803D)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Reciclador: $recName',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // SELECTOR DIRECTO DE ASIGNACIÓN
                              Row(
                                children: <Widget>[
                                  const Text(
                                    'Asignar ruta:',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: _recicladores.any((r) => r['id'].toString() == (p['recycler_id']?.toString() ?? ''))
                                              ? p['recycler_id']?.toString()
                                              : null,
                                          hint: const Text(
                                            'Seleccionar reciclador...',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          items: _recicladores.map((r) {
                                            final String rId = r['id'].toString();
                                            final String rName =
                                                r['full_name'] ?? r['nombre'] ?? 'Reciclador';
                                            return DropdownMenuItem<String>(
                                              value: rId,
                                              child: Text(
                                                rName,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (String? selectedRecId) {
                                            if (selectedRecId != null) {
                                              final selectedRec = _recicladores.firstWhere(
                                                (r) => r['id'].toString() == selectedRecId,
                                              );
                                              final String rName = selectedRec['full_name'] ??
                                                  selectedRec['nombre'] ??
                                                  'Reciclador';
                                              _asignarReciclador(pId, selectedRecId, rName);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // REGISTRO DE PROTECCIÓN DE DATOS (LEY 1581)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Registro de protección de datos (Ley 1581)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Trazabilidad de aceptación de política de privacidad por ciudadano.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _auditLogs.isEmpty
                              ? <Widget>[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'No hay registros de auditoría reportados.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ]
                              : _auditLogs.map((log) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            const Icon(Icons.verified_user, size: 14, color: Color(0xFF15803D)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${log['fecha']} — ${log['usuario']}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${log['detalle']} • ${log['hash']}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                        const Divider(height: 12, color: Color(0xFFE2E8F0)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
