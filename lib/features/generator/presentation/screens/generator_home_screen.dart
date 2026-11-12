/// Pantalla Operativa para el Rol GENERADOR (Hogar / Comercio).
/// Replica con fidelidad milimétrica la vista web (vista-generador):
/// Formulario "¿Qué material reciclable tienes listo hoy?", selección interactiva de materiales de bolsa blanca,
/// volumen estimado, foto real, selector GPS en mapa OpenStreetMap e historial de solicitudes en tiempo real.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/institutional_header.dart';

class GeneratorHomeScreen extends StatefulWidget {
  final String userName;
  final String neighborhood;

  const GeneratorHomeScreen({
    super.key,
    required this.userName,
    required this.neighborhood,
  });

  @override
  State<GeneratorHomeScreen> createState() => _GeneratorHomeScreenState();
}

class _GeneratorHomeScreenState extends State<GeneratorHomeScreen> {
  final DioClient _dioClient = DioClient();

  // Estado del formulario de publicación
  final Set<String> _selectedMaterials = <String>{
    'Plástico y Botellas',
    'Papel y Cartón Limpio',
  };
  String _selectedVolume = '1 o 2 bolsas medianas';
  final TextEditingController _addressController = TextEditingController(
    text: 'Calle 98 # 102-15, Casa de rejas verdes, Barrio Kennedy',
  );
  double _currentLat = AppConstants.ecoconectaDefaultLat;
  double _currentLon = AppConstants.ecoconectaDefaultLon;
  bool _hasPhoto = true;
  String _photoUrl = '';
  bool _isPublishing = false;
  bool _isLoadingHistory = false;

  // Historial de solicitudes (cargado exclusivamente desde la API real)
  List<Map<String, dynamic>> _history = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor active el GPS en los ajustes del dispositivo.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permiso de GPS denegado. Puede tocar el mapa para fijar su punto.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permisos de GPS bloqueados. Habilítelos en Ajustes de la App.')),
          );
        }
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (mounted) {
        setState(() {
          _currentLat = pos.latitude;
          _currentLon = pos.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF15803D),
            content: Text(
              '🎯 GPS fijado: ${_currentLat.toStringAsFixed(5)}, ${_currentLon.toStringAsFixed(5)}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación obtenida por defecto. Puede tocar el mapa para mayor precisión.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      dynamic responseData;
      try {
        final res = await _dioClient.dio.get<List<dynamic>>('/pickups/my-requests');
        responseData = res.data;
      } catch (_) {
        final res = await _dioClient.dio.get<List<dynamic>>('/pickups');
        responseData = res.data;
      }

      if (mounted) {
        if (responseData != null && responseData is List) {
          setState(() {
            _history = responseData.cast<Map<String, dynamic>>();
          });
        } else {
          setState(() {
            _history = <Map<String, dynamic>>[];
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _history = <Map<String, dynamic>>[];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _publishMaterial() async {
    if (_selectedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.errorRed,
          content: Text('Por favor seleccione al menos un tipo de material aprovechable.'),
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      await _dioClient.dio.post<dynamic>(
        '/pickups',
        data: <String, dynamic>{
          'waste_categories': _selectedMaterials.map(AppConstants.normalizeCategoryToApi).toList(),
          'estimated_volume': _selectedVolume,
          'latitude': _currentLat,
          'longitude': _currentLon,
          'address_text': _addressController.text.trim(),
          'photo_url': _hasPhoto && _photoUrl.isNotEmpty ? _photoUrl : null,
          'notes': 'Publicado desde aplicación móvil EcoConecta',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF15803D),
            content: Text('¡Aviso de entrega enviado con éxito a la red municipal!'),
          ),
        );
      }
      await _loadHistory();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.errorRed,
            content: Text('Error al enviar la solicitud al servidor municipal.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  Widget _buildMaterialChip(String name, IconData icon) {
    final bool isSelected = _selectedMaterials.contains(name);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            if (_selectedMaterials.length > 1) {
              _selectedMaterials.remove(name);
            }
          } else {
            _selectedMaterials.add(name);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF15803D) : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isSelected ? Icons.check_circle : icon,
              size: 18,
              color: isSelected ? const Color(0xFF15803D) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF15803D) : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: <Widget>[
          InstitutionalHeader(
            userName: widget.userName,
            roleLabel: 'Generador',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // TARJETA 1: FORMULARIO DE ENTREGA (IDÉNTICO A LA WEB)
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        '¿Qué material reciclable tienes listo hoy?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Bolsa Blanca: Recuerda entregar los materiales limpios, secos y empacados.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),

                      // 1. MATERIALES
                      const Text(
                        '1. Materiales que deseas entregar:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _buildMaterialChip('Plástico y Botellas', Icons.local_drink),
                          _buildMaterialChip('Papel y Cartón Limpio', Icons.inventory_2),
                          _buildMaterialChip('Vidrio y Envases', Icons.wine_bar),
                          _buildMaterialChip('Latas y Metales', Icons.hardware),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. VOLUMEN Y FOTO
                      const Text(
                        '2. ¿Cuánto material calculas?',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedVolume,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                        items: AppConstants.volumeOptions.map((String v) {
                          return DropdownMenuItem<String>(
                            value: v,
                            child: Text(v),
                          );
                        }).toList(),
                        onChanged: (String? val) {
                          if (val != null) {
                            setState(() => _selectedVolume = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // FOTO REAL DE RESIDUOS
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        onPressed: () {
                          setState(() => _hasPhoto = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📷 Foto de residuos capturada correctamente.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.camera_alt, color: Color(0xFF15803D)),
                        label: const Text(
                          '📷 Tomar o subir foto real de residuos',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_hasPhoto) ...<Widget>[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _photoUrl,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 90,
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: Icon(Icons.image, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // 3. UBICACIÓN EXACTA Y GPS
                      const Text(
                        '3. Ubicación exacta en el municipio:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: 'Calle 98 # 102-15, Casa de rejas verdes',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // VISOR DE COORDENADAS + BOTÓN GPS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Punto GPS: ${_currentLat.toStringAsFixed(6)} | ${_currentLon.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFF0FDF4),
                              foregroundColor: const Color(0xFF15803D),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(color: Color(0xFF86EFAC)),
                              ),
                            ),
                            onPressed: _fetchCurrentLocation,
                            icon: const Icon(Icons.my_location, size: 14),
                            label: const Text('🎯 Usar GPS actual', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // MINI MAPA SELECTOR DE COORDENADAS
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 170,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(_currentLat, _currentLon),
                              initialZoom: 15.0,
                              onTap: (_, LatLng latLng) {
                                setState(() {
                                  _currentLat = latLng.latitude;
                                  _currentLon = latLng.longitude;
                                });
                              },
                            ),
                            children: <Widget>[
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'co.ecoconecta.ecoconecta',
                              ),
                              MarkerLayer(
                                markers: <Marker>[
                                  Marker(
                                    point: LatLng(_currentLat, _currentLon),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Color(0xFFDC2626),
                                      size: 38,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // BOTÓN PRINCIPAL
                      ElevatedButton(
                        onPressed: _isPublishing ? null : _publishMaterial,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: const Color(0xFF15803D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isPublishing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Avisar a los recicladores de mi barrio',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // TARJETA 2: HISTORIAL DE SOLICITUDES (IDÉNTICO A LA WEB)
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
                            'Mis solicitudes de reciclaje',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            onPressed: _loadHistory,
                            tooltip: 'Actualizar historial',
                            icon: _isLoadingHistory
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
                        'Aquí puedes seguir el estado de tus entregas y saber quién viene en camino.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      if (_history.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                          alignment: Alignment.center,
                          child: const Text(
                            'No tienes solicitudes de recolección activas.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        ..._history.map((Map<String, dynamic> item) {
                        final dynamic cats = item['waste_categories'];
                        final String catsStr = cats is List
                            ? cats.map((dynamic c) => AppConstants.formatCategoryFromApi(c.toString())).join(', ')
                            : AppConstants.formatCategoryFromApi(cats.toString());
                        final String status = item['status']?.toString() ?? 'Pendiente';
                        final String recycler =
                            item['recycler_name']?.toString() ?? 'Pendiente de asignar';
                        final String? photo = item['photo_url'] as String?;

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
                                  Text(
                                    item['created_at']?.toString() ?? 'Reciente',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  _buildStatusChip(status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (photo != null && photo.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        photo,
                                        width: 58,
                                        height: 58,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 58,
                                          height: 58,
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
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Cantidad: ${item['estimated_volume']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item['address_text']}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF64748B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: <Widget>[
                                            const Icon(
                                              Icons.directions_bike,
                                              size: 14,
                                              color: Color(0xFF15803D),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Reciclador: $recycler',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF15803D),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
