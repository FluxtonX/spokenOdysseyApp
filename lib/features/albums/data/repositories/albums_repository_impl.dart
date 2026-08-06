import '../../domain/entities/album_entity.dart';
import '../../domain/repositories/albums_repository.dart';
import '../datasources/albums_remote_datasource.dart';

class AlbumsRepositoryImpl implements AlbumsRepository {
  final AlbumsRemoteDataSource remoteDataSource;

  AlbumsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AlbumEntity>> getAlbums() async {
    return await remoteDataSource.getAlbums();
  }

  @override
  Future<AlbumEntity> getAlbumDetails(String albumId) async {
    return await remoteDataSource.getAlbumDetails(albumId);
  }

  @override
  Future<AlbumEntity> createAlbum({
    required String title,
    String? description,
    String? coverPhotoPath,
  }) async {
    return await remoteDataSource.createAlbum(
      title: title,
      description: description,
      coverPhotoPath: coverPhotoPath,
    );
  }

  @override
  Future<AlbumEntity> updateAlbum({
    required String albumId,
    String? title,
    String? description,
    String? coverPhotoPath,
  }) async {
    return await remoteDataSource.updateAlbum(
      albumId: albumId,
      title: title,
      description: description,
      coverPhotoPath: coverPhotoPath,
    );
  }

  @override
  Future<void> deleteAlbum(String albumId) async {
    await remoteDataSource.deleteAlbum(albumId);
  }
}
