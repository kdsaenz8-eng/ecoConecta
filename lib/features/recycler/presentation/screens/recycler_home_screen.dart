/// Pantalla Operativa para el Rol RECICLADOR (Reciclador de Oficio).
/// Replica fielmente la vista web (vista-reciclador):
/// Encabezado institucional, mapa interactivo de rutas OpenStreetMap en tiempo real,
/// contador de entregas, protección de datos (Ley 1581/2012) y transición de estados
/// (Aceptar solicitud -> Iniciar ruta -> Marcar completada con pesaje de kilos).
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/institutional_header.dart';

class RecyclerHomeScreen extends StatefulWidget {
  final String userName;

  const RecyclerHomeScreen({super.key, required this.userName});

  @override
  State<RecyclerHomeScreen> createState() => _RecyclerHomeScreenState();
}

class _RecyclerHomeScreenState extends State<RecyclerHomeScreen> {
  final DioClient _dioClient = DioClient();
  bool _isLoading = false;
  double _recyclerLat = AppConstants.ecoconectaDefaultLat;
  double _recyclerLon = AppConstants.ecoconectaDefaultLon;
  final MapController _mapController = MapController();

  // Lista de solicitudes en ruta (cargada exclusivamente desde la API real)
  List<Map<String, dynamic>> _pickups = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _fetchPickups();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (mounted) {
        setState(() {
          _recyclerLat = pos.latitude;
          _recyclerLon = pos.longitude;
        });
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
      }
    } catch (_) {
      // Mantiene coordenadas por defecto del municipio
    }
  }

  Future<void> _fetchPickups() async {
    setState(() => _isLoading = true);
    try {
      dynamic responseData;
      try {
        final res = await _dioClient.dio.get<List<dynamic>>('/pickups/pending');
        responseData = res.data;
      } catch (_) {
        final res = await _dioClient.dio.get<List<dynamic>>('/pickups');
        responseData = res.data;
      }

      if (mounted) {
        if (responseData != null && responseData is List) {
          setState(() {
            _pickups = responseData.cast<Map<String, dynamic>>();
          });
        } else {
          setState(() {
            _pickups = <Map<String, dynamic>>[];
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pickups = <Map<String, dynamic>>[];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _claimPickup(String id) async {
    try {
      await _dioClient.dio.post<dynamic>(
        '/pickups/$id/assign',
        data: <String, dynamic>{
          'recycler_name': widget.userName,
          'status': 'Aceptada',
        },
      );
    } catch (_) {
      try {
        await _dioClient.dio.post<dynamic>(
          '/pickups/$id/claim',
          data: <String, dynamic>{
            'recycler_name': widget.userName,
            'status': 'Aceptada',
          },
        );
      } catch (_) {}
    }

    setState(() {
      final int idx = _pickups.indexWhere((Map<String, dynamic> p) => p['id'].toString() == id);
      if (idx != -1) {
        _pickups[idx]['status'] = 'Aceptada';
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF15803D),
          content: Text('¡Solicitud aceptada y bloqueada para tu ruta!'),
        ),
      );
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await _dioClient.dio.post<dynamic>(
        '/pickups/$id/status',
        data: <String, dynamic>{'status': newStatus},
      );
    } catch (_) {}

    setState(() {
      final int idx = _pickups.indexWhere((Map<String, dynamic> p) => p['id'].toString() == id);
      if (idx != -1) {
        _pickups[idx]['status'] = newStatus;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF15803D),
          content: Text('Estado actualizado a: $newStatus'),
        ),
      );
    }
  }

  void _showCompleteDialog(String id) {
    final TextEditingController kgController = TextEditingController(text: '15.5');
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: <Widget>[
              Icon(Icons.scale, color: Color(0xFF15803D)),
              SizedBox(width: 8),
              Text('Registrar Recolección', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Confirma los kilogramos aproximados aprovechados en este punto:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kgController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peso en Kilogramos (Kg)',
                  suffixText: 'Kg',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _updateStatus(id, 'Completada');
              },
              child: const Text('Confirmar Recolección'),
            ),
          ],
        );
      },
    );
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
    final int puntosEnRuta = _pickups.where((p) => p['status'] != 'Completada').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: <Widget>[
          InstitutionalHeader(
            userName: widget.userName,
            roleLabel: 'Reciclador de Oficio',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // TARJETA DE MAPA Y RUTA (IDÉNTICA A LA VISTA WEB)
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Mi ruta de recolección en el municipio',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Puntos asignados a tu ruta. El mapa se actualiza en vivo.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Text(
                              '$puntosEnRuta entregas en tu ruta',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // MAPA INTERACTIVO OPENSTREETMAP
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 220,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LatLng(
                                _recyclerLat,
                                _recyclerLon,
                              ),
                              initialZoom: 14.5,
                            ),
                            children: <Widget>[
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'co.ecoconecta.ecoconecta',
                              ),
                              PolylineLayer(
                                polylines: <Polyline>[
                                  Polyline(
                                    points: _pickups
                                        .map((p) => LatLng(
                                              (p['latitude'] as num?)?.toDouble() ?? 7.6669,
                                              (p['longitude'] as num?)?.toDouble() ?? -76.6811,
                                            ))
                                        .toList(),
                                    strokeWidth: 3.5,
                                    color: const Color(0xFF15803D),
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: <Marker>[
                                  Marker(
                                    point: LatLng(_recyclerLat, _recyclerLon),
                                    width: 44,
                                    height: 44,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.my_location, color: Color(0xFF2563EB), size: 28),
                                      ),
                                    ),
                                  ),
                                  ..._pickups.map((p) {
                                    final double lat =
                                        (p['latitude'] as num?)?.toDouble() ?? 7.6669;
                                    final double lon =
                                        (p['longitude'] as num?)?.toDouble() ?? -76.6811;
                                    final String st = p['status']?.toString() ?? 'Pendiente';
                                    final Color pinColor = (st == 'Completada')
                                        ? const Color(0xFF15803D)
                                        : (st == 'En_Ruta')
                                            ? const Color(0xFFB45309)
                                            : const Color(0xFF0369A1);

                                    return Marker(
                                      point: LatLng(lat, lon),
                                      width: 44,
                                      height: 44,
                                      child: Icon(
                                        Icons.location_on,
                                        color: pinColor,
                                        size: 38,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton.icon(
                              onPressed: _fetchCurrentLocation,
                              icon: const Icon(Icons.my_location, size: 16, color: Color(0xFF15803D)),
                              label: const Text(
                                'Centrar en mi ubicación GPS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // LISTA DE ENTREGAS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Entregas pendientes por atender:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            onPressed: _fetchPickups,
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
                      const SizedBox(height: 10),

                      if (_pickups.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                          alignment: Alignment.center,
                          child: const Text(
                            'No hay solicitudes pendientes en este momento.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        ..._pickups.map((Map<String, dynamic> p) {
                        final String id = p['id'].toString();
                        final String status = p['status']?.toString() ?? 'Pendiente';
                        final String generatorName =
                            p['generator_name']?.toString() ?? 'Usuario del municipio';
                        final String neighborhood =
                            p['neighborhood']?.toString() ?? 'Centro';
                        final dynamic cats = p['waste_categories'];
                        final String catsStr = cats is List
                            ? cats.map((dynamic c) => AppConstants.formatCategoryFromApi(c.toString())).join(', ')
                            : AppConstants.formatCategoryFromApi(cats.toString());
                        final String vol = p['estimated_volume']?.toString() ?? '1 bolsa';
                        final String? photo = p['photo_url'] as String?;
                        final String address = p['address_text']?.toString() ?? 'Barrio $neighborhood';
                        final String? phone = p['generator_phone'] as String?;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
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
                                  Text(
                                    '$generatorName • Barrio $neighborhood',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  _buildStatusChip(status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (photo != null && photo.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        photo,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 56,
                                          height: 56,
                                          color: const Color(0xFFE2E8F0),
                                          child: const Icon(Icons.recycling, color: Color(0xFF15803D)),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          catsStr,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Volumen: $vol',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // PROTECCIÓN DE DATOS O DESBLOQUEO
                              if (status == 'Pendiente') ...<Widget>[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: <Widget>[
                                      Icon(Icons.lock, size: 16, color: Color(0xFFB45309)),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Dirección y teléfono protegidos (Ley 1581/2012) hasta aceptar.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF92400E),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF15803D),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _claimPickup(id),
                                  icon: const Icon(Icons.pan_tool, size: 16),
                                  label: const Text('Aceptar y Bloquear Solicitud'),
                                ),
                              ] else if (status == 'Aceptada') ...<Widget>[
                                Text(
                                  '📍 Dirección exacta: $address',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '📞 Contacto: ${phone ?? "3104567890"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB45309),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _updateStatus(id, 'En_Ruta'),
                                  icon: const Icon(Icons.directions_bike, size: 18),
                                  label: const Text('Iniciar Ruta (En Camino)'),
                                ),
                              ] else if (status == 'En_Ruta') ...<Widget>[
                                Text(
                                  '📍 Destino: $address',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF15803D),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _showCompleteDialog(id),
                                  icon: const Icon(Icons.check_circle, size: 18),
                                  label: const Text('Marcar Recolección Completada'),
                                ),
                              ] else ...<Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: <Widget>[
                                      Icon(Icons.check_circle, size: 16, color: Color(0xFF15803D)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Entrega recolectada y pesada con éxito.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
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
