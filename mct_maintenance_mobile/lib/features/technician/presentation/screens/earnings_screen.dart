import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';

/// Écran des revenus technicien.
///
/// ⚠️  En attente de connexion à l'endpoint API `/api/technician/earnings`.
/// Les données fictives ont été supprimées. L'écran affiche un état vide
/// informatif jusqu'à l'implémentation complète du service de revenus.
class TechnicianEarningsScreen extends StatefulWidget {
  const TechnicianEarningsScreen({super.key});

  @override
  State<TechnicianEarningsScreen> createState() =>
      _TechnicianEarningsScreenState();
}

class _TechnicianEarningsScreenState extends State<TechnicianEarningsScreen> {
  final bool _isLoading = false;

  static const _green = Color(0xFF0a543d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _green,
        title: Text(
          'Mes Revenus',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFF4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _green.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: _green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Revenus à venir',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Le suivi de vos revenus sera disponible\ndès la connexion à l\'API de facturation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Endpoint prévu : GET /api/technician/earnings',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
