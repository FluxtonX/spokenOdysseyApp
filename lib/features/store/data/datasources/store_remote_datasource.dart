import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/cart_item_model.dart';
import '../models/store_product_model.dart';

abstract class StoreRemoteDataSource {
  Future<List<StoreProductModel>> getProducts();
  Future<StoreProductModel> getProductBySlug(String slug);
  Future<List<CartItemModel>> getCart();
  Future<List<CartItemModel>> addToCart(String productId, int quantity);
  Future<void> removeFromCart(String cartItemId);
  Future<Map<String, dynamic>> checkout(Map<String, dynamic> orderPayload);
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  final ApiClient apiClient;

  StoreRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<StoreProductModel>> getProducts() async {
    final response = await apiClient.get(ApiEndpoints.storeProducts);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => StoreProductModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<StoreProductModel> getProductBySlug(String slug) async {
    final response = await apiClient.get(ApiEndpoints.storeProductBySlug(slug));
    final data = response.data['data'] ?? response.data;
    return StoreProductModel.fromJson(data);
  }

  @override
  Future<List<CartItemModel>> getCart() async {
    final response = await apiClient.get(ApiEndpoints.storeCart);
    final data = response.data['data'] ?? response.data;
    final items = data is Map ? data['items'] : data;
    if (items is List) {
      return items.map((json) => CartItemModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<List<CartItemModel>> addToCart(String productId, int quantity) async {
    final response = await apiClient.post(
      ApiEndpoints.storeCartItems,
      data: {'productId': productId, 'quantity': quantity},
    );
    final data = response.data['data'] ?? response.data;
    final items = data is Map ? data['items'] : data;
    if (items is List) {
      return items.map((json) => CartItemModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> removeFromCart(String cartItemId) async {
    await apiClient.delete(ApiEndpoints.storeCartItemById(cartItemId));
  }

  @override
  Future<Map<String, dynamic>> checkout(
    Map<String, dynamic> orderPayload,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.storeOrders,
      data: orderPayload,
    );
    return response.data;
  }
}
