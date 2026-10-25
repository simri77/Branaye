import 'package:dio/dio.dart';

class BackupRepository {
  BackupRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> restore(Map<String, dynamic> backup) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/backups/restore',
      data: backup,
    );
    return response.data!;
  }
}
