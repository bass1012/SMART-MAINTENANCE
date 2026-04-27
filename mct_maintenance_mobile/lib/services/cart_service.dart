import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../config/environment.dart';

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];
  static const String _cartKey = 'shopping_cart';
  bool _isLoaded = false;

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);

  // Corriger l'URL de l'image si elle contient localhost
  String _fixImageUrl(String? imageUrl) {
    if (imageUrl == null) return '';

    // Si l'URL contient localhost, la remplacer par la vraie base URL
    if (imageUrl.contains('localhost:3000')) {
      // Extraire le chemin (ex: /uploads/products/...)
      final uri = Uri.parse(imageUrl);
      final path = uri.path;
      return '${AppConfig.baseUrl}$path';
    }

    return imageUrl;
  }

  // Charger le panier depuis SharedPreferences
  Future<void> loadCart() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString(_cartKey);

      if (cartData != null) {
        final List<dynamic> decoded = jsonDecode(cartData);
        _items.clear();

        // Charger les items et corriger les URLs d'images
        for (var itemJson in decoded) {
          final cartItem = CartItem.fromJson(itemJson);

          // Corriger l'URL de l'image du produit
          if (cartItem.product.imageUrl != null) {
            final fixedUrl = _fixImageUrl(cartItem.product.imageUrl);
            // Créer un nouveau ProductModel avec l'URL corrigée
            final fixedProduct = ProductModel(
              id: cartItem.product.id,
              sku: cartItem.product.sku,
              nom: cartItem.product.nom,
              description: cartItem.product.description,
              prix: cartItem.product.prix,
              quantiteStock: cartItem.product.quantiteStock,
              imageUrl: fixedUrl,
              categorieId: cartItem.product.categorieId,
              marqueId: cartItem.product.marqueId,
              actif: cartItem.product.actif,
              specifications: cartItem.product.specifications,
              createdAt: cartItem.product.createdAt,
              updatedAt: cartItem.product.updatedAt,
            );

            _items.add(CartItem(
              product: fixedProduct,
              quantity: cartItem.quantity,
            ));
          } else {
            _items.add(cartItem);
          }
        }

        // Sauvegarder le panier avec les URLs corrigées
        await _saveCart();
        notifyListeners();
      }

      _isLoaded = true;
    } catch (e) {
      debugPrint('Erreur lors du chargement du panier: $e');
    }
  }

  // Sauvegarder le panier dans SharedPreferences
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartData);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du panier: $e');
    }
  }

  // Ajouter un produit au panier
  void addItem(ProductModel product, {int quantity = 1}) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }

    unawaited(_saveCart());
    notifyListeners();
  }

  // Retirer un produit du panier
  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    unawaited(_saveCart());
    notifyListeners();
  }

  // Augmenter la quantité
  void increaseQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity++;
      unawaited(_saveCart());
      notifyListeners();
    }
  }

  // Diminuer la quantité
  void decreaseQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      unawaited(_saveCart());
      notifyListeners();
    }
  }

  // Vider le panier
  void clear() {
    _items.clear();
    unawaited(_saveCart());
    notifyListeners();
  }

  // Vérifier si un produit est dans le panier
  bool isInCart(int productId) {
    return _items.any((item) => item.product.id == productId);
  }

  // Obtenir la quantité d'un produit dans le panier
  int getQuantity(int productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () =>
          CartItem(product: ProductModel(id: 0, sku: '', nom: '', prix: 0)),
    );
    return item.product.id != 0 ? item.quantity : 0;
  }
}
