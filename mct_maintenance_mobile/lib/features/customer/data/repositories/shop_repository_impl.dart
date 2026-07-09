import 'dart:convert';
import 'package:mct_maintenance_mobile/core/network/base_api_service.dart';
import 'package:mct_maintenance_mobile/features/customer/domain/repositories/shop_repository.dart';

class ShopRepositoryImpl implements ShopRepository {
  final BaseApiService _apiService;

  ShopRepositoryImpl(this._apiService);

  @override
  Future<Map<String, dynamic>> getProducts({String? category, String? search, int? brandId}) async {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    if (brandId != null) queryParams['brand_id'] = brandId.toString();
    
    final response = await _apiService.get('/api/products', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getProductById(int id) async {
    final response = await _apiService.get('/api/products/$id');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getCategories() async {
    final response = await _apiService.get('/api/categories');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getCart() async {
    final response = await _apiService.get('/api/cart');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> addToCart(int productId, int quantity) async {
    final response = await _apiService.post('/api/cart', body: {
      'product_id': productId,
      'quantity': quantity,
    });
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> updateCartItem(int productId, int quantity) async {
    final response = await _apiService.put('/api/cart/$productId', body: {
      'quantity': quantity,
    });
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> removeFromCart(int productId) async {
    final response = await _apiService.delete('/api/cart/$productId');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> clearCart() async {
    final response = await _apiService.delete('/api/cart');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getOrders() async {
    final response = await _apiService.get('/api/orders');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final response = await _apiService.get('/api/orders/$orderId');
    return jsonDecode(response.body);
  }

  @override
  Future<List<int>> downloadInvoicePDF(int orderId) async {
    final bytes = await _apiService.getBytes('/api/orders/$orderId/invoice');
    return bytes;
  }

  @override
  Future<Map<String, dynamic>> getBrands() async {
    final response = await _apiService.get('/api/brands');
    return jsonDecode(response.body);
  }
}
