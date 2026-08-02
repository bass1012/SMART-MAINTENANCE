import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/widgets/common/loading_indicator.dart';
import 'package:provider/provider.dart';

/// Cockpit des exceptions opérationnelles pour le Manager.
///
/// Consomme [GET /api/admin/cockpit/operational-alerts] et affiche les alertes
/// regroupées par catégorie avec leur sévérité. Interface conçue pour une
/// lecture rapide sur terrain.
class ManagerCockpitScreen extends StatefulWidget {
  const ManagerCockpitScreen({super.key});

  @override
  State<ManagerCockpitScreen> createState() => _ManagerCockpitScreenState();
}

class _ManagerCockpitScreenState extends State<ManagerCockpitScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _cockpit;

  static const _blue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = context.read<BaseApiService>();
      final response = await api.get('/api/admin/cockpit/operational-alerts');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == true) {
        if (mounted) {
          setState(() {
            _cockpit = decoded['data'] as Map<String, dynamic>;
            _isLoading = false;
          });
        }
      } else {
        throw Exception(decoded['message'] ?? 'Erreur API');
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
        elevation: 0,
        backgroundColor: _blue,
        title: Text(
          'Cockpit Opérationnel',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les alertes',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final summary = _cockpit!['summary'] as Map<String, dynamic>;
    final alerts = _cockpit!['alerts'] as Map<String, dynamic>;
    final totalAlerts = summary['total_alerts'] as int? ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Résumé global
          _buildSummaryCard(totalAlerts),
          const SizedBox(height: 20),

          // Alertes critiques
          Text(
            '🔴 Critiques',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(height: 8),
          _buildAlertCard(
            alerts['failed_payments'] as Map<String, dynamic>,
            Icons.payment_outlined,
            const Color(0xFFE53E3E),
          ),
          _buildAlertCard(
            alerts['unassigned_interventions'] as Map<String, dynamic>,
            Icons.person_off_outlined,
            const Color(0xFFE53E3E),
          ),

          const SizedBox(height: 16),

          // Alertes de vigilance
          Text(
            '🟡 Vigilance',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 8),
          _buildAlertCard(
            alerts['late_interventions'] as Map<String, dynamic>,
            Icons.schedule_outlined,
            const Color(0xFFD97706),
          ),
          _buildAlertCard(
            alerts['expired_quotes'] as Map<String, dynamic>,
            Icons.description_outlined,
            const Color(0xFFD97706),
          ),
          _buildAlertCard(
            alerts['pending_refunds'] as Map<String, dynamic>,
            Icons.undo_outlined,
            const Color(0xFFD97706),
          ),
          _buildAlertCard(
            alerts['pending_diagnostic_payments'] as Map<String, dynamic>,
            Icons.build_circle_outlined,
            const Color(0xFFD97706),
          ),

          const SizedBox(height: 16),

          // Informations
          Text(
            '🔵 Informations',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3182CE),
            ),
          ),
          const SizedBox(height: 8),
          _buildAlertCard(
            alerts['near_expiry_contracts'] as Map<String, dynamic>,
            Icons.assignment_late_outlined,
            const Color(0xFF3182CE),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int total) {
    final color = total == 0 ? const Color(0xFF0a543d) : const Color(0xFFE53E3E);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$total',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0 ? 'Aucune alerte active' : 'Alertes actives',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  total == 0
                      ? 'Toutes les opérations sont normales'
                      : '$total exception${total > 1 ? 's' : ''} à traiter',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    Map<String, dynamic> alert,
    IconData icon,
    Color color,
  ) {
    final count = alert['count'] as int? ?? 0;
    final label = alert['label'] as String? ?? '';
    final severity = alert['severity'] as String? ?? 'ok';
    final isOk = severity == 'ok';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isOk ? Colors.white : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOk
              ? Colors.grey.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOk
                  ? Colors.grey.withValues(alpha: 0.08)
                  : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isOk ? Colors.grey.shade500 : color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isOk ? Colors.grey.shade500 : const Color(0xFF1A202C),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOk
                  ? Colors.grey.withValues(alpha: 0.1)
                  : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOk ? '✓' : '$count',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isOk ? Colors.grey.shade500 : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
