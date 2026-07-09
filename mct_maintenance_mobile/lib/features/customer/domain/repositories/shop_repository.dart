abstract class ShopRepository {
  Future<Map<String, dynamic>> getProducts({String? category, String? search, int? brandId});
  Future<Map<String, dynamic>> getProductById(int id);
  Future<Map<String, dynamic>> getCategories();
  Future<Map<String, dynamic>> getCart();
  Future<Map<String, dynamic>> addToCart(int productId, int quantity);
  Future<Map<String, dynamic>> updateCartItem(int productId, int quantity);
  Future<Map<String, dynamic>> removeFromCart(int productId);
  Future<Map<String, dynamic>> clearCart();
  Future<Map<String, dynamic>> getOrders();
  Future<Map<String, dynamic>> getOrderDetails(int orderId);
  Future<List<int>> downloadInvoicePDF(int orderId);
  Future<Map<String, dynamic>> getBrands();
}
