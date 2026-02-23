import 'package:flutter/material.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class TechnicianAvailabilityScreen extends StatefulWidget {
  const TechnicianAvailabilityScreen({super.key});

  @override
  State<TechnicianAvailabilityScreen> createState() =>
      _TechnicianAvailabilityScreenState();
}

class _TechnicianAvailabilityScreenState
    extends State<TechnicianAvailabilityScreen> {
  final ApiService _apiService = ApiService();
  String _status = 'offline';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final response = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _status =
              response['data']['profile']['availability_status'] ?? 'offline';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _apiService.updateTechnicianAvailability(newStatus);
      if (mounted) {
        setState(() => _status = newStatus);

        // Afficher le message selon le statut
        switch (newStatus) {
          case 'available':
            SnackBarHelper.showSuccess(
              context,
              'Vous êtes maintenant disponible pour de nouvelles interventions',
              emoji: '✅',
              duration: const Duration(seconds: 3),
            );
            break;
          case 'busy':
            SnackBarHelper.showWarning(
              context,
              'Statut défini sur occupé - Nouvelles demandes en attente',
              duration: const Duration(seconds: 3),
            );
            break;
          case 'offline':
            SnackBarHelper.showWarning(
              context,
              'Vous êtes hors ligne - Aucune nouvelle intervention ne vous sera assignée',
              duration: const Duration(seconds: 3),
            );
            break;
          default:
            SnackBarHelper.showInfo(context, 'Statut mis à jour',
                duration: const Duration(seconds: 3));
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Erreur lors de la mise à jour: ${e.toString()}',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disponibilités')),
      body: Stack(
        children: [
          // Image de fond
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/background_tech_2.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Contenu
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          _status == 'available'
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 64,
                          color: _status == 'available'
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Statut: ${_status == "available" ? "Disponible" : _status == "busy" ? "Occupé" : "Hors ligne"}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildButton('Disponible', 'available', Colors.green,
                    Icons.check_circle),
                const SizedBox(height: 12),
                _buildButton('Occupé', 'busy', Colors.orange, Icons.schedule),
                const SizedBox(height: 12),
                _buildButton(
                    'Hors ligne', 'offline', Colors.grey, Icons.cancel),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, String status, Color color, IconData icon) {
    final isSelected = _status == status;
    return ElevatedButton.icon(
      onPressed: () => _updateStatus(status),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.all(16),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}
