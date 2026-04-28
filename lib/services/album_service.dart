import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:spokenodyssey/services/memory_service.dart';

import '../config/server_constants.dart';

class AlbumService {
  AlbumService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ServerConstants.baseUrl,
          connectTimeout: ServerConstants.connectTimeout,
          receiveTimeout: ServerConstants.receiveTimeout,
          sendTimeout: ServerConstants.sendTimeout,
        ),
      ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }

  final Dio _dio;
  static List<Map<String, dynamic>>? _cachedAlbums;
  static Future<List<Map<String, dynamic>>>? _inFlightAlbums;
  static String? _cachedUid;

  Future<List<Map<String, dynamic>>> fetchAlbums({
    bool forceRefresh = false,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Please sign in again to manage albums.');
    }

    final uid = currentUser.uid;
    if (forceRefresh || _cachedUid != uid) {
      invalidateCache();
      _cachedUid = uid;
    }

    if (_cachedAlbums != null) {
      return _cloneAlbums(_cachedAlbums!);
    }

    if (_inFlightAlbums != null) {
      return _cloneAlbums(await _inFlightAlbums!);
    }

    _inFlightAlbums = _fetchAlbumsFromNetwork();

    try {
      final albums = await _inFlightAlbums!;
      _cachedAlbums = albums;
      return _cloneAlbums(albums);
    } finally {
      _inFlightAlbums = null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAlbumsFromNetwork() async {
    try {
      final response = await _dio.get(
        '/api/albums',
        options: await _authorizedOptions(),
      );

      final data = response.data;
      final albums = data is Map<String, dynamic> && data['data'] is List
          ? data['data'] as List
          : const [];

      return albums
          .map((album) => _normalizeAlbum(Map<String, dynamic>.from(album)))
          .toList();
    } on DioException catch (error) {
      throw Exception(_extractMessage(error));
    }
  }

  Future<Map<String, dynamic>> createAlbum({
    required String title,
    required String subtitle,
    File? coverImage,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'subtitle': subtitle,
        if (coverImage != null)
          'coverImage': await MultipartFile.fromFile(
            coverImage.path,
            filename: Uri.file(coverImage.path).pathSegments.last,
          ),
      });

      final response = await _dio.post(
        '/api/albums',
        data: formData,
        options: await _authorizedOptions(contentType: 'multipart/form-data'),
      );

      final data = response.data;
      if (data is! Map<String, dynamic> || data['data'] is! Map) {
        throw Exception('Album was created but server response was invalid.');
      }

      final album = _normalizeAlbum(
        Map<String, dynamic>.from(data['data'] as Map),
      );
      _mergeAlbumIntoCache(album);
      return Map<String, dynamic>.from(album);
    } on DioException catch (error) {
      throw Exception(_extractMessage(error));
    }
  }

  void invalidateCache() {
    _cachedAlbums = null;
    _inFlightAlbums = null;
  }

  Future<Options> _authorizedOptions({String? contentType}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Please sign in again to manage albums.');
    }

    final token = await currentUser.getIdToken();

    return Options(
      contentType: contentType,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Map<String, dynamic> _normalizeAlbum(Map<String, dynamic> rawAlbum) {
    final rawMemories = rawAlbum['memories'];
    final memoryService = MemoryService();

    return {
      'id': rawAlbum['id']?.toString() ?? rawAlbum['_id']?.toString() ?? '',
      'title': rawAlbum['title']?.toString() ?? '',
      'subtitle': rawAlbum['subtitle']?.toString() ?? '',
      'entries': rawAlbum['entries'] is int
          ? rawAlbum['entries']
          : int.tryParse('${rawAlbum['entries'] ?? 0}') ?? 0,
      'coverImageUrl': rawAlbum['coverImageUrl']?.toString(),
      'coverImageKey': rawAlbum['coverImageKey']?.toString(),
      'ownerDisplayName': rawAlbum['ownerDisplayName']?.toString() ?? '',
      'ownerEmail': rawAlbum['ownerEmail']?.toString() ?? '',
      'memories': rawMemories is List
          ? rawMemories
                .map(
                  (memory) => memory is Map
                      ? memoryService.normalizeMemory(
                          Map<String, dynamic>.from(memory),
                        )
                      : <String, dynamic>{},
                )
                .where((memory) => memory.isNotEmpty)
                .toList()
          : <Map<String, dynamic>>[],
      'createdAt': rawAlbum['createdAt']?.toString(),
      'updatedAt': rawAlbum['updatedAt']?.toString(),
      'isLocalOnly': false,
      'storageMode': 'cloud',
      'storageLabel': 'Cloud synced',
    };
  }

  void _mergeAlbumIntoCache(Map<String, dynamic> album) {
    if (_cachedAlbums == null) {
      return;
    }

    final albumId = album['id']?.toString();
    final updated = [
      Map<String, dynamic>.from(album),
      ..._cachedAlbums!
          .where((existing) => existing['id']?.toString() != albumId)
          .map((existing) => Map<String, dynamic>.from(existing)),
    ];

    _cachedAlbums = updated;
  }

  List<Map<String, dynamic>> _cloneAlbums(List<Map<String, dynamic>> albums) {
    return albums.map((album) => Map<String, dynamic>.from(album)).toList();
  }

  String _extractMessage(DioException error) {
    if (error.response?.statusCode == 413) {
      return 'File is too large for the current server upload limit. '
          'Increase the server body-size limit or try a smaller file.';
    }

    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final message = responseData['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }

    return 'Something went wrong while talking to the server.';
  }
}
