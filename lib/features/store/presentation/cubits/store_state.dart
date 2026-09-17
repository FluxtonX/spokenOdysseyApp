import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/store_product_entity.dart';

abstract class StoreState {
  const StoreState();
}

class StoreInitial extends StoreState {
  const StoreInitial();
}

class StoreLoading extends StoreState {
  const StoreLoading();
}

class StoreLoaded extends StoreState {
  final List<StoreProductEntity> products;
  final List<CartItemEntity> cartItems;
  const StoreLoaded({required this.products, required this.cartItems});
}

class StoreError extends StoreState {
  final String message;
  const StoreError(this.message);
}
