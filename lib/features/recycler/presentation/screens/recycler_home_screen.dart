/// Pantalla Operativa para el Rol RECICLADOR (Bandeja de Solicitudes y Mapa OpenStreetMap HU-04).
/// Soporta alternancia entre Vista de Lista y Vista de Mapa (`flutter_map`), muestra distancia en km,
/// protege dirección/teléfono en estado PENDIENTE (Ley 1581/2012) y ejecuta reclamo atómico.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';

class RecyclerHomeScreen extends StatefulWidget {
  final String userName;

  const RecyclerHomeScreen({super.key, required this.userName});

  @override
  State<RecyclerHomeScreen> createState() => _RecyclerHomeScreenState();
}

class _RecyclerHomeScreenState extends State<RecyclerHomeScreen> {
  final DioClient _dioClient = DioClient();
  List<Map<String, dynamic>> _pickups = <Map<String, dynamic>>[];
  bool _isLoading = false;
  bool _showMapView = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingPickups();
  }

  Future<void> _fetchPendingPickups() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dioClient.dio.get<List<dynamic>>(
        '/pickups/pending',
        queryParameters: <String, dynamic>{
          'lat': AppConstants.ecoconectaDefaultLat,
          'lon': AppConstants.ecoconectaDefaultLon,
        },
      );
      if (mounted && response.data != null) {
        setState(() {
          _pickups = response.data!.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
      // Mantiene datos existentes si no hay conexión en el momento
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _claimPickupAtomically(String pickupId) async {
    try {
      await _dioClient.dio.post<dynamic>('/pickups/$pickupId/claim');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.primaryGreen,
          content: Text(
            'Solicitud bloqueada y asignada exitosamente. Dirección exacta desbloqueada.',
          ),
        ),
      );
      await _fetchPendingPickups();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.errorRed,
          content: Text(
            'La solicitud ya fue tomada por otro reciclador (Bloqueo de Concurrencia 409).',
          ),
        ),
      );
    }
  }

  Future<void> _updateStatus(String pickupId, String newStatus) async {
    try {
      await _dioClient.dio.patch<dynamic>(
        '/pickups/$pickupId/status',
        data: <String, dynamic>{'status': newStatus},
      );
      await _fetchPendingPickups();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bandeja Reciclador: ${widget.userName}'),
        actions: <Widget>[
          IconButton(
            tooltip: _showMapView ? 'Ver Lista' : 'Ver Mapa del municipio',
            onPressed: () => setState(() => _showMapView = !_showMapView),
            icon: Icon(_showMapView ? Icons.list_alt : Icons.map_outlined),
          ),
          IconButton(
            tooltip: 'Actualizar bandeja GPS',
            onPressed: _fetchPendingPickups,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showMapView
              ? _buildMunicipioMapView()
              : _buildListView(),
    );
  }

  Widget _buildMunicipioMapView() {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(
          AppConstants.ecoconectaDefaultLat,
          AppConstants.ecoconectaDefaultLon,
        ),
        initialZoom: 14.5,
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'co.ecoconecta.ecoconecta',
        ),
        MarkerLayer(
          markers: _pickups.map((Map<String, dynamic> item) {
            final double lat =
                (item['latitude'] as num?)?.toDouble() ?? AppConstants.ecoconectaDefaultLat;
            final double lon =
                (item['longitude'] as num?)?.toDouble() ?? AppConstants.ecoconectaDefaultLon;
            return Marker(
              point: LatLng(lat, lon),
              width: 48,
              height: 48,
              child: const Icon(
                Icons.location_on,
                color: AppTheme.primaryGreen,
                size: 40,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    if (_pickups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay solicitudes pendientes en su radio cercano del municipio en este momento.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pickups.length,
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> item = _pickups[index];
        final String id = item['id'].toString();
        final String status = (item['status'] as String?) ?? 'PENDIENTE';
        final String? exactAddress = item['exact_address'] as String?;
        final String? phone = item['generator_phone'] as String?;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      (item['approximate_zone'] as String?) ?? 'Municipio',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(label: Text(status)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Materiales: ${(item['waste_categories'] as List<dynamic>).join(', ')}',
                ),
                Text('Volumen: ${item['estimated_volume']}'),
                if (item['distance_km'] != null)
                  Text('Distancia GPS: ${item['distance_km']} km'),
                const Divider(height: 20),
                if (exactAddress == null)
                  const Row(
                    children: <Widget>[
                      Icon(Icons.lock_outline, size: 18),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Dirección exacta y teléfono protegidos (Ley 1581/2012) hasta aceptar la recolección.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  )
                else ...<Widget>[
                  Text(
                    'Dirección desbloqueada: $exactAddress',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text('Teléfono de contacto: ${phone ?? "N/A"}'),
                ],
                const SizedBox(height: 14),
                if (status == 'PENDIENTE')
                  ElevatedButton.icon(
                    onPressed: () => _claimPickupAtomically(id),
                    icon: const Icon(Icons.pan_tool_alt_outlined),
                    label: const Text('Aceptar y Bloquear Solicitud'),
                  )
                else if (status == 'ACEPTADA')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(id, 'EN_CAMINO'),
                    icon: const Icon(Icons.directions_bike),
                    label: const Text('Iniciar Ruta (En Camino)'),
                  )
                else if (status == 'EN_CAMINO')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(id, 'COMPLETADA'),
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Marcar Recolección Completada'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
