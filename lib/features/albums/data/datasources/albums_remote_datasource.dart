import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/album_model.dart';

abstract class AlbumsRemoteDataSource {
  Future<List<AlbumModel>> getAlbums();
  Future<AlbumModel> getAlbumDetails(String albumId);
  Future<AlbumModel> createAlbum({
    required String title,
    String? description,
    String? coverPhotoPath,
  });
  Future<AlbumModel> updateAlbum({
    required String albumId,
    String? title,
    String? description,
    String? coverPhotoPath,
  });
  Future<void> deleteAlbum(String albumId);
}

class AlbumsRemoteDataSourceImpl implements AlbumsRemoteDataSource {
  final ApiClient apiClient;

  AlbumsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AlbumModel>> getAlbums() async {
    final response = await apiClient.get(ApiEndpoints.albums);
    final data = response.data['data'] ?? response.data;
    if (data is List) {
      return data.map((json) => AlbumModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<AlbumModel> getAlbumDetails(String albumId) async {
    final response = await apiClient.get(ApiEndpoints.albumById(albumId));
    final data = response.data['data'] ?? response.data;
    return AlbumModel.fromJson(data);
  }

  @override
  Future<AlbumModel> createAlbum({
    required String title,
    String? description,
    String? coverPhotoPath,
  }) async {
    final formDataMap = <String, dynamic>{
      'title': title,
      if (description != null && description.isNotEmpty)
        'description': description,
      'privacy': 'Private',
    };

    if (coverPhotoPath != null && coverPhotoPath.isNotEmpty) {
      final fileName = coverPhotoPath.split('/').last;
      formDataMap['coverImage'] = await MultipartFile.fromFile(
        coverPhotoPath,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap(formDataMap);
    final response = await apiClient.post(ApiEndpoints.albums, data: formData);

    final data = response.data['data'] ?? response.data;
    return AlbumModel.fromJson(data);
  }

  @override
  Future<AlbumModel> updateAlbum({
    required String albumId,
    String? title,
    String? description,
    String? coverPhotoPath,
  }) async {
    final formDataMap = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
    };

    if (coverPhotoPath != null && coverPhotoPath.isNotEmpty) {
      final fileName = coverPhotoPath.split('/').last;
      formDataMap['coverImage'] = await MultipartFile.fromFile(
        coverPhotoPath,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap(formDataMap);
    final response = await apiClient.patch(
      ApiEndpoints.albumById(albumId),
      data: formData,
    );

    final data = response.data['data'] ?? response.data;
    return AlbumModel.fromJson(data);
  }

  @override
  Future<void> deleteAlbum(String albumId) async {
    await apiClient.delete(ApiEndpoints.albumById(albumId));
  }
}
