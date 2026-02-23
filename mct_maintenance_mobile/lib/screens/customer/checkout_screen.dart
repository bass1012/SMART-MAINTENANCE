import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import '../../widgets/common/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/cart_service.dart';
import '../../services/api_service.dart';
import '../../services/payment_service.dart';
import 'payment_status_screen.dart';
import 'payment_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _promoCodeController = TextEditingController();
  bool _isProcessing = false;
  bool _isLoadingLocation = false;
  bool _isValidatingPromo = false;
  Map<String, dynamic>? _appliedPromo;
  double _discount = 0.0;
  late final PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    final apiService = ApiService();
    _paymentService = PaymentService(apiService);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _validatePromoCode() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) {
      SnackBarHelper.showWarning(context, 'Veuillez entrer un code promo');
      return;
    }

    setState(() => _isValidatingPromo = true);

    try {
      final cart = Provider.of<CartService>(context, listen: false);
      final api = ApiService(); // Créer une instance directement

      final response = await api.post('/promotions/validate', {
        'code': code,
        'orderAmount': cart.totalAmount,
      });

      if (response['success']) {
        final promo = response['data'];
        double discountAmount = 0;

        if (promo['type'] == 'percentage') {
          discountAmount = (cart.totalAmount * promo['value']) / 100;
        } else if (promo['type'] == 'fixed') {
          discountAmount = promo['value'].toDouble();
        }

        // S'assurer que la réduction ne dépasse pas le montant total
        if (discountAmount > cart.totalAmount) {
          discountAmount = cart.totalAmount;
        }

        setState(() {
          _appliedPromo = promo;
          _discount = discountAmount;
        });

        SnackBarHelper.showSuccess(
          context,
          'Code promo appliqué ! Réduction de ${discountAmount.toStringAsFixed(0)} FCFA',
        );
      } else {
        SnackBarHelper.showError(
            context, response['message'] ?? 'Code promo invalide');
      }
    } catch (e) {
      print('❌ Erreur validation promo: $e');
      SnackBarHelper.showError(
        context,
        'Erreur lors de la validation du code promo: ${e.toString()}',
      );
    } finally {
      setState(() => _isValidatingPromo = false);
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromo = null;
      _discount = 0.0;
      _promoCodeController.clear();
    });
    SnackBarHelper.showInfo(context, 'Code promo retiré');
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          SnackBarHelper.showWarning(
              context, 'Les services de localisation sont désactivés');
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            SnackBarHelper.showError(
                context, 'Permission de localisation refusée');
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          SnackBarHelper.showError(context,
              'Permission de localisation refusée définitivement. Activez-la dans les paramètres.',
              duration: const Duration(seconds: 4));
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convertir les coordonnées en adresse
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';

        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += address.isNotEmpty
              ? ', ${place.subLocality}'
              : place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address +=
              address.isNotEmpty ? ', ${place.locality}' : place.locality!;
        }
        if (place.country != null && place.country!.isNotEmpty) {
          address += address.isNotEmpty ? ', ${place.country}' : place.country!;
        }

        if (address.isEmpty) {
          address =
              'Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}';
        }

        _addressController.text = address;

        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Position récupérée avec succès',
              emoji: '📍', duration: const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
            context, 'Erreur lors de la récupération de la position: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _processPayment({bool isCash = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cart = Provider.of<CartService>(context, listen: false);
      final apiService = ApiService();

      // Préparer les données de la commande
      final orderData = {
        'items': cart.items
            .map((item) => {
                  'product_id': item.product.id,
                  'quantity': item.quantity,
                  'prix_unitaire': item.product.prix,
                })
            .toList(),
        'montant_total': cart.totalAmount - _discount,
        'shipping_address': _addressController.text,
        'telephone': _phoneController.text,
        'notes': _notesController.text,
        'payment_method': isCash ? 'Espèces à la livraison' : 'FineoPay',
        'statut_paiement': isCash ? 'en_attente' : 'en_cours',
        if (_appliedPromo != null) ...{
          'promo_code': _appliedPromo!['code'],
          'promo_discount': _discount,
          'promo_id': _appliedPromo!['id'],
        },
      };

      // Créer la commande
      final response = await apiService.post('/orders', orderData);
      final orderId = response['data']['id'];
      final totalAmount = response['data']['totalAmount'];
      final reference = response['data']['reference'];

      if (mounted) {
        if (isCash) {
          // Pour le paiement en espèces, juste confirmer
          cart.clear();
          SnackBarHelper.showSuccess(
            context,
            'Commande passée avec succès !',
            emoji: '🎉',
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // Pour FineoPay, initialiser le paiement
          print('💳 Initialisation paiement FineoPay pour commande #$orderId');
          final paymentData = await _paymentService.initializeOrderPayment(
            orderId,
            totalAmount.toDouble(),
            reference,
          );

          final paymentUrl = paymentData['paymentUrl'];
          print('🔗 URL de paiement reçue: $paymentUrl');

          if (paymentUrl != null && paymentUrl.toString().isNotEmpty) {
            try {
              print('📱 Ouverture du WebView pour le paiement...');

              // Ouvrir le paiement dans un WebView intégré
              final paymentResult = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentWebViewScreen(
                    paymentUrl: paymentUrl,
                    title: 'Paiement commande #$reference',
                    orderId: orderId,
                  ),
                ),
              );

              if (mounted) {
                cart.clear();
                if (paymentResult == true) {
                  // Paiement réussi
                  print('✅ Paiement réussi via WebView');
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => PaymentStatusScreen(
                        orderId: orderId,
                        orderReference: reference,
                      ),
                    ),
                  );
                } else {
                  // Paiement annulé ou échoué - retourner à l'accueil
                  print('❌ Paiement annulé ou échoué');
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            } catch (e) {
              print('❌ Erreur lors du paiement: $e');
              if (mounted) {
                SnackBarHelper.showError(
                  context,
                  'Erreur lors du paiement: $e',
                );
              }
            }
          } else {
            print('❌ URL de paiement manquante dans la réponse');
            if (mounted) {
              SnackBarHelper.showError(
                context,
                'URL de paiement manquante',
              );
            }
          }
        }
      }
    } catch (e) {
      print('❌ Erreur traitement commande: $e');
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Résumé de la commande
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Résumé de la commande',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Articles (${cart.itemCount})',
                            style: GoogleFonts.nunitoSans(fontSize: 14),
                          ),
                          Text(
                            '${cart.totalAmount.toStringAsFixed(0)} FCFA',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Livraison',
                            style: GoogleFonts.nunitoSans(fontSize: 14),
                          ),
                          Text(
                            'Gratuite',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Afficher la réduction si un code promo est appliqué
                      if (_appliedPromo != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Réduction ',
                                  style: GoogleFonts.nunitoSans(fontSize: 14),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    _appliedPromo!['code'],
                                    style: GoogleFonts.nunitoSans(
                                      fontSize: 11,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '-${_discount.toStringAsFixed(0)} FCFA',
                              style: GoogleFonts.nunitoSans(
                                fontSize: 14,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(cart.totalAmount - _discount).toStringAsFixed(0)} FCFA',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0a543d),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Code Promo
              Text(
                'Code Promo',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (_appliedPromo == null)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _promoCodeController,
                        decoration: InputDecoration(
                          labelText: 'Entrez votre code promo',
                          prefixIcon: const Icon(Icons.local_offer),
                          border: const OutlineInputBorder(),
                          hintText: 'Ex: PROMO2025',
                          suffixIcon: _isValidatingPromo
                              ? Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 40,
                                    height: 20,
                                    child: ButtonLoadingIndicator(
                                        color: Color(0xFF0a543d), size: 6.0),
                                  ),
                                )
                              : null,
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isValidatingPromo ? null : _validatePromoCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Appliquer'),
                    ),
                  ],
                )
              else
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Code promo appliqué : ${_appliedPromo!['code']}',
                                style: GoogleFonts.nunitoSans(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade900,
                                ),
                              ),
                              Text(
                                _appliedPromo!['name'] ?? '',
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _removePromoCode,
                          color: Colors.red,
                          tooltip: 'Retirer',
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Informations de livraison
              Text(
                'Informations de livraison',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro de téléphone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Adresse de livraison',
                  prefixIcon: const Icon(Icons.location_on),
                  border: const OutlineInputBorder(),
                  suffixIcon: _isLoadingLocation
                      ? Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 40,
                            height: 20,
                            child: ButtonLoadingIndicator(
                              color: Color(0xFF0a543d),
                              size: 6.0,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _getCurrentLocation,
                          tooltip: 'Ma position actuelle',
                          color: const Color(0xFF0a543d),
                        ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre adresse';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Appuyez sur l\'icône 📍 pour utiliser votre position actuelle',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Information FineoPay
              _buildFineoPayInfo(),
              const SizedBox(height: 16),

              // Note de sécurité
              _buildSecurityNote(),
              const SizedBox(height: 32),

              // Bouton de paiement FineoPay
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _processPayment(isCash: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isProcessing
                      ? const SizedBox.shrink()
                      : const Icon(Icons.credit_card),
                  label: _isProcessing
                      ? ButtonLoadingIndicator(color: Colors.white, size: 6.0)
                      : Text(
                          'Payer ${(cart.totalAmount - _discount).toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Bouton paiement en espèces
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _processPayment(isCash: true),
                  icon: const Icon(Icons.money),
                  label: const Text(
                    'Payer en espèces à la livraison',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0a543d),
                    side: const BorderSide(
                      color: Color(0xFF0a543d),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFineoPayInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payment,
                  color: Color(0xFF0a543d),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Paiement sécurisé avec FineoPay',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Modes de paiement disponibles :',
              style: GoogleFonts.nunitoSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            // Logos Mobile Money
            Row(
              children: [
                const SizedBox(width: 4),
                Image.asset('assets/images/orange_money.png',
                    height: 40, width: 40),
                const SizedBox(width: 12),
                Image.asset('assets/images/mtn_money.png',
                    height: 40, width: 40),
                const SizedBox(width: 12),
                Image.asset('assets/images/moov_money.png',
                    height: 40, width: 40),
                const SizedBox(width: 12),
                Image.asset('assets/images/wave.png', height: 40, width: 40),
              ],
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
                Icons.credit_card, 'Carte bancaire', 'Visa, Mastercard'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vos informations de paiement sont sécurisées et cryptées',
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
