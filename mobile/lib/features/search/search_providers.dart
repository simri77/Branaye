import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/note.dart';
import '../../data/api/dio_provider.dart';
import '../../data/providers.dart' show authProvider;

/// Search parameters with copyWith for immutability
@immutable
class SearchParams {
  const SearchParams({
    this.q,
    this.category,
    this.tags = const [],
    this.page = 1,
    this.limit = 20,
    this.sort = 'createdAt:desc',
    this.searchIn = 'all',
  });

  final String? q;
  final String? category;
  final String searchIn;
  final List<String> tags;
  final int page;
  final int limit;
  final String sort;

  SearchParams copyWith({
    String? q,
    String? category,
    List<String>? tags,
    int? page,
    int? limit,
    String? sort,
    String? searchIn,
  }) {
    return SearchParams(
      q: q ?? this.q,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      sort: sort ?? this.sort,
      searchIn: searchIn ?? this.searchIn,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': sort,
    };
    if (q != null && q!.isNotEmpty) params['q'] = q;
    if (category != null) params['category'] = category;
    if (tags.isNotEmpty) params['tags'] = tags.join(',');
    if (searchIn != 'all') params['searchIn'] = searchIn;
    return params;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          runtimeType == other.runtimeType &&
          q == other.q &&
          category == other.category &&
          listEquals(tags, other.tags) &&
          page == other.page &&
          limit == other.limit &&
          sort == other.sort;

  @override
  int get hashCode =>
      q.hashCode ^
      category.hashCode ^
      tags.hashCode ^
      page.hashCode ^
      limit.hashCode ^
      sort.hashCode;
}

/// Pagination metadata from API
@immutable
class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

/// Paginated notes response from API
@immutable
class PaginatedNotes {
  const PaginatedNotes({required this.data, required this.meta});

  final List<Note> data;
  final PaginationMeta meta;

  bool get hasMore => meta.hasMore;

  SearchParams nextPageParams(SearchParams current) {
    if (!hasMore) return current;
    return current.copyWith(page: current.page + 1);
  }

  factory PaginatedNotes.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataJson = json['data'] as List<dynamic>;
    return PaginatedNotes(
      data: dataJson
          .map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

/// API exceptions with user-friendly messages
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException()
    : super('Session expired. Please log in again.', statusCode: 401);
}

class NotFoundException extends ApiException {
  const NotFoundException() : super('Not found', statusCode: 404);
}

class ServerException extends ApiException {
  const ServerException()
    : super('Server error. Please try again later.', statusCode: 500);
}

class NetworkException extends ApiException {
  const NetworkException()
    : super('Network error. Check your connection.', statusCode: 0);
}

/// ApiRepository interface for search
abstract class ApiRepository {
  Future<PaginatedNotes> searchNotes(SearchParams params);
  Future<List<Tag>> getTags();
  Future<List<Tag>> getTagSuggestions(String prefix, {int limit = 10});
  Future<List<Tag>> getPopularTags({int limit = 10});
}

/// Tag model for API
@immutable
class Tag {
  const Tag({
    required this.id,
    required this.name,
    this.color,
    required this.noteCount,
  });

  final String id;
  final String name;
  final String? color;
  final int noteCount;

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      noteCount: json['noteCount'] as int? ?? 0,
    );
  }
}

/// Dio implementation of ApiRepository
class DioApiRepository implements ApiRepository {
  DioApiRepository(this._dio);

  final Dio _dio;

  @override
  Future<PaginatedNotes> searchNotes(SearchParams params) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notes',
        queryParameters: params.toQueryParams(),
      );
      if (response.data == null) {
        throw const ServerException();
      }
      return PaginatedNotes.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<Tag>> getTags() async {
    try {
      final response = await _dio.get<List<dynamic>>('/tags');
      return (response.data ?? [])
          .map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<Tag>> getTagSuggestions(String prefix, {int limit = 10}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/tags/suggestions',
        queryParameters: {'q': prefix, 'limit': limit},
      );
      return (response.data ?? [])
          .map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<Tag>> getPopularTags({int limit = 10}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/tags/popular',
        queryParameters: {'limit': limit},
      );
      return (response.data ?? [])
          .map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 401) return const UnauthorizedException();
        if (status == 404) return const NotFoundException();
        if (status != null && status >= 500) return const ServerException();
        return ApiException('Request failed: ${e.message}', statusCode: status);
      case DioExceptionType.cancel:
        return ApiException('Request cancelled');
      case DioExceptionType.unknown:
        return const NetworkException();
      default:
        return ApiException('Unexpected error: ${e.message}');
    }
  }
}

/// ApiRepository provider — uses the app-wide authenticated Dio.
final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  return DioApiRepository(ref.watch(dioProvider));
});

/// SearchParamsNotifier with 300ms debounce (using new Notifier API)
class SearchParamsNotifier extends Notifier<SearchParams> {
  @override
  SearchParams build() {
    _debounceTimer?.cancel();
    ref.watch(authProvider.select((auth) => auth.user?.id));
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const SearchParams();
  }

  Timer? _debounceTimer;

  void updateQuery(String? q) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(q: q?.isNotEmpty == true ? q : null, page: 1);
    });
  }

  void updateCategory(String? category) {
    state = state.copyWith(category: category, page: 1);
  }

  void updateTags(List<String> tags) {
    state = state.copyWith(tags: tags, page: 1);
  }

  void updateSearchIn(String searchIn) {
    state = state.copyWith(searchIn: searchIn, page: 1);
  }

  void nextPage() {
    state = state.copyWith(page: state.page + 1);
  }

  void reset() {
    state = const SearchParams();
  }
}

/// Search params provider
final searchParamsProvider =
    NotifierProvider<SearchParamsNotifier, SearchParams>(
      SearchParamsNotifier.new,
    );

/// Search results provider with autoDispose + family for caching
final searchResultsProvider = FutureProvider.autoDispose
    .family<PaginatedNotes, SearchParams>((ref, params) async {
      final userId = ref.watch(authProvider.select((auth) => auth.user?.id));
      if (userId == null) {
        return PaginatedNotes(
          data: [],
          meta: PaginationMeta(
            page: 1,
            limit: params.limit,
            total: 0,
            totalPages: 0,
          ),
        );
      }

      // Don't search if query is empty and no filters
      if (params.q == null && params.category == null && params.tags.isEmpty) {
        return PaginatedNotes(
          data: [],
          meta: PaginationMeta(
            page: 1,
            limit: params.limit,
            total: 0,
            totalPages: 0,
          ),
        );
      }

      final repository = ref.watch(apiRepositoryProvider);
      return repository.searchNotes(params);
    });

/// All tags provider for editor picker
final allTagsProvider = FutureProvider.autoDispose<List<Tag>>((ref) async {
  final userId = ref.watch(authProvider.select((auth) => auth.user?.id));
  if (userId == null) return [];
  final repository = ref.watch(apiRepositoryProvider);
  return repository.getTags();
});

/// Tag suggestions provider for autocomplete
final tagSuggestionsProvider = FutureProvider.autoDispose
    .family<List<Tag>, String>((ref, prefix) async {
      final userId = ref.watch(authProvider.select((auth) => auth.user?.id));
      if (userId == null) return [];
      if (prefix.isEmpty) return [];
      final repository = ref.watch(apiRepositoryProvider);
      return repository.getTagSuggestions(prefix, limit: 10);
    });

/// Popular tags provider for tag cloud
final popularTagsProvider = FutureProvider.autoDispose<List<Tag>>((ref) async {
  final userId = ref.watch(authProvider.select((auth) => auth.user?.id));
  if (userId == null) return [];
  final repository = ref.watch(apiRepositoryProvider);
  return repository.getPopularTags(limit: 10);
});

/// Recent searches notifier with SharedPreferences persistence (new Notifier API)
class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    _load();
    return [];
  }

  static const _prefsKey = 'recent_searches';
  static const _maxItems = 10;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    state = list;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state);
  }

  void addSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    state = [
      trimmed,
      ...state.where((s) => s != trimmed),
    ].take(_maxItems).toList();
    _save();
  }

  void clearHistory() {
    state = [];
    _save();
  }
}

/// Recent searches provider
final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
      RecentSearchesNotifier.new,
    );
