import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/store_repository.dart';
import 'store_state.dart';

class StoreCubit extends Cubit<StoreState> {
  final StoreRepository repository;

  StoreCubit({required this.repository}) : super(const StoreInitial());

  Future<void> loadStoreCatalog() async {
    emit(const StoreLoading());
    try {
      final products = await repository.getProducts();
      List cart = [];
      try {
        cart = await repository.getCart();
      } catch (_) {}
      emit(StoreLoaded(products: products, cartItems: List.from(cart)));
    } catch (e) {
      emit(StoreError('Failed to load Odyssey Store catalog: ${e.toString()}'));
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    try {
      final updatedCart = await repository.addToCart(productId, quantity);
      if (state is StoreLoaded) {
        final currentProducts = (state as StoreLoaded).products;
        emit(StoreLoaded(products: currentProducts, cartItems: updatedCart));
      } else {
        loadStoreCatalog();
      }
    } catch (e) {
      emit(StoreError('Failed to add item to cart: ${e.toString()}'));
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      await repository.removeFromCart(cartItemId);
      if (state is StoreLoaded) {
        final currentProducts = (state as StoreLoaded).products;
        final updatedCart = (state as StoreLoaded).cartItems
            .where((item) => item.id != cartItemId)
            .toList();
        emit(StoreLoaded(products: currentProducts, cartItems: updatedCart));
      }
    } catch (e) {
      emit(StoreError('Failed to remove item from cart: ${e.toString()}'));
    }
  }
}
