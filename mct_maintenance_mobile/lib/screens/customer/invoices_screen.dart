import '../../utils/snackbar_helper.dart';
import '../../widgets/common/support_fab_wrapper.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'payment_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Invoice> _invoices = [];
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);

    try {
      // Charger les vraies factures depuis l'API
      final response = await _apiService.getInvoices();

      if (mounted) {
        setState(() {
          _invoices = _parseInvoices(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // En cas d'erreur, utiliser les données de démo
          _invoices = _getDemoInvoices();
          _isLoading = false;
        });
        SnackBarHelper.showError(context, 'Erreur de chargement: $e');
      }
    }
  }

  List<Invoice> _parseInvoices(Map<String, dynamic> response) {
    try {
      final List<dynamic> ordersData = response['data'] ?? [];

      print('🔍 DEBUG Invoices - Nombre de commandes: ${ordersData.length}');

      return ordersData.map((orderJson) {
        // DEBUG: Afficher tous les champs de la première commande
        if (ordersData.indexOf(orderJson) == 0) {
          print('📦 DEBUG - Premier objet commande:');
          print('   Keys disponibles: ${orderJson.keys.toList()}');
          print('   payment_status: ${orderJson['payment_status']}');
          print('   paymentStatus: ${orderJson['paymentStatus']}');
          print('   status: ${orderJson['status']}');
          print('   statut: ${orderJson['statut']}');
        }

        // Convertir les commandes en factures
        final orderId = orderJson['id'].toString();
        final createdAt = DateTime.parse(orderJson['created_at'] ??
            orderJson['createdAt'] ??
            DateTime.now().toIso8601String());

        // Parser le montant avec plusieurs tentatives
        double amount = 0.0;
        if (orderJson['totalAmount'] != null) {
          amount = double.tryParse(orderJson['totalAmount'].toString()) ?? 0.0;
        } else if (orderJson['total_amount'] != null) {
          amount = double.tryParse(orderJson['total_amount'].toString()) ?? 0.0;
        } else if (orderJson['montant_total'] != null) {
          amount =
              double.tryParse(orderJson['montant_total'].toString()) ?? 0.0;
        } else if (orderJson['total'] != null) {
          amount = double.tryParse(orderJson['total'].toString()) ?? 0.0;
        } else if (orderJson['amount'] != null) {
          amount = double.tryParse(orderJson['amount'].toString()) ?? 0.0;
        }

        // Récupérer le statut de paiement
        // L'API renvoie paymentStatus en camelCase (pas payment_status)
        String paymentStatus = orderJson['paymentStatus']?.toString() ??
            orderJson['payment_status']?.toString() ??
            orderJson['statut_paiement']?.toString() ??
            'pending';

        print('💳 Commande #$orderId - Payment Status brut: $paymentStatus');

        final mappedStatus = _mapInvoiceStatus(paymentStatus, createdAt);
        print('   ➡️ Status mappé: $mappedStatus');

        return Invoice(
          id: orderId,
          number: 'FACT-${DateTime.now().year}-${orderId.padLeft(3, '0')}',
          date: createdAt,
          dueDate:
              createdAt.add(const Duration(days: 30)), // Échéance à 30 jours
          amount: amount,
          status: mappedStatus,
          description: orderJson['notes'] ??
              orderJson['adresse_livraison'] ??
              orderJson['shipping_address'] ??
              'Commande #$orderId',
        );
      }).toList();
    } catch (e) {
      print('❌ Erreur lors du parsing des factures: $e');
      return [];
    }
  }

  String _mapInvoiceStatus(String paymentStatus, DateTime invoiceDate) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
      case 'paye':
        return 'paid';
      case 'failed':
      case 'refunded':
        return 'cancelled';
      case 'pending':
      case 'en_attente':
        // Vérifier si la facture est en retard (plus de 30 jours)
        final dueDate = invoiceDate.add(const Duration(days: 30));
        if (DateTime.now().isAfter(dueDate)) {
          return 'overdue';
        }
        return 'pending';
      default:
        return 'pending';
    }
  }

  List<Invoice> _getDemoInvoices() {
    return [
      Invoice(
        id: '1',
        number: 'FACT-2025-001',
        date: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().add(const Duration(days: 25)),
        amount: 1250.00,
        status: 'paid',
        description: 'Maintenance préventive chaudière',
      ),
      Invoice(
        id: '2',
        number: 'FACT-2025-002',
        date: DateTime.now().subtract(const Duration(days: 15)),
        dueDate: DateTime.now().add(const Duration(days: 15)),
        amount: 850.00,
        status: 'pending',
        description: 'Dépannage pompe à chaleur',
      ),
      Invoice(
        id: '3',
        number: 'FACT-2024-089',
        date: DateTime.now().subtract(const Duration(days: 45)),
        dueDate: DateTime.now().subtract(const Duration(days: 15)),
        amount: 2500.00,
        status: 'overdue',
        description: 'Installation thermostat connecté',
      ),
      Invoice(
        id: '4',
        number: 'FACT-2024-078',
        date: DateTime.now().subtract(const Duration(days: 90)),
        dueDate: DateTime.now().subtract(const Duration(days: 60)),
        amount: 450.00,
        status: 'paid',
        description: 'Entretien annuel',
      ),
    ];
  }

  List<Invoice> get _filteredInvoices {
    if (_filterStatus == 'all') {
      return _invoices;
    }
    return _invoices.where((i) => i.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SupportFabWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Mes Factures',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0a543d),
                  Color(0xFF0d6b4d),
                ],
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh, size: 20),
                ),
                onPressed: _loadInvoices,
                tooltip: 'Actualiser',
              ),
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
          child: Column(
            children: [
              // Statistiques modernes
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0a543d),
                      Color(0xFF0d6b4d),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total',
                            _invoices.length.toString(),
                            Icons.receipt_long_outlined,
                            const Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Payées',
                            _invoices
                                .where((i) => i.status == 'paid')
                                .length
                                .toString(),
                            Icons.check_circle_outline,
                            const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'En retard',
                            _invoices
                                .where((i) => i.status == 'overdue')
                                .length
                                .toString(),
                            Icons.warning_amber_outlined,
                            const Color(0xFFFF5252),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filtres modernes
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                          'Toutes', 'all', Icons.receipt_long_outlined),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                          'Payées', 'paid', Icons.check_circle_outline),
                      const SizedBox(width: 10),
                      _buildFilterChip('En attente', 'pending', Icons.schedule),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                          'En retard', 'overdue', Icons.warning_amber_outlined),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                          'Annulées', 'cancelled', Icons.cancel_outlined),
                    ],
                  ),
                ),
              ),

              // Liste des factures
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredInvoices.isEmpty
                        ? Center(
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
                                  Icon(Icons.receipt_outlined,
                                      size: 64,
                                      color: const Color(0xFF0a543d)
                                          .withOpacity(0.6)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune facture',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredInvoices.length,
                            itemBuilder: (context, index) {
                              final invoice = _filteredInvoices[index];
                              return _buildInvoiceCard(invoice);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0a543d).withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 8 : 6,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF0a543d),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : const Color(0xFF0a543d),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInvoiceDetails(invoice),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0a543d).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.number,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(invoice.date),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(invoice.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  invoice.description,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a543d).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0a543d).withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: invoice.status == 'overdue'
                                ? const Color(0xFFFF5252)
                                : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Échéance: ${_formatDate(invoice.dueDate)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: invoice.status == 'overdue'
                                  ? const Color(0xFFFF5252)
                                  : Colors.black54,
                              fontWeight: invoice.status == 'overdue'
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${invoice.amount.toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0a543d),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color primaryColor;
    Color secondaryColor;
    String label;
    IconData icon;

    switch (status) {
      case 'paid':
        primaryColor = const Color(0xFF4CAF50);
        secondaryColor = const Color(0xFF66BB6A);
        label = 'Payée';
        icon = Icons.check_circle;
        break;
      case 'pending':
        primaryColor = const Color(0xFFFF9800);
        secondaryColor = const Color(0xFFFFB74D);
        label = 'En attente';
        icon = Icons.schedule;
        break;
      case 'overdue':
        primaryColor = const Color(0xFFFF5252);
        secondaryColor = const Color(0xFFFF8A80);
        label = 'En retard';
        icon = Icons.warning;
        break;
      case 'cancelled':
        primaryColor = const Color(0xFF757575);
        secondaryColor = const Color(0xFF9E9E9E);
        label = 'Annulée';
        icon = Icons.cancel;
        break;
      default:
        primaryColor = const Color(0xFF9E9E9E);
        secondaryColor = const Color(0xFFBDBDBD);
        label = 'Inconnu';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showInvoiceDetails(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  invoice.number,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(invoice.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Description', invoice.description),
            _buildDetailRow('Date d\'émission', _formatDate(invoice.date)),
            _buildDetailRow('Date d\'échéance', _formatDate(invoice.dueDate)),
            _buildDetailRow(
              'Montant',
              '${invoice.amount.toStringAsFixed(0)} FCFA',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadInvoicePDF(invoice);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Télécharger'),
                  ),
                ),
                const SizedBox(width: 12),
                if (invoice.status != 'paid')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentScreen(
                              invoiceId: invoice.id,
                              invoiceNumber: invoice.number,
                              amount: invoice.amount,
                            ),
                          ),
                        );

                        // Si le paiement a réussi, recharger les factures
                        if (result == true) {
                          _loadInvoices();
                        }
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Payer'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadInvoicePDF(Invoice invoice) async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Télécharger le PDF
      final orderId = int.parse(invoice.id);
      final pdfBytes = await _apiService.downloadInvoicePDF(orderId);

      // Obtenir le répertoire de téléchargement
      Directory? directory;
      if (Platform.isAndroid) {
        // Sur Android 10+, utiliser getExternalStorageDirectory pour éviter les permissions
        directory = await getExternalStorageDirectory();
        // Créer un sous-dossier Download si possible
        if (directory != null) {
          final downloadDir = Directory('${directory.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          directory = downloadDir;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Créer le nom du fichier
      final fileName = 'facture-${invoice.number}.pdf';
      final filePath = '${directory!.path}/$fileName';

      // Sauvegarder le fichier
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        Navigator.pop(context); // Fermer le loader

        SnackBarHelper.showSuccess(
          context,
          'Facture téléchargée: $fileName',
          emoji: '📄',
          action: SnackBarAction(
            label: 'Ouvrir',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(filePath),
          ),
        );

        // Ouvrir automatiquement le fichier
        await OpenFile.open(filePath);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le loader

        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }
}

// Modèle de facture
class Invoice {
  final String id;
  final String number;
  final DateTime date;
  final DateTime dueDate;
  final double amount;
  final String status;
  final String description;

  Invoice({
    required this.id,
    required this.number,
    required this.date,
    required this.dueDate,
    required this.amount,
    required this.status,
    required this.description,
  });
}
