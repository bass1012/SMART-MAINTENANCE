class QuoteItem {
  final int? id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double taxRate;
  final bool isCustom;

  QuoteItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    this.taxRate = 20.0,
    this.isCustom = false,
  });

  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * (discount / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (taxRate / 100);
  double get total => taxableAmount + taxAmount;

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'],
      productId: json['productId'] ?? json['product_id'] ?? -1,
      productName: json['productName'] ?? json['product_name'] ?? json['product']?['nom'] ?? 'Article',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? json['unit_price'] ?? 0.0).toDouble(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      taxRate: (json['taxRate'] ?? json['tax_rate'] ?? 20.0).toDouble(),
      isCustom: json['isCustom'] ?? json['is_custom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
      'taxRate': taxRate,
      'isCustom': isCustom,
    };
  }
}
