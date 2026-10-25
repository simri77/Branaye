import 'package:dio/dio.dart';

import '../../core/models/category.dart';

class CategoriesRepository {
  CategoriesRepository(this._dio);

  final Dio _dio;

  Future<List<CategoryItem>> list() async {
    final response = await _dio.get<List<dynamic>>('/categories');
    return (response.data ?? const [])
        .map((item) => CategoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryItem> create(String name, int iconCodePoint) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/categories',
      data: {'name': name, 'iconCodePoint': iconCodePoint},
    );
    return CategoryItem.fromJson(response.data!);
  }
}
