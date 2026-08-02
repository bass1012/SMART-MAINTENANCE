import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/features/customer/presentation/screens/complaints_screen.dart';
import 'package:mct_maintenance_mobile/features/customer/presentation/screens/interventions_list_screen.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:provider/provider.dart';

/// Écran SAV & Garanties Actives Client.
///
/// Transforme la garantie statique en espace SAV dynamique :
/// - Statut en temps réel des garanties par équipement
/// - Alertes sur garanties arrivant à échéance
/// - Lien direct vers réclamations SAV & demande d'intervention
/// - Consultation des engagements contractuels de garantie
class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  bool _showStaticRules = false;

  static const _green = Color(0xFF0a543d);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<BaseApiService>();
      final response = await api.get('/api/customer/warranty/dashboard');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (decoded['success'] == true) {
        if (mounted) {
          setState(() {
            _dashboardData = decoded['data'] as Map<String, dynamic>;
            _isLoading = false;
          });
        }
      } else {
        throw Exception(decoded['message'] ?? 'Erreur lors du chargement');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Garantie & SAV Actif',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildQuickSAVActions(),
                    const SizedBox(height: 20),
                    if (_error == null && _dashboardData != null) ...[
                      _buildEquipmentsWarrantyList(),
                      const SizedBox(height: 20),
                    ],
                    _buildStaticTermsToggle(),
                    if (_showStaticRules) ...[
                      const SizedBox(height: 16),
                      _buildStaticTermsContent(),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final summary = _dashboardData?['summary'] as Map<String, dynamic>?;
    final activeCount = summary?['warranties_active'] ?? 0;
    final totalEquipments = summary?['total_equipments'] ?? 0;
    final openComplaints = summary?['open_complaints'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Suivi SAV & Couverture Équipements',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Cartes KPI
          Row(
            children: [
              Expanded(
                child: _buildKPITile(
                  label: 'Équipements',
                  value: '$totalEquipments',
                  icon: Icons.devices_other,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKPITile(
                  label: 'Garanties actives',
                  value: '$activeCount',
                  icon: Icons.check_circle_outline,
                  highlight: activeCount > 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKPITile(
                  label: 'Réclamations',
                  value: '$openComplaints',
                  icon: Icons.report_problem_outlined,
                  isWarning: openComplaints > 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPITile({
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isWarning
            ? Colors.red.shade400
            : highlight
                ? const Color(0xFF059669)
                : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSAVActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComplaintsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.report_problem_outlined, size: 18),
              label: const Text('Déclarer réclamation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InterventionsListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.build_outlined, size: 18),
              label: const Text('Demander SAV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: const BorderSide(color: _green, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentsWarrantyList() {
    final equipments = (_dashboardData?['equipments'] as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos équipements & Garanties',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 12),
          if (equipments.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.devices_other, color: Colors.grey.shade400, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Aucun équipement enregistré pour le moment.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: equipments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final eq = equipments[index] as Map<String, dynamic>;
                return _buildEquipmentCard(eq);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> eq) {
    final status = eq['warranty_status'] ?? 'unknown';
    final days = eq['days_remaining'] as int?;

    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (status == 'active') {
      badgeColor = const Color(0xFF2F855A);
      badgeText = days != null ? 'Sous garantie ($days j)' : 'Garantie active';
      badgeIcon = Icons.check_circle_outline;
    } else if (status == 'expiring_soon') {
      badgeColor = const Color(0xFFD97706);
      badgeText = 'Expire bientôt ($days j)';
      badgeIcon = Icons.warning_amber_rounded;
    } else if (status == 'expired') {
      badgeColor = const Color(0xFFE53E3E);
      badgeText = 'Garantie expirée';
      badgeIcon = Icons.cancel_outlined;
    } else {
      badgeColor = Colors.grey.shade600;
      badgeText = 'Hors contrat / Non renseignée';
      badgeIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.ac_unit, color: badgeColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eq['name'] ?? 'Équipement',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A202C),
                  ),
                ),
                if (eq['brand'] != null || eq['model'] != null)
                  Text(
                    '${eq['brand'] ?? ''} ${eq['model'] ?? ''}'.trim(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticTermsToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => setState(() => _showStaticRules = !_showStaticRules),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.gavel_outlined, color: Color(0xFF0a543d), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Conditions & Engagements de Garantie',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A202C),
                  ),
                ),
              ),
              Icon(
                _showStaticRules
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticTermsContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildWarrantySection(
            icon: Icons.build_outlined,
            title: 'Installation d\'équipements',
            color: Colors.blue,
            duration: '3 mois',
            content:
                '''Garantie de 3 mois sur les travaux d'installation d'équipements de nos marques partenaires. Portant sur la qualité des travaux et du matériel d'installation (hors problèmes de réseau électrique externe).''',
          ),
          const SizedBox(height: 12),
          _buildWarrantySection(
            icon: Icons.cleaning_services_outlined,
            title: 'Travaux d\'Entretien',
            color: Colors.orange,
            duration: '2 semaines',
            content:
                '''Garantie de 2 semaines après la date d'entretien pour couvrir toute mauvaise manipulation éventuelle durant la prestation.''',
          ),
          const SizedBox(height: 12),
          _buildWarrantySection(
            icon: Icons.extension_outlined,
            title: 'Pièces de Rechange',
            color: Colors.green,
            duration: 'Variables selon fabricant',
            content:
                '''Garanties régies par les conditions constructeurs. MCT Maintenance assure le remplacement sous réserve de l'expertise technique.''',
          ),
        ],
      ),
    );
  }

  Widget _buildWarrantySection({
    required IconData icon,
    required String title,
    required Color color,
    required String duration,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  duration,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
