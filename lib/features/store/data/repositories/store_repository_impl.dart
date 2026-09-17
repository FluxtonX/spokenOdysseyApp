import '../../../../core/network/cache_manager.dart';
import '../datasources/store_remote_datasource.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/store_product_entity.dart';
import '../../domain/repositories/store_repository.dart';

class StoreRepositoryImpl implements StoreRepository {
  final StoreRemoteDataSource remoteDataSource;

  StoreRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<StoreProductEntity>> getProducts() async {
    const key = 'store_products';
    final cached = CacheManager().get<List<StoreProductEntity>>(key, ttl: const Duration(minutes: 10));
    if (cached != null) return cached;

    final products = await remoteDataSource.getProducts();
    CacheManager().set(key, products);
    return products;
  }

  @override
  Future<StoreProductEntity> getProductBySlug(String slug) async {
    return await remoteDataSource.getProductBySlug(slug);
  }

  @override
  Future<List<CartItemEntity>> getCart() async {
    return await remoteDataSource.getCart();
  }

  @override
  Future<List<CartItemEntity>> addToCart(String productId, int quantity) async {
    return await remoteDataSource.addToCart(productId, quantity);
  }

  @override
  Future<void> removeFromCart(String cartItemId) async {
    await remoteDataSource.removeFromCart(cartItemId);
  }

  @override
  Future<Map<String, dynamic>> checkout(
    Map<String, dynamic> orderPayload,
  ) async {
    return await remoteDataSource.checkout(orderPayload);
  }
}
