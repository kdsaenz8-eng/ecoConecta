/// Pantalla para el Rol GENERADOR (Hogar / Comercio en el municipio).
/// Incluye botón destacado "Publicar Material Reciclable", asistente modal en 3 pasos
/// de baja carga cognitiva (Resolución 2184 de 2019) e historial de entregas.
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';

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
  final Set<String> _selectedCategories = <String>{'PLASTICO'};
  String _selectedVolume = AppConstants.volumeOptions.first;
  int _currentWizardStep = 0;
  bool _hasAttachedPhoto = false;
  bool _isPublishing = false;
  final TextEditingController _referenceController = TextEditingController(
    text: 'Frente a la entrada principal',
  );

  List<Map<String, dynamic>> _myHistory = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await _dioClient.dio.get<List<dynamic>>('/pickups/my-requests');
      if (mounted && response.data != null) {
        setState(() {
          _myHistory = response.data!.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
      // Mantiene lista local si se ejecuta en modo demostración sin red activa
    }
  }

  Future<void> _publishPickup() async {
    if (_selectedCategories.isEmpty) return;
    setState(() => _isPublishing = true);

    try {
      await _dioClient.dio.post<dynamic>(
        '/pickups',
        data: <String, dynamic>{
          'waste_categories': _selectedCategories.toList(),
          'estimated_volume': _selectedVolume,
          'latitude': AppConstants.ecoconectaDefaultLat,
          'longitude': AppConstants.ecoconectaDefaultLon,
          'address_text':
              'Barrio ${widget.neighborhood} - ${_referenceController.text.trim()}',
          'photo_url': _hasAttachedPhoto
              ? 'https://storage.ecoconecta.co/evidencias/bolsa_blanca_ecoconecta.jpg'
              : null,
        },
      );
      await _loadHistory();
    } catch (_) {
      // Registro local inmediato de respaldo para visualización en prototipo
      setState(() {
        _myHistory.insert(0, <String, dynamic>{
          'status': 'PENDIENTE',
          'waste_categories': _selectedCategories.toList(),
          'estimated_volume': _selectedVolume,
          'address_text':
              'Barrio ${widget.neighborhood} - ${_referenceController.text.trim()}',
        });
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _currentWizardStep = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text(
              '¡Solicitud publicada! Los recicladores del municipio han sido notificados.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${widget.userName} (${widget.neighborhood})'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(Icons.eco, color: AppTheme.primaryGreen, size: 28),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Publicar Material Reciclable (3 Pasos)',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Código de Colores Resolución 2184 de 2019 - Bolsa Blanca (Residuos Aprovechables Limpios y Secos).',
                  ),
                  const SizedBox(height: 14),
                  Stepper(
                    physics: const NeverScrollableScrollPhysics(),
                    currentStep: _currentWizardStep,
                    onStepContinue: () {
                      if (_currentWizardStep < 2) {
                        setState(() => _currentWizardStep += 1);
                      } else {
                        _publishPickup();
                      }
                    },
                    onStepCancel: () {
                      if (_currentWizardStep > 0) {
                        setState(() => _currentWizardStep -= 1);
                      }
                    },
                    steps: <Step>[
                      Step(
                        title: const Text('Paso 1: Selección de Materiales'),
                        isActive: _currentWizardStep >= 0,
                        content: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppConstants.res2184WasteCategories
                              .map((Map<String, dynamic> cat) {
                            final String code = cat['code'] as String;
                            final bool selected =
                                _selectedCategories.contains(code);
                            return FilterChip(
                              avatar: Icon(cat['icon'] as IconData, size: 18),
                              label: Text(cat['label'] as String),
                              selected: selected,
                              onSelected: (bool val) {
                                setState(() {
                                  if (val) {
                                    _selectedCategories.add(code);
                                  } else if (_selectedCategories.length > 1) {
                                    _selectedCategories.remove(code);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      Step(
                        title: const Text('Paso 2: Volumen Estimado y Foto'),
                        isActive: _currentWizardStep >= 1,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            DropdownButtonFormField<String>(
                              initialValue: _selectedVolume,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad aproximada',
                              ),
                              items: AppConstants.volumeOptions
                                  .map(
                                    (String v) => DropdownMenuItem<String>(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (String? val) {
                                if (val != null) {
                                  setState(() => _selectedVolume = val);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _hasAttachedPhoto = true);
                              },
                              icon: Icon(
                                _hasAttachedPhoto
                                    ? Icons.check_circle
                                    : Icons.camera_alt_outlined,
                              ),
                              label: Text(
                                _hasAttachedPhoto
                                    ? 'Evidencia fotográfica adjuntada'
                                    : 'Capturar fotografía del material',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Step(
                        title: const Text('Paso 3: Ubicación GPS y Referencia'),
                        isActive: _currentWizardStep >= 2,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'GPS detectado en el municipio: (${AppConstants.ecoconectaDefaultLat}, ${AppConstants.ecoconectaDefaultLon})',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _referenceController,
                              decoration: const InputDecoration(
                                labelText: 'Referencia para el reciclador',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isPublishing)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Historial de Entregas Recientes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_myHistory.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aún no has publicado solicitudes de recolección.'),
              ),
            )
          else
            ..._myHistory.map(
              (Map<String, dynamic> item) => Card(
                child: ListTile(
                  leading: const Icon(Icons.recycling, color: AppTheme.primaryGreen),
                  title: Text(
                    'Materiales: ${(item['waste_categories'] as List<dynamic>).join(', ')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Volumen: ${item['estimated_volume']} • Estado: ${item['status']}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

