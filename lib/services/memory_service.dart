import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/server_constants.dart';

class MemoryService {
  MemoryService()
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
  static List<Map<String, dynamic>>? _cachedMemories;
  static Future<List<Map<String, dynamic>>>? _inFlightMemories;
  static String? _cachedUid;

  Future<List<Map<String, dynamic>>> fetchMemories({
    bool forceRefresh = false,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Please sign in again to load memories.');
    }

    final uid = currentUser.uid;
    if (forceRefresh || _cachedUid != uid) {
      invalidateCache();
      _cachedUid = uid;
    }

    if (_cachedMemories != null) {
      return _cloneMemories(_cachedMemories!);
    }

    if (_inFlightMemories != null) {
      return _cloneMemories(await _inFlightMemories!);
    }

    _inFlightMemories = _fetchMemoriesFromNetwork();

    try {
      final memories = await _inFlightMemories!;
      _cachedMemories = memories;
      return _cloneMemories(memories);
    } finally {
      _inFlightMemories = null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMemoriesFromNetwork() async {
    try {
      final response = await _dio.get(
        '/api/memories',
        options: await _authorizedOptions(),
      );

      final data = response.data;
      final memories = data is Map<String, dynamic> && data['data'] is List
          ? data['data'] as List
          : const [];

      return memories
          .map((memory) => normalizeMemory(Map<String, dynamic>.from(memory)))
          .toList();
    } on DioException catch (error) {
      throw Exception(_extractMessage(error));
    }
  }

  Future<Map<String, dynamic>> createMemory({
    required String title,
    required String description,
    required List<String> tags,
    required String mood,
    required String privacy,
    required String type,
    required bool publish,
    required DateTime occurredAt,
    String? albumId,
    String? color,
    File? mediaFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'tags': jsonEncode(tags),
        'mood': mood,
        'privacy': privacy,
        'type': type,
        'status': publish ? 'published' : 'draft',
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        if (albumId != null && albumId.isNotEmpty) 'albumId': albumId,
        if (color != null && color.isNotEmpty) 'color': color,
        if (mediaFile != null)
          'media': await MultipartFile.fromFile(
            mediaFile.path,
            filename: Uri.file(mediaFile.path).pathSegments.last,
          ),
      });

      final response = await _dio.post(
        '/api/memories',
        data: formData,
        options: await _authorizedOptions(contentType: 'multipart/form-data'),
      );

      final data = response.data;
      if (data is! Map<String, dynamic> || data['data'] is! Map) {
        throw Exception(
          'Memory was saved but the server response was invalid.',
        );
      }

      final memory = normalizeMemory(
        Map<String, dynamic>.from(data['data'] as Map),
      );
      _mergeMemoryIntoCache(memory);
      return Map<String, dynamic>.from(memory);
    } on DioException catch (error) {
      throw Exception(_extractMessage(error));
    }
  }

  void invalidateCache() {
    _cachedMemories = null;
    _inFlightMemories = null;
  }

  Future<void> deleteMemory(String memoryId) async {
    try {
      await _dio.delete(
        '/api/memories/$memoryId',
        options: await _authorizedOptions(),
      );

      if (_cachedMemories != null) {
        _cachedMemories = _cachedMemories!
            .where((memory) => memory['id']?.toString() != memoryId)
            .map((memory) => Map<String, dynamic>.from(memory))
            .toList();
      }
    } on DioException catch (error) {
      throw Exception(_extractMessage(error));
    }
  }

  Future<Map<String, dynamic>> updateMemory({
    required String memoryId,
    required String title,
    required String description,
    String? color,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/memories/$memoryId',
        data: {
          'title': title,
          'description': description,
          if (color != null) 'color': color,
        },
        options: await _authorizedOptions(),
      );

      final data = response.data;
      if (data is! Map<String, dynamic> || data['data'] is! Map) {
        throw Exception('Memory was updated but the server response was invalid.');
      }

      final memory = normalizeMemory(
        Map<String, dynamic>.from(data['data'] as Map),
      );
      _mergeMemoryIntoCache(memory);
      return Map<String, dynamic>.from(memory);
    } on DioException catch (error) {
      throw Exception(_extractMessage(error));
    }
  }

  Future<Options> _authorizedOptions({String? contentType}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Please sign in again to continue.');
    }

    final token = await currentUser.getIdToken();

    return Options(
      contentType: contentType,
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  String _buildAbsoluteUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    
    String safePath = path;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      try {
        final uri = Uri.parse(path);
        if (uri.path.contains('/uploads/')) {
           safePath = uri.path;
        } else {
           return path;
        }
      } catch (e) {
        return path;
      }
    }
    
    final baseUrl = ServerConstants.baseUrl.replaceAll(RegExp(r'/$'), '');
    safePath = safePath.startsWith('/') ? safePath : '/$safePath';
    return '$baseUrl$safePath';
  }

  Map<String, dynamic> normalizeMemory(Map<String, dynamic> rawMemory) {
    final typeLabel = rawMemory['type']?.toString() ?? 'Text';
    final status = rawMemory['status']?.toString().toLowerCase() == 'published'
        ? 'published'
        : 'draft';
    final tags = rawMemory['tags'] is List
        ? List<String>.from(
            (rawMemory['tags'] as List).map((tag) => tag.toString()),
          )
        : <String>[];
    final occurredAt = DateTime.tryParse(rawMemory['date']?.toString() ?? '');
    final updatedAt = DateTime.tryParse(
      rawMemory['updatedAt']?.toString() ??
          rawMemory['createdAt']?.toString() ??
          '',
    );

    return {
      'id': rawMemory['id']?.toString() ?? rawMemory['_id']?.toString() ?? '',
      'title': rawMemory['title']?.toString() ?? '',
      'description': rawMemory['description']?.toString() ?? '',
      'color': rawMemory['color']?.toString() ?? '',
      'tags': tags,
      'category':
          rawMemory['category']?.toString() ??
          rawMemory['privacy']?.toString() ??
          'Private',
      'privacy': rawMemory['privacy']?.toString() ?? 'Private',
      'type': typeLabel,
      'mood': rawMemory['mood']?.toString() ?? '',
      'status': status,
      'albumId': rawMemory['albumId']?.toString(),
      'albumTitle': rawMemory['albumTitle']?.toString(),
      'date': occurredAt != null
          ? DateFormat('MMMM d, y').format(occurredAt)
          : '',
      'dateRaw': rawMemory['date']?.toString(),
      'updatedAtRaw':
          updatedAt?.toIso8601String() ??
          rawMemory['updatedAt']?.toString() ??
          rawMemory['createdAt']?.toString(),
      'updatedAtLabel': updatedAt != null
          ? DateFormat('MMM d, h:mm a').format(updatedAt)
          : '',
      'icon': _iconForType(typeLabel),
      'mediaUrl': _buildAbsoluteUrl(rawMemory['mediaUrl']?.toString()),
      'thumbnailUrl': _buildAbsoluteUrl(
        (rawMemory['thumbnailUrl']?.toString() != null &&
                rawMemory['thumbnailUrl']?.toString().isNotEmpty == true)
            ? rawMemory['thumbnailUrl']?.toString()
            : rawMemory['mediaUrl']?.toString(),
      ),
      'mediaKey': rawMemory['mediaKey']?.toString(),
      'mediaMimeType': rawMemory['mediaMimeType']?.toString(),
      'likes': rawMemory['likes'] is int
          ? rawMemory['likes']
          : int.tryParse('${rawMemory['likes'] ?? 0}') ?? 0,
      'comments': rawMemory['comments'] is int
          ? rawMemory['comments']
          : int.tryParse('${rawMemory['comments'] ?? 0}') ?? 0,
      'ownerDisplayName': rawMemory['ownerDisplayName']?.toString() ?? '',
      'ownerEmail': rawMemory['ownerEmail']?.toString() ?? '',
      'createdAt': rawMemory['createdAt']?.toString(),
      'updatedAt': rawMemory['updatedAt']?.toString(),
      'coverUploadWarning': rawMemory['mediaUploadWarning']?.toString(),
    };
  }

  void _mergeMemoryIntoCache(Map<String, dynamic> memory) {
    if (_cachedMemories == null) {
      return;
    }

    final memoryId = memory['id']?.toString();
    final updated = [
      Map<String, dynamic>.from(memory),
      ..._cachedMemories!
          .where((existing) => existing['id']?.toString() != memoryId)
          .map((existing) => Map<String, dynamic>.from(existing)),
    ];

    _cachedMemories = updated;
  }

  List<Map<String, dynamic>> _cloneMemories(
    List<Map<String, dynamic>> memories,
  ) {
    return memories.map((memory) => Map<String, dynamic>.from(memory)).toList();
  }

  IconData _iconForType(String typeLabel) {
    final normalized = typeLabel.toLowerCase();
    if (normalized.contains('voice')) return Icons.mic_none_rounded;
    if (normalized.contains('photo')) return Icons.collections_outlined;
    if (normalized.contains('video')) return Icons.videocam_outlined;
    return Icons.edit_note_rounded;
  }

  String _extractMessage(DioException error) {
    if (error.response?.statusCode == 413) {
      return 'Video file is too large for the current server upload limit. '
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
