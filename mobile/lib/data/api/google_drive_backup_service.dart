import 'dart:convert';

import 'package:dio/dio.dart';

class GoogleDriveBackupService {
  GoogleDriveBackupService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://www.googleapis.com/drive/v3',
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      ),
      _uploadDio = Dio(
        BaseOptions(
          baseUrl: 'https://www.googleapis.com/upload/drive/v3',
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          followRedirects: false,
        ),
      );

  static const _fileName = 'Branaye-backup.json';
  final Dio _dio;
  final Dio _uploadDio;

  Future<String> uploadBackup({
    required String accessToken,
    required String accountId,
    required Map<String, dynamic> backup,
  }) async {
    final headers = {'Authorization': 'Bearer $accessToken'};
    final existing = await _dio.get<Map<String, dynamic>>(
      '/files',
      queryParameters: {
        'q':
            "name='$_fileName' and appProperties has { key='branayeUserId' and value='$accountId' } and trashed=false",
        'pageSize': 1,
        'orderBy': 'modifiedTime desc',
        'fields': 'files(id)',
        'spaces': 'drive',
      },
      options: Options(headers: headers),
    );
    final files = existing.data?['files'] as List<dynamic>? ?? const [];
    final payload = jsonEncode(backup);
    final fileId = files.isEmpty
        ? null
        : (files.first as Map<String, dynamic>)['id'] as String?;
    if (files.isNotEmpty && (fileId == null || fileId.isEmpty)) {
      throw StateError('Google Drive returned a backup without a file ID.');
    }
    final uploadBytes = utf8.encode(payload);
    final metadata = {
      'name': _fileName,
      'mimeType': 'application/json',
      'description': 'Full Branaye notes, tags, and categories backup',
      'appProperties': {'branayeUserId': accountId},
    };
    final initiated = await _uploadDio.request<void>(
      fileId == null ? '/files' : '/files/$fileId',
      data: metadata,
      queryParameters: {'uploadType': 'resumable'},
      options: Options(
        method: fileId == null ? 'POST' : 'PATCH',
        headers: {
          ...headers,
          'X-Upload-Content-Type': 'application/json',
          'X-Upload-Content-Length': '${uploadBytes.length}',
        },
        contentType: 'application/json; charset=UTF-8',
      ),
    );
    final uploadUrl = initiated.headers.value('location');
    final uri = uploadUrl == null ? null : Uri.tryParse(uploadUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'www.googleapis.com' ||
        !uri.path.startsWith('/upload/drive/v3/files')) {
      throw StateError('Google Drive returned an invalid upload session URL.');
    }
    final uploaded = await _uploadDio.put<Map<String, dynamic>>(
      uri.toString(),
      data: payload,
      options: Options(
        headers: {
          ...headers,
          Headers.contentLengthHeader: '${uploadBytes.length}',
        },
        contentType: 'application/json; charset=UTF-8',
      ),
    );
    final uploadedFileId = fileId ?? uploaded.data?['id'] as String?;
    if (uploadedFileId == null || uploadedFileId.isEmpty) {
      throw StateError('Google Drive created a backup without a file ID.');
    }
    return uploadedFileId;
  }

  Future<Map<String, dynamic>> downloadBackup({
    required String accessToken,
    required String accountId,
  }) async {
    final headers = {'Authorization': 'Bearer $accessToken'};
    final response = await _dio.get<Map<String, dynamic>>(
      '/files',
      queryParameters: {
        'q':
            "name='$_fileName' and appProperties has { key='branayeUserId' and value='$accountId' } and trashed=false",
        'pageSize': 1,
        'orderBy': 'modifiedTime desc',
        'fields': 'files(id,name,modifiedTime)',
        'spaces': 'drive',
      },
      options: Options(headers: headers),
    );
    final files = response.data?['files'] as List<dynamic>? ?? const [];
    if (files.isEmpty) {
      throw StateError(
        'No Branaye backup was found in this Google Drive account.',
      );
    }
    final fileId = (files.first as Map<String, dynamic>)['id'] as String?;
    if (fileId == null || fileId.isEmpty) {
      throw StateError('Google Drive returned a backup without a file ID.');
    }

    final download = await _dio.get<Map<String, dynamic>>(
      '/files/$fileId',
      queryParameters: {'alt': 'media'},
      options: Options(headers: headers, responseType: ResponseType.json),
    );
    final backup = download.data;
    if (backup == null ||
        backup['format'] != 'branaye-backup' ||
        backup['version'] != 1 ||
        backup['notes'] is! List ||
        backup['categories'] is! List ||
        backup['tags'] is! List ||
        backup['createdAt'] is! String) {
      throw FormatException(
        'The Drive file is not a supported Branaye backup.',
      );
    }
    return backup;
  }
}
