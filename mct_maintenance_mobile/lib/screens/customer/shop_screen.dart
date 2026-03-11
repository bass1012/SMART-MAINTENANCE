import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mct_maintenance_mobile/services/api_service.dart';
import 'package:mct_maintenance_mobile/models/product_model.dart';
import 'package:mct_maintenance_mobile/models/maintenance_offer_model.dart';
import 'package:mct_maintenance_mobile/services/cart_service.dart';
import 'package:mct_maintenance_mobile/widgets/common/support_fab_wrapper.dart';
import 'cart_screen.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/test_keys.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isLoadingBrands = true;
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _brands = [];
  String _selectedCategory = 'all';
  int? _selectedBrandId;
  String _searchQuery = '';
  MaintenanceOffer? _premiumOffer; // Offre premium pour les climatiseurs

  @override
  void initState() {
    super.initState();
    _loadBrands();
    _loadProducts();
    _loadPremiumOffer();
  }

  Future<void> _loadPremiumOffer() async {
    try {
      final offers = await _apiService.getMaintenanceOffers();
      if (mounted && offers.isNotEmpty) {
        // Chercher l'offre "Premium" en priorité, sinon la plus chère
        MaintenanceOffer? premiumOffer;

        // 1. Chercher par nom contenant "premium"
        premiumOffer = offers
            .where((o) => o.isActive)
            .cast<MaintenanceOffer?>()
            .firstWhere(
              (o) => o!.title.toLowerCase().contains('premium'),
              orElse: () => null,
            );

        // 2. Si pas trouvé, chercher par nom contenant "gold" ou "or"
        premiumOffer ??= offers
            .where((o) => o.isActive)
            .cast<MaintenanceOffer?>()
            .firstWhere(
              (o) =>
                  o!.title.toLowerCase().contains('gold') ||
                  o.title.toLowerCase().contains('or'),
              orElse: () => null,
            );

        // 3. Si toujours pas trouvé, prendre l'offre active la plus chère
        if (premiumOffer == null) {
          final activeOffers = offers.where((o) => o.isActive).toList();
          if (activeOffers.isNotEmpty) {
            activeOffers.sort((a, b) => b.price.compareTo(a.price));
            premiumOffer = activeOffers.first;
          }
        }

        setState(() {
          _premiumOffer = premiumOffer;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'offre premium: $e');
    }
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoadingBrands = true);

    try {
      final response = await _apiService.get('/brands');

      if (mounted) {
        final List<dynamic> brandsData = response['data'] ?? [];
        setState(() {
          _brands = brandsData
              .map((brand) => {
                    'id': brand['id'],
                    'nom': brand['nom'],
                  })
              .toList();
          _isLoadingBrands = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBrands = false);
        print('Erreur lors du chargement des marques: $e');
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.getProducts(
        category: _selectedCategory != 'all' ? _selectedCategory : null,
        brandId: _selectedBrandId,
      );

      if (mounted) {
        final List<dynamic> productsData = response['data'] ?? [];
        setState(() {
          _products =
              productsData.map((json) => ProductModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Erreur: $e');
      }
    }
  }

  List<ProductModel> get _filteredProducts {
    var filtered = _products;

    // Filtrer par marque
    if (_selectedBrandId != null) {
      filtered = filtered
          .where((product) => product.marqueId == _selectedBrandId)
          .toList();
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final query = _searchQuery.toLowerCase();
        return product.nom.toLowerCase().contains(query) ||
            (product.description?.toLowerCase().contains(query) ?? false) ||
            product.sku.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  // Obtenir les marques qui ont des produits
  List<Map<String, dynamic>> get _brandsWithProducts {
    if (_products.isEmpty) return [];

    // Obtenir les IDs de marques qui ont au moins un produit
    final brandIdsWithProducts = _products
        .where((product) => product.marqueId != null)
        .map((product) => product.marqueId)
        .toSet();

    // Filtrer les marques pour ne garder que celles qui ont des produits
    return _brands
        .where((brand) => brandIdsWithProducts.contains(brand['id']))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SupportFabWrapper(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0a543d),
          elevation: 0,
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white70,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh, size: 20),
                ),
                onPressed: () {
                  _loadBrands();
                  _loadProducts();
                },
                tooltip: 'Actualiser',
              ),
            ),
            Consumer<CartService>(
              builder: (context, cart, child) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shopping_cart_outlined,
                              size: 20),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CartScreen(),
                            ),
                          );
                        },
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.red, Colors.redAccent],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '${cart.itemCount}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
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
              // Header avec filtres par marque
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: _isLoadingBrands || _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: const Color(0xFF0a543d),
                              ),
                            )
                          : _brandsWithProducts.isEmpty
                              ? Center(
                                  child: Text(
                                    'Aucune marque disponible',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  children: [
                                    _buildBrandChip('Tout', null),
                                    ..._brandsWithProducts
                                        .map((brand) => _buildBrandChip(
                                              brand['nom'],
                                              brand['id'],
                                            )),
                                  ],
                                ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Liste des produits
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun produit disponible',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            key: const ValueKey(TestKeys.productsList),
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return _buildProductCard(product);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandChip(String label, int? brandId) {
    final isSelected = _selectedBrandId == brandId;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedBrandId = brandId;
            _loadProducts();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0a543d).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Consumer<CartService>(
      builder: (context, cart, child) {
        return GestureDetector(
          onTap: () => _showProductDetails(product),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image du produit avec badge stock
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Image.network(
                                  product.imageUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                      ),
                      if (!product.inStock)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Rupture',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      // Badge Offre pour les climatiseurs (categorie_id = 1)
                      if (product.categorieId == 1 && _premiumOffer != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _premiumOffer!.title.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Informations du produit
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  product.nom,
                                  maxLines: product.categorieId == 1 ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              // Offre pour les climatiseurs
                              if (product.categorieId == 1 &&
                                  _premiumOffer != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3CD),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFFFD700),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.card_giftcard,
                                        size: 10,
                                        color: Color(0xFFD4A800),
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          '${_premiumOffer!.title} incluse',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFD4A800),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                '${product.prix.toStringAsFixed(0)} FCFA',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF0a543d),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bouton ajouter au panier moderne
                        SizedBox(
                          width: double.infinity,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: product.inStock
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF0a543d),
                                        Color(0xFF0d6b4d)
                                      ],
                                    )
                                  : null,
                              color:
                                  product.inStock ? null : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: product.inStock
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0a543d)
                                            .withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: product.inStock
                                    ? () {
                                        cart.addItem(product);
                                        // Fermer tous les SnackBars existants
                                        ScaffoldMessenger.of(context)
                                            .clearSnackBars();
                                        // Afficher un SnackBar simple qui se ferme automatiquement
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '🛒 ${product.nom} ajouté au panier'),
                                            duration: const Duration(
                                                milliseconds: 1500),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(16),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_shopping_cart,
                                        size: 14,
                                        color: product.inStock
                                            ? Colors.white
                                            : Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        product.inStock
                                            ? 'Ajouter'
                                            : 'Indisponible',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: product.inStock
                                              ? Colors.white
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProductDetails(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<CartService>(
        builder: (context, cart, child) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image avec badge stock
                      Stack(
                        children: [
                          Container(
                            height: 280,
                            width: double.infinity,
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: product.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 80,
                                            color: Colors.grey.shade400,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 80,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                          ),
                          // Badge stock
                          if (!product.inStock)
                            Positioned(
                              top: 26,
                              right: 26,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF5252),
                                      Color(0xFFD32F2F)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Rupture de stock',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Nom et prix
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nom,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0a543d),
                                    Color(0xFF0d6b4d)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0a543d)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${product.prix.toStringAsFixed(0)} FCFA',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Informations détaillées
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Référence
                            _buildDetailRow(
                              icon: Icons.tag,
                              label: 'Référence',
                              value:
                                  product.sku.isNotEmpty ? product.sku : 'N/A',
                            ),

                            // Prix unitaire
                            _buildDetailRow(
                              icon: Icons.payments,
                              label: 'Prix unitaire',
                              value: '${product.prix.toStringAsFixed(0)} FCFA',
                              valueColor: const Color(0xFF0a543d),
                            ),

                            // Stock disponible
                            _buildDetailRow(
                              icon: product.inStock
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              label: 'Disponibilité',
                              value: product.inStock
                                  ? 'En stock (${product.quantiteStock ?? 0} unités)'
                                  : 'Rupture de stock',
                              valueColor:
                                  product.inStock ? Colors.green : Colors.red,
                            ),

                            // Spécifications
                            if (product.specifications != null &&
                                product.specifications!.isNotEmpty)
                              _buildDetailRow(
                                icon: Icons.info_outline,
                                label: 'Spécifications',
                                value: product.specifications!,
                              ),

                            const SizedBox(height: 24),

                            // Description
                            if (product.description != null &&
                                product.description!.isNotEmpty) ...[
                              Text(
                                'Description',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  product.description!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],

                            // Offre Premium pour les climatiseurs
                            if (product.categorieId == 1 &&
                                _premiumOffer != null) ...[
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFFF8E1),
                                      Color(0xFFFFECB3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD700),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _premiumOffer!.title
                                                    .toUpperCase(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      const Color(0xFFD4A800),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              Text(
                                                'Inclus avec l\'achat de ce climatiseur',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.brown.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_premiumOffer!
                                        .description.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _premiumOffer!.description,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.brown.shade700,
                                            fontStyle: FontStyle.italic,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    const Divider(color: Color(0xFFFFD700)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Fonctionnalités incluses:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.brown.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ..._premiumOffer!.features.map((feature) =>
                                        _buildPremiumFeature(
                                            Icons.check_circle, feature)),
                                    const SizedBox(height: 12)
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bouton d'ajout au panier fixe en bas
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  top: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: product.inStock
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF0a543d),
                                  Color(0xFF0d6b4d),
                                  Color(0xFF0f7d59)
                                ],
                              )
                            : null,
                        color: product.inStock ? null : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: product.inStock
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF0a543d).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: product.inStock
                              ? () {
                                  cart.addItem(product);
                                  Navigator.pop(context); // Ferme la modal
                                  SnackBarHelper.showSuccess(
                                    context,
                                    '${product.nom} ajouté au panier',
                                    emoji: '🛒',
                                    action: SnackBarAction(
                                      label: 'Voir',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CartScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_shopping_cart,
                                  size: 24,
                                  color: product.inStock
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  product.inStock
                                      ? 'Ajouter au panier'
                                      : 'Produit indisponible',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: product.inStock
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0a543d), Color(0xFF0d6b4d)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.brown.shade700,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
