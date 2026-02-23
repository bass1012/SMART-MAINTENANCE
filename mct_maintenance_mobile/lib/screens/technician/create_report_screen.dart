import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mct_maintenance_mobile/screens/technician/report_summary_screen.dart';
import '../../utils/snackbar_helper.dart';

class CreateReportScreen extends StatefulWidget {
  final Map<String, dynamic> intervention;

  const CreateReportScreen({
    super.key,
    required this.intervention,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  // Controllers
  final TextEditingController _workDescriptionController =
      TextEditingController();
  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  // Mesures techniques
  final TextEditingController _pressionController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _intensiteController = TextEditingController();
  final TextEditingController _tensionController = TextEditingController();

  // Matériaux utilisés
  List<Map<String, dynamic>> _materials = [];

  // Photos
  List<XFile> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadExistingReportData();
  }

  void _loadExistingReportData() {
    // Charger les données existantes du rapport si présentes
    if (widget.intervention['report_data'] != null) {
      try {
        final reportData = widget.intervention['report_data'];
        print('🔍 Type de report_data: ${reportData.runtimeType}');
        print('🔍 Contenu de report_data: $reportData');

        Map<String, dynamic> data = {};

        if (reportData is String && reportData.isNotEmpty) {
          // Parser la chaîne JSON
          data = json.decode(reportData);
          print('✅ Report data parsé depuis String: $data');
        } else if (reportData is Map) {
          data = Map<String, dynamic>.from(reportData);
          print('✅ Report data depuis Map: $data');
        }

        if (data.isNotEmpty) {
          // Pré-remplir les champs
          _workDescriptionController.text = data['work_description'] ?? '';
          _observationsController.text = data['observations'] ?? '';
          _durationController.text = data['duration']?.toString() ?? '';

          // Charger les mesures techniques
          _pressionController.text = data['pression']?.toString() ?? '';
          _temperatureController.text = data['temperature']?.toString() ?? '';
          _intensiteController.text = data['intensite']?.toString() ?? '';
          _tensionController.text = data['tension']?.toString() ?? '';

          print('✅ Champs pré-remplis:');
          print('  - work_description: ${_workDescriptionController.text}');
          print('  - observations: ${_observationsController.text}');
          print('  - duration: ${_durationController.text}');
          print('  - pression: ${_pressionController.text}');
          print('  - temperature: ${_temperatureController.text}');
          print('  - intensite: ${_intensiteController.text}');
          print('  - tension: ${_tensionController.text}');

          // Charger les matériaux
          if (data['materials_used'] != null) {
            if (data['materials_used'] is List) {
              _materials = List<Map<String, dynamic>>.from(
                (data['materials_used'] as List).map((item) {
                  if (item is Map) {
                    return Map<String, dynamic>.from(item);
                  }
                  return {
                    'name': item.toString(),
                    'quantity': 1,
                    'unit': 'unité'
                  };
                }),
              );
              print('✅ ${_materials.length} matériaux chargés');
            }
          }

          // Forcer le rebuild pour afficher les données
          setState(() {});
        } else {
          print('⚠️ Report data vide après parsing');
        }
      } catch (e, stackTrace) {
        print('❌ Erreur lors du chargement des données du rapport: $e');
        print('❌ Stack trace: $stackTrace');
      }
    } else {
      print('⚠️ Aucune report_data trouvée dans l\'intervention');
      print('🔍 Clés disponibles: ${widget.intervention.keys.toList()}');
    }
  }

  @override
  void dispose() {
    _workDescriptionController.dispose();
    _observationsController.dispose();
    _durationController.dispose();
    _pressionController.dispose();
    _temperatureController.dispose();
    _intensiteController.dispose();
    _tensionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _photos.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de la sélection des photos: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _photos.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de la prise de photo: $e');
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _addMaterial() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final quantityController = TextEditingController();
        final unitController = TextEditingController(text: 'unité');

        return AlertDialog(
          title: const Text('Ajouter un matériau'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du matériau',
                  hintText: 'Ex: Tuyau PVC',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unité',
                  hintText: 'Ex: mètre, pièce, litre',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    quantityController.text.isNotEmpty) {
                  setState(() {
                    _materials.add({
                      'name': nameController.text,
                      'quantity': quantityController.text,
                      'unit': unitController.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0a543d),
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _removeMaterial(int index) {
    setState(() {
      _materials.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_workDescriptionController.text.trim().isEmpty) {
      SnackBarHelper.showWarning(
          context, 'Veuillez décrire le travail effectué');
      return;
    }

    // Préparer les données sans soumettre
    // Convertir les photos en base64
    // Récupérer les chemins des photos pour l'upload multipart
    List<String> photoPaths = _photos.map((photo) => photo.path).toList();

    final reportData = {
      'intervention_id': widget.intervention['id'],
      'work_description': _workDescriptionController.text.trim(),
      'materials_used': _materials,
      'duration': _durationController.text.isNotEmpty
          ? int.tryParse(_durationController.text) ?? 0
          : 0,
      'observations': _observationsController.text.trim(),
      'photos': photoPaths,
      // Mesures techniques
      'pression': _pressionController.text.trim(),
      'temperature': _temperatureController.text.trim(),
      'intensite': _intensiteController.text.trim(),
      'tension': _tensionController.text.trim(),
    };

    // Naviguer vers l'écran de récapitulatif
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportSummaryScreen(
            intervention: widget.intervention,
            reportData: reportData,
          ),
        ),
      );

      // Si le rapport a été soumis avec succès depuis le récap
      if (result == true && mounted) {
        // Retourner à l'écran de détail de l'intervention
        Navigator.pop(context, true);
      }
      // Si result == false, l'utilisateur veut modifier, on reste sur cet écran
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer le Rapport'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations intervention
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.intervention['title'] ?? 'Intervention',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Client: ${widget.intervention['customer'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                'Adresse: ${widget.intervention['address'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Travail effectué
                      const Text(
                        'Travail effectué *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _workDescriptionController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Décrivez en détail le travail effectué...',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ce champ est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Durée
                      const Text(
                        'Durée (en minutes)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Ex: 120',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          suffixText: 'min',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mesures techniques
                      const Text(
                        'Mesures Techniques',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pressionController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Pression',
                                hintText: 'Ex: 12.5',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                suffixText: 'bar',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _temperatureController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Température',
                                hintText: 'Ex: 22',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                suffixText: '°C',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _intensiteController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Intensité',
                                hintText: 'Ex: 5.2',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                suffixText: 'A',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _tensionController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Tension',
                                hintText: 'Ex: 220',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                suffixText: 'V',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Matériaux utilisés
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Matériaux utilisés',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addMaterial,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Ajouter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0a543d),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_materials.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Aucun matériau ajouté',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...List.generate(_materials.length, (index) {
                          final material = _materials[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.inventory_2,
                                color: Color(0xFF0a543d),
                              ),
                              title: Text(material['name']),
                              subtitle: Text(
                                '${material['quantity']} ${material['unit']}',
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeMaterial(index),
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 24),

                      // Photos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Photos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _takePicture,
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Photo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _pickImages,
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: const Text('Galerie'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0a543d),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_photos.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Aucune photo ajoutée',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _photos.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_photos[index].path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removePhoto(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 24),

                      // Observations
                      const Text(
                        'Observations / Recommandations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _observationsController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Observations, recommandations pour le client...',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bouton soumettre
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submitReport,
                          icon: const Icon(Icons.send),
                          label: const Text(
                            'Soumettre le rapport',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0a543d),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
