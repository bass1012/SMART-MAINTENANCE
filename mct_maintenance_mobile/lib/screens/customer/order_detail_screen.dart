import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commande #${widget.order['id']}'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isDownloading ? null : _downloadInvoice,
            tooltip: 'Télécharger la facture',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut de la commande
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Informations de la commande
            _buildInfoCard(),
            const SizedBox(height: 16),

            // Articles de la commande
            _buildItemsCard(),
            const SizedBox(height: 16),

            // Total
            _buildTotalCard(),
            const SizedBox(height: 24),

            // Bouton de téléchargement
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadInvoice,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isDownloading
                    ? 'Téléchargement...'
                    : 'Télécharger la facture PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0a543d),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = widget.order['status'] ?? 'pending';
    final statusInfo = _getStatusInfo(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusInfo['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                statusInfo['icon'],
                color: statusInfo['color'],
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statut',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusInfo['label'],
                    style: TextStyle(
                      color: statusInfo['color'],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow('Référence', widget.order['reference'] ?? 'N/A'),
            _buildInfoRow(
                'Date',
                _formatDate(
                    widget.order['createdAt'] ?? widget.order['created_at'])),
            _buildInfoRow(
                'Mode de paiement',
                widget.order['paymentMethod'] ??
                    widget.order['payment_method'] ??
                    'N/A'),
            _buildInfoRow(
                'Adresse de livraison',
                widget.order['shippingAddress'] ??
                    widget.order['shipping_address'] ??
                    'N/A'),
            if (widget.order['notes'] != null &&
                widget.order['notes'].toString().isNotEmpty)
              _buildInfoRow('Notes', widget.order['notes']),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    final items = widget.order['items'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Articles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            if (items.isEmpty)
              const Text('Aucun article')
            else
              ...items.map<Widget>((item) => _buildItemRow(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final product = item['product'] ?? {};
    final productName = product['nom'] ?? product['name'] ?? 'Produit';
    final quantity = item['quantity'] ?? 1;
    final unitPrice = double.tryParse(item['unit_price']?.toString() ??
            item['unitPrice']?.toString() ??
            '0') ??
        0.0;
    final total = double.tryParse(item['total']?.toString() ?? '0') ??
        (quantity * unitPrice);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantité: $quantity × ${_formatCurrency(unitPrice)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(total),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    final totalAmount = double.tryParse(
            widget.order['totalAmount']?.toString() ??
                widget.order['total_amount']?.toString() ??
                '0') ??
        0.0;

    return Card(
      color: const Color(0xFF0a543d).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatCurrency(totalAmount),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0a543d),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return {
          'label': 'Livrée',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'processing':
      case 'confirmed':
        return {
          'label': 'En cours',
          'color': Colors.blue,
          'icon': Icons.hourglass_empty,
        };
      case 'cancelled':
        return {
          'label': 'Annulée',
          'color': Colors.red,
          'icon': Icons.cancel,
        };
      default:
        return {
          'label': 'En attente',
          'color': Colors.orange,
          'icon': Icons.pending,
        };
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} FCFA';
  }

  Future<void> _downloadInvoice() async {
    setState(() => _isDownloading = true);

    try {
      // Télécharger le PDF
      final orderId = int.parse(widget.order['id'].toString());
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
      final fileName =
          'facture-${widget.order['reference'] ?? widget.order['id']}.pdf';
      final filePath = '${directory!.path}/$fileName';

      // Sauvegarder le fichier
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
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
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }
}
