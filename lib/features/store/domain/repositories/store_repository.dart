import '../entities/cart_item_entity.dart';
import '../entities/store_product_entity.dart';

abstract class StoreRepository {
  Future<List<StoreProductEntity>> getProducts();
  Future<StoreProductEntity> getProductBySlug(String slug);
  Future<List<CartItemEntity>> getCart();
  Future<List<CartItemEntity>> addToCart(String productId, int quantity);
  Future<void> removeFromCart(String cartItemId);
  Future<Map<String, dynamic>> checkout(Map<String, dynamic> orderPayload);
}
