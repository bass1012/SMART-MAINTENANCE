import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart'; // Temporairement désactivé
import '../../services/split_service.dart';
import '../../models/split.dart' as models;

/// Écran de scan QR pour identifier un split lors d'une intervention
class SplitScanScreen extends StatefulWidget {
  final int interventionId;
  final int? customerId; // Pour vérifier que le split appartient au bon client
  final Function(models.SplitScanResult)? onSplitScanned;

  const SplitScanScreen({
    Key? key,
    required this.interventionId,
    this.customerId,
    this.onSplitScanned,
  }) : super(key: key);

  @override
  State<SplitScanScreen> createState() => _SplitScanScreenState();
}

class _SplitScanScreenState extends State<SplitScanScreen> {
  final SplitService _splitService = SplitService();

  bool _isProcessing = false;
  bool _hasScanned = false;
  String? _errorMessage;
  models.SplitScanResult? _scanResult;

  @override
  void initState() {
    super.initState();
    // Ne PAS lancer le scan automatiquement - laisser l'utilisateur choisir
    // Cela évite les crashs sur simulateur
  }

  Future<void> _startQRScan() async {
    if (_isProcessing || _hasScanned) return;

    // Scanner QR temporairement désactivé - conflit dépendances iOS
    setState(() {
      _errorMessage =
          'Scanner QR temporairement indisponible. Veuillez utiliser la saisie manuelle.';
    });
    return;

    // Code désactivé temporairement
    // final barcodeScanRes = await Navigator.push<String>(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => _QRScannerView(),
    //   ),
    // );
    //
    // // Si l'utilisateur a annulé ou aucun résultat
    // if (barcodeScanRes == null) {
    //   return; // Ne pas fermer l'écran, rester sur les options
    // }
    //
    // await _processQRCode(barcodeScanRes);
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing || _hasScanned) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Parser les données du QR code
    final parsedData = _splitService.parseQRData(qrData);

    if (parsedData == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'QR code invalide. Ce n\'est pas un code split.';
      });
      return;
    }

    final splitCode = parsedData['code'] as String;
    print('🔍 Code split scanné: $splitCode');

    // Rechercher le split et l'associer à l'intervention
    final result = await _splitService.scanSplitForIntervention(
      interventionId: widget.interventionId,
      splitCode: splitCode,
      scanMethod: 'qr_scan',
    );

    if (result == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Erreur de connexion au serveur.';
      });
      return;
    }

    if (result['error'] == true) {
      setState(() {
        _isProcessing = false;
        _errorMessage = result['message'] ?? 'Erreur inconnue';

        // Si c'est un warning de mauvais client, afficher un dialog spécial
        if (result['warning'] == 'SPLIT_CUSTOMER_MISMATCH') {
          _showCustomerMismatchDialog(splitCode);
        }
      });
      return;
    }

    // Succès ! Construire le résultat
    final splitData = result['split'];
    final activeOfferData = result['activeOffer'];

    final scanResult = models.SplitScanResult(
      split: models.Split.fromJson(splitData),
      activeOffer: activeOfferData != null
          ? models.SplitActiveOffer.fromJson(activeOfferData)
          : null,
      hasActiveOffer: result['hasActiveOffer'] ?? false,
    );

    setState(() {
      _isProcessing = false;
      _hasScanned = true;
      _scanResult = scanResult;
    });

    // Afficher le résumé
    _showScanResultDialog(scanResult);
  }

  void _showCustomerMismatchDialog(String splitCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Attention'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ce split n\'appartient pas au client de cette intervention.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Code scanné: $splitCode',
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScan();
            },
            child: Text('Rescanner'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualSelectionSheet();
            },
            child: Text('Sélection manuelle'),
          ),
        ],
      ),
    );
  }

  void _showScanResultDialog(models.SplitScanResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SplitResultSheet(
        result: result,
        onConfirm: () {
          Navigator.pop(context);
          if (widget.onSplitScanned != null) {
            widget.onSplitScanned!(result);
          }
          Navigator.pop(context, result);
        },
        onRescan: () {
          Navigator.pop(context);
          _resetScan();
        },
      ),
    );
  }

  void _resetScan() {
    setState(() {
      _hasScanned = false;
      _scanResult = null;
      _errorMessage = null;
    });
    // Relancer le scan
    _startQRScan();
  }

  void _showManualSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualSplitSelectionSheet(
        customerId: widget.customerId,
        interventionId: widget.interventionId,
        onSplitSelected: (result) {
          Navigator.pop(context);
          if (widget.onSplitScanned != null) {
            widget.onSplitScanned!(result);
          }
          Navigator.pop(context, result);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner le Split'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicateur de traitement
            if (_isProcessing) ...[
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text(
                'Vérification en cours...',
                style: TextStyle(fontSize: 16),
              ),
            ] else if (_hasScanned && _scanResult != null) ...[
              // Succès
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              SizedBox(height: 24),
              Text(
                'Split identifié',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _scanResult!.split.splitCode,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              // Instructions
              Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 24),
              Text(
                'Scanner le QR Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Scannez le QR code collé sur le split (climatiseur) pour l\'identifier.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),

              // Message d'erreur
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
              ],

              // Boutons d'action
              ElevatedButton.icon(
                onPressed: _startQRScan,
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Scanner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
              SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _showManualSelectionSheet,
                icon: Icon(Icons.list),
                label: Text('QR absent/illisible'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet affichant le résultat du scan
class _SplitResultSheet extends StatelessWidget {
  final models.SplitScanResult result;
  final VoidCallback onConfirm;
  final VoidCallback onRescan;

  const _SplitResultSheet({
    required this.result,
    required this.onConfirm,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    final split = result.split;
    final offer = result.activeOffer;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Contenu
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre avec icône de succès
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Split identifié',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            split.splitCode,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Infos du split
                _InfoRow(
                  icon: Icons.ac_unit,
                  label: 'Équipement',
                  value: split.displayName,
                ),
                if (split.location != null)
                  _InfoRow(
                    icon: Icons.room,
                    label: 'Localisation',
                    value:
                        '${split.location}${split.floor != null ? ' (${split.floor})' : ''}',
                  ),
                _InfoRow(
                  icon: Icons.speed,
                  label: 'Puissance',
                  value: split.formattedPower,
                ),
                if (split.lastMaintenanceDate != null)
                  _InfoRow(
                    icon: Icons.history,
                    label: 'Dernier entretien',
                    value: _formatDate(split.lastMaintenanceDate!),
                  ),

                SizedBox(height: 20),

                // Offre active
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: result.hasActiveOffer
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: result.hasActiveOffer
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            result.hasActiveOffer
                                ? Icons.verified
                                : Icons.warning_amber,
                            color: result.hasActiveOffer
                                ? Colors.green
                                : Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            result.hasActiveOffer
                                ? 'Offre active'
                                : 'Aucune offre active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: result.hasActiveOffer
                                  ? Colors.green[800]
                                  : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                      if (offer != null) ...[
                        SizedBox(height: 8),
                        Text(
                          offer.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (offer.description != null)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              offer.description!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        if (offer.features != null &&
                            offer.features!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: offer.features!
                                  .take(3)
                                  .map(
                                    (f) => Chip(
                                      label: Text(f,
                                          style: TextStyle(fontSize: 11)),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.zero,
                                      labelPadding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        if (offer.endDate != null)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Expire le ${_formatDate(offer.endDate!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: offer.expiresSoon
                                    ? Colors.orange[700]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRescan,
                        child: Text('Rescanner'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Confirmer et continuer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet pour sélection manuelle du split
class _ManualSplitSelectionSheet extends StatefulWidget {
  final int? customerId;
  final int interventionId;
  final Function(models.SplitScanResult) onSplitSelected;

  const _ManualSplitSelectionSheet({
    this.customerId,
    required this.interventionId,
    required this.onSplitSelected,
  });

  @override
  State<_ManualSplitSelectionSheet> createState() =>
      _ManualSplitSelectionSheetState();
}

class _ManualSplitSelectionSheetState
    extends State<_ManualSplitSelectionSheet> {
  final SplitService _splitService = SplitService();
  List<models.Split> _splits = [];
  bool _isLoading = true;
  String? _selectedReason;
  models.Split? _selectedSplit;

  final List<String> _exceptionReasons = [
    'QR code absent',
    'QR code illisible',
    'QR code endommagé',
    'Étiquette décollée',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadSplits();
  }

  Future<void> _loadSplits() async {
    print(
        '🔍 Chargement des splits - customerId: ${widget.customerId}, interventionId: ${widget.interventionId}');

    List<models.Split> splits = [];

    // Essayer différentes méthodes pour récupérer les splits
    if (widget.customerId != null) {
      // 1. Par customer_id si disponible
      splits = await _splitService.getCustomerSplits(widget.customerId!);
      print('📋 Splits par customerId: ${splits.length}');
    }

    if (splits.isEmpty) {
      // 2. Par intervention_id
      splits =
          await _splitService.getSplitsForIntervention(widget.interventionId);
      print('📋 Splits par interventionId: ${splits.length}');
    }

    if (splits.isEmpty) {
      // 3. Fallback: tous les splits
      splits = await _splitService.getAllSplits();
      print('📋 Tous les splits: ${splits.length}');
    }

    setState(() {
      _splits = splits;
      _isLoading = false;
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedSplit == null || _selectedReason == null) return;

    setState(() => _isLoading = true);

    final result = await _splitService.scanSplitForIntervention(
      interventionId: widget.interventionId,
      splitCode: _selectedSplit!.splitCode,
      scanMethod: 'manual_selection',
      exceptionReason: _selectedReason,
    );

    if (result != null && result['error'] != true) {
      final scanResult = models.SplitScanResult(
        split: models.Split.fromJson(result['split']),
        activeOffer: result['activeOffer'] != null
            ? models.SplitActiveOffer.fromJson(result['activeOffer'])
            : null,
        hasActiveOffer: result['hasActiveOffer'] ?? false,
      );
      widget.onSplitSelected(scanResult);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['message'] ?? 'Erreur lors de la sélection'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titre
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Theme.of(context).primaryColor),
                SizedBox(width: 12),
                Text(
                  'Sélection manuelle du split',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Raison de l'exception
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motif de sélection manuelle *',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _exceptionReasons
                      .map(
                        (reason) => ChoiceChip(
                          label: Text(reason),
                          selected: _selectedReason == reason,
                          onSelected: (selected) {
                            setState(() =>
                                _selectedReason = selected ? reason : null);
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Liste des splits
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _splits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.ac_unit,
                                size: 64, color: Colors.grey[300]),
                            SizedBox(height: 16),
                            Text(
                              'Aucun split enregistré',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(16),
                        itemCount: _splits.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final split = _splits[index];
                          final isSelected = _selectedSplit?.id == split.id;

                          return Card(
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedSplit = split),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.ac_unit,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            split.displayName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            split.location ??
                                                'Localisation non définie',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            split.splitCode,
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              color: Colors.grey[500],
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (split.hasActiveOffer)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          split.activeOffer!.title,
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    if (isSelected)
                                      Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bouton confirmer
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedSplit != null && _selectedReason != null)
                    ? _confirmSelection
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text('Confirmer la sélection'),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// Widget pour afficher le scanner QR
/// Temporairement désactivé - conflit dépendances iOS mobile_scanner
class _QRScannerView extends StatelessWidget {
  const _QRScannerView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner le QR Code'),
        backgroundColor: const Color(0xFF0a543d),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // MobileScanner désactivé temporairement - conflit dépendances iOS
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'Scanner QR temporairement indisponible',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Retour'),
                ),
              ],
            ),
          ),
          // MobileScanner(
          //   onDetect: onDetect,
          // ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Positionnez le QR code dans le cadre',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
