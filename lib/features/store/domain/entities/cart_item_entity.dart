import 'store_product_entity.dart';

class CartItemEntity {
  final String id;
  final StoreProductEntity product;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const CartItemEntity({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}
