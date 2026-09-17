import '../../domain/entities/cart_item_entity.dart';
import 'store_product_model.dart';

class CartItemModel extends CartItemEntity {
  const CartItemModel({
    required super.id,
    required super.product,
    required super.quantity,
    required super.unitPrice,
    required super.totalPrice,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] is Map<String, dynamic>
        ? json['product']
        : <String, dynamic>{'id': json['productId'] ?? ''};
    final product = StoreProductModel.fromJson(productJson);
    final qty = json['quantity'] as int? ?? 1;
    final uPrice = (json['unitPrice'] as num?)?.toDouble() ?? product.basePrice;

    return CartItemModel(
      id: json['id'] as String? ?? '',
      product: product,
      quantity: qty,
      unitPrice: uPrice,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? (qty * uPrice),
    );
  }
}
