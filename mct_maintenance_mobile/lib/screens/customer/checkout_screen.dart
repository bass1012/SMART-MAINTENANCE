import '../../utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/cart_service.dart';
import '../../services/api_service.dart';

enum PaymentMethod {
  wave,
  orangeMoney,
  moovMoney,
  mtnMoney,
  card,
  cashOnDelivery,
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod? _selectedPaymentMethod;
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

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPaymentMethod == null) {
      SnackBarHelper.showWarning(
          context, 'Veuillez sélectionner une méthode de paiement');
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
        'payment_method': _getPaymentMethodString(_selectedPaymentMethod!),
        'statut_paiement':
            _selectedPaymentMethod == PaymentMethod.cashOnDelivery
                ? 'en_attente'
                : 'en_cours',
        if (_appliedPromo != null) ...{
          'promo_code': _appliedPromo!['code'],
          'promo_discount': _discount,
          'promo_id': _appliedPromo!['id'],
        },
      };

      // Envoyer la commande à l'API
      final response = await apiService.post('/orders', orderData);

      if (mounted) {
        // Vider le panier
        cart.clear();

        // Afficher un message de succès
        SnackBarHelper.showSuccess(
          context,
          _selectedPaymentMethod == PaymentMethod.cashOnDelivery
              ? 'Commande passée avec succès !'
              : 'Paiement en cours de traitement...',
          emoji: '🎉',
        );

        // Rediriger vers l'écran de confirmation
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _getPaymentMethodString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.wave:
        return 'Wave';
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.moovMoney:
        return 'Moov Money';
      case PaymentMethod.mtnMoney:
        return 'MTN Money';
      case PaymentMethod.card:
        return 'Carte bancaire';
      case PaymentMethod.cashOnDelivery:
        return 'Espèces à la livraison';
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
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
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
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
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

              // Méthodes de paiement
              Text(
                'Méthode de paiement',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Mobile Money avec logos
              _buildPaymentOptionWithLogo(
                PaymentMethod.orangeMoney,
                'Orange Money',
                'assets/images/orange_money.png',
              ),
              _buildPaymentOptionWithLogo(
                PaymentMethod.mtnMoney,
                'MTN Mobile Money',
                'assets/images/mtn_money.png',
              ),
              _buildPaymentOptionWithLogo(
                PaymentMethod.moovMoney,
                'Moov Money',
                'assets/images/moov_money.png',
              ),
              _buildPaymentOptionWithLogo(
                PaymentMethod.wave,
                'Wave',
                'assets/images/wave.png',
              ),

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // Autres méthodes
              _buildPaymentOption(
                PaymentMethod.card,
                'Carte bancaire',
                Icons.credit_card,
                Colors.purple,
              ),
              _buildPaymentOption(
                PaymentMethod.cashOnDelivery,
                'Espèces à la livraison',
                Icons.money,
                Colors.green,
              ),

              const SizedBox(height: 32),

              // Bouton de paiement
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _selectedPaymentMethod == PaymentMethod.cashOnDelivery
                              ? 'Confirmer la commande'
                              : 'Procéder au paiement',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    String title,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod == method;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0a543d) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF0a543d),
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Nouvelle méthode avec logo pour Mobile Money
  Widget _buildPaymentOptionWithLogo(
    PaymentMethod method,
    String title,
    String logoPath,
  ) {
    final isSelected = _selectedPaymentMethod == method;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0a543d) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Logo de l'opérateur
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(2),
                child: Image.asset(
                  logoPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.phone_android,
                      color: const Color(0xFF0a543d),
                      size: 28,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF0a543d),
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
