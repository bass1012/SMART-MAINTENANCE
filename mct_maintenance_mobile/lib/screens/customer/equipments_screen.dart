import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/environment.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/common/support_fab_wrapper.dart';

class EquipmentsScreen extends StatefulWidget {
  const EquipmentsScreen({super.key});

  @override
  State<EquipmentsScreen> createState() => _EquipmentsScreenState();
}

class _EquipmentsScreenState extends State<EquipmentsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _equipments = [];

  @override
  void initState() {
    super.initState();
    _loadEquipments();
  }

  Future<void> _loadEquipments() async {
    try {
      setState(() => _isLoading = true);

      final response = await _apiService.get('/equipments/my-equipments');

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _equipments = List<Map<String, dynamic>>.from(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Erreur lors du chargement des équipements',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupportFabWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Mes Équipements',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0a543d),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showAddEquipmentDialog();
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/Maintenancier_SMART_Maintenance_two.png'),
              fit: BoxFit.cover,
              opacity: 0.4,
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _equipments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadEquipments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _equipments.length,
                        itemBuilder: (context, index) {
                          final equipment = _equipments[index];
                          return _buildEquipmentCard(equipment);
                        },
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0a543d).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.devices_other,
                size: 64,
                color: Color(0xFF0a543d),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun équipement',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez vos appareils pour mieux\nles gérer et les suivre',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddEquipmentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un équipement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0a543d),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> equipment) {
    final type = equipment['type'] ?? 'Non spécifié';
    final brand = equipment['brand'] ?? '';
    final model = equipment['model'] ?? '';
    final serialNumber = equipment['serial_number'] ?? '';
    final location = equipment['location'] ?? '';
    final installationDate = equipment['installation_date'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEquipmentDetails(equipment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0a543d).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getEquipmentIcon(type),
                      color: const Color(0xFF0a543d),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (brand.isNotEmpty || model.isNotEmpty)
                          Text(
                            '$brand ${model}'.trim(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showEquipmentOptions(equipment),
                  ),
                ],
              ),
              if (serialNumber.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.qr_code_2,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'N° de série: ',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      serialNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
              if (location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
              if (installationDate.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Installé le: $installationDate',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getEquipmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'climatiseur':
      case 'climatisation':
        return Icons.ac_unit;
      case 'réfrigérateur':
      case 'frigo':
        return Icons.kitchen;
      case 'congélateur':
        return Icons.severe_cold;
      case 'machine à laver':
        return Icons.local_laundry_service;
      case 'four':
        return Icons.microwave;
      default:
        return Icons.devices_other;
    }
  }

  void _showEquipmentDetails(Map<String, dynamic> equipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                equipment['type'] ?? 'Équipement',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Marque', equipment['brand']),
              _buildDetailRow('Modèle', equipment['model']),
              _buildDetailRow('N° de série', equipment['serial_number']),
              _buildDetailRow('Emplacement', equipment['location']),
              _buildDetailRow(
                  'Date d\'installation', equipment['installation_date']),
              if (equipment['notes'] != null && equipment['notes'].isNotEmpty)
                _buildDetailRow('Notes', equipment['notes']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty)
      return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showEquipmentOptions(Map<String, dynamic> equipment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF0a543d)),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                _showEditEquipmentDialog(equipment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteEquipment(equipment);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddEquipmentDialog() {
    final formKey = GlobalKey<FormState>();
    final typeController = TextEditingController();
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final serialNumberController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Ajouter un équipement',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'Type d\'équipement *',
                    hintText: 'Ex: Climatiseur, Réfrigérateur',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: brandController,
                  decoration: const InputDecoration(
                    labelText: 'Marque',
                    hintText: 'Ex: Carrier, LK',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: modelController,
                  decoration: const InputDecoration(
                    labelText: 'Modèle',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: serialNumberController,
                  decoration: const InputDecoration(
                    labelText: 'N° de série',
                    hintText: 'Code unique de l\'appareil',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Emplacement',
                    hintText: 'Ex: Bureau, Salon',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                await _addEquipment({
                  'type': typeController.text,
                  'brand': brandController.text,
                  'model': modelController.text,
                  'serial_number': serialNumberController.text,
                  'location': locationController.text,
                  'notes': notesController.text,
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0a543d),
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditEquipmentDialog(Map<String, dynamic> equipment) {
    final formKey = GlobalKey<FormState>();
    final typeController = TextEditingController(text: equipment['type']);
    final brandController = TextEditingController(text: equipment['brand']);
    final modelController = TextEditingController(text: equipment['model']);
    final serialNumberController =
        TextEditingController(text: equipment['serial_number']);
    final locationController =
        TextEditingController(text: equipment['location']);
    final notesController = TextEditingController(text: equipment['notes']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Modifier l\'équipement',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Type *'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: brandController,
                  decoration: const InputDecoration(labelText: 'Marque'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: modelController,
                  decoration: const InputDecoration(labelText: 'Modèle'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: serialNumberController,
                  decoration: const InputDecoration(labelText: 'N° de série'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Emplacement'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);
                await _updateEquipment(equipment['id'], {
                  'type': typeController.text,
                  'brand': brandController.text,
                  'model': modelController.text,
                  'serial_number': serialNumberController.text,
                  'location': locationController.text,
                  'notes': notesController.text,
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0a543d),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _addEquipment(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/equipments', data);

      if (response['success'] == true) {
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Équipement ajouté avec succès');
          await _loadEquipments();
        }
      } else {
        if (mounted) {
          SnackBarHelper.showError(
              context, response['message'] ?? 'Erreur lors de l\'ajout');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur lors de l\'ajout');
      }
    }
  }

  Future<void> _updateEquipment(int id, Map<String, dynamic> data) async {
    try {
      // Utiliser la méthode get avec le path complet pour PUT
      final url = '${AppConfig.baseUrl}/api/equipments/$id';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      final jsonResponse = json.decode(response.body);

      if (jsonResponse['success'] == true) {
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Équipement modifié avec succès');
          _loadEquipments();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur lors de la modification');
      }
    }
  }

  void _confirmDeleteEquipment(Map<String, dynamic> equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'équipement'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${equipment['type']}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEquipment(equipment['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEquipment(int id) async {
    try {
      final url = '${AppConfig.baseUrl}/api/equipments/$id';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final jsonResponse = json.decode(response.body);

      if (jsonResponse['success'] == true) {
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Équipement supprimé');
          _loadEquipments();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur lors de la suppression');
      }
    }
  }
}
