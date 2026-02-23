import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ViewDiagnosticReportScreen extends StatelessWidget {
  final Map<String, dynamic> intervention;

  const ViewDiagnosticReportScreen({
    super.key,
    required this.intervention,
  });

  Map<String, dynamic>? get _report {
    // L'API retourne 'diagnosticReports' (liste) mais on veut le premier élément
    if (intervention['diagnosticReports'] != null) {
      final reports = intervention['diagnosticReports'];
      if (reports is List && reports.isNotEmpty) {
        return reports[0] as Map<String, dynamic>;
      }
    }
    // Fallback pour l'ancien format (diagnostic_report singulier)
    if (intervention['diagnostic_report'] != null) {
      return intervention['diagnostic_report'] as Map<String, dynamic>;
    }
    return null;
  }

  List<dynamic> get _partsList {
    if (_report == null || _report!['parts_needed'] == null) {
      return [];
    }

    final partsNeeded = _report!['parts_needed'];
    if (partsNeeded is String) {
      // Handle empty string
      if (partsNeeded.isEmpty || partsNeeded == '[]') {
        return [];
      }
      try {
        final decoded = json.decode(partsNeeded);
        if (decoded is List) {
          return decoded;
        }
        return [];
      } catch (e) {
        print('❌ Erreur parsing parts_needed: $e');
        return [];
      }
    } else if (partsNeeded is List) {
      return partsNeeded;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final hasReport = report != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport de Diagnostic'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
      ),
      body: !hasReport
          ? _buildNoReport()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec statut
                    _buildStatusBadge(report['status'] ?? 'submitted'),
                    const SizedBox(height: 24),

                    // Informations intervention
                    _buildInfoCard(),
                    const SizedBox(height: 24),

                    // Date de soumission
                    if (report['submitted_at'] != null)
                      _buildInfoRow(
                        '📅 Rapport soumis le',
                        _formatDate(report['submitted_at']),
                      ),
                    const SizedBox(height: 24),

                    // Description du problème
                    _buildSection(
                      'Description du Problème',
                      Icons.error_outline,
                      report['problem_description'] ?? 'Non renseigné',
                    ),
                    const SizedBox(height: 24),

                    // Solution recommandée
                    _buildSection(
                      'Solution Recommandée',
                      Icons.build_circle,
                      report['recommended_solution'] ?? 'Non renseigné',
                    ),
                    const SizedBox(height: 24),

                    // Pièces nécessaires
                    if (_partsList.isNotEmpty) _buildPartsSection(_partsList),
                    const SizedBox(height: 24),

                    // Niveau d'urgence
                    _buildUrgencyBadge(report['urgency_level'] ?? 'medium'),
                    const SizedBox(height: 24),

                    // Durée estimée
                    if (report['estimated_duration'] != null &&
                        report['estimated_duration'].toString().isNotEmpty)
                      _buildSection(
                        'Durée Estimée',
                        Icons.access_time,
                        report['estimated_duration'],
                      ),
                    const SizedBox(height: 24),

                    // Notes
                    if (report['notes'] != null &&
                        report['notes'].toString().isNotEmpty)
                      _buildSection(
                        'Notes / Observations',
                        Icons.comment,
                        report['notes'],
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNoReport() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun rapport disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le rapport de diagnostic n\'a pas encore été soumis',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'submitted':
        bgColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        label = 'Soumis';
        icon = Icons.send;
        break;
      case 'approved':
        bgColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        label = 'Approuvé';
        icon = Icons.check_circle;
        break;
      case 'pending':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        label = 'En attente';
        icon = Icons.pending;
        break;
      default:
        bgColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              intervention['title'] ?? 'Sans titre',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (intervention['description'] != null)
              Text(
                intervention['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF0a543d)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0a543d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildPartsSection(List<dynamic> parts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.build, size: 20, color: Color(0xFF0a543d)),
            SizedBox(width: 8),
            Text(
              'Pièces Nécessaires',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0a543d),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...parts.map((part) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a543d).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFF0a543d),
                  ),
                ),
                title: Text(
                  part['name'] ?? 'Pièce sans nom',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'x${part['quantity'] ?? 0}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildUrgencyBadge(String urgency) {
    Color color;
    String label;
    IconData icon;

    switch (urgency) {
      case 'critical':
        color = Colors.red;
        label = 'URGENT';
        icon = Icons.warning;
        break;
      case 'high':
        color = Colors.orange;
        label = 'ÉLEVÉ';
        icon = Icons.priority_high;
        break;
      case 'medium':
        color = Colors.blue;
        label = 'MOYEN';
        icon = Icons.info;
        break;
      case 'low':
        color = Colors.green;
        label = 'FAIBLE';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        label = urgency.toUpperCase();
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            'Urgence: $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, double cost) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${NumberFormat('#,##0').format(cost)} FCFA',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCostRow(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0a543d).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF0a543d)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Coût Total Estimé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0a543d),
            ),
          ),
          Text(
            '${NumberFormat('#,##0').format(total)} FCFA',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0a543d),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'Date inconnue';
      }

      return DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(date);
    } catch (e) {
      print('❌ Erreur formatage date: $e');
      return 'Date invalide';
    }
  }
}
