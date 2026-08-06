import '../entities/album_entity.dart';

abstract class AlbumsRepository {
  Future<List<AlbumEntity>> getAlbums();
  Future<AlbumEntity> getAlbumDetails(String albumId);
  Future<AlbumEntity> createAlbum({
    required String title,
    String? description,
    String? coverPhotoPath,
  });
  Future<AlbumEntity> updateAlbum({
    required String albumId,
    String? title,
    String? description,
    String? coverPhotoPath,
  });
  Future<void> deleteAlbum(String albumId);
}
