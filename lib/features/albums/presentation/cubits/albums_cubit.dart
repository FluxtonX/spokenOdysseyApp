import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/album_entity.dart';
import '../../domain/repositories/albums_repository.dart';

abstract class AlbumsState {}

class AlbumsInitial extends AlbumsState {}
class AlbumsLoading extends AlbumsState {}
class AlbumsLoaded extends AlbumsState {
  final List<AlbumEntity> albums;
  AlbumsLoaded(this.albums);
}
class AlbumsError extends AlbumsState {
  final String message;
  AlbumsError(this.message);
}

class AlbumsCubit extends Cubit<AlbumsState> {
  final AlbumsRepository repository;

  AlbumsCubit({required this.repository}) : super(AlbumsInitial());

  Future<void> loadAlbums() async {
    try {
      emit(AlbumsLoading());
      final albums = await repository.getAlbums();
      emit(AlbumsLoaded(albums));
    } catch (e) {
      emit(AlbumsError(e.toString()));
    }
  }

  Future<bool> createAlbum({
    required String title,
    String? description,
    String? coverPhotoPath,
  }) async {
    try {
      await repository.createAlbum(
        title: title,
        description: description,
        coverPhotoPath: coverPhotoPath,
      );
      await loadAlbums();
      return true;
    } catch (e) {
      emit(AlbumsError(e.toString()));
      return false;
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    try {
      await repository.deleteAlbum(albumId);
      await loadAlbums();
    } catch (e) {
      emit(AlbumsError(e.toString()));
    }
  }
}
