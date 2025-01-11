import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

class ApiService {
  final Dio _dio;
  final Box _cacheBox;
  final Duration cacheDuration;

  ApiService(this._dio, this._cacheBox,
      {this.cacheDuration = const Duration(minutes: 10)});

  Future<Response> get(String url) async {
    final cacheEntry = _cacheBox.get(url);
    if (cacheEntry != null) {
      final cachedTime = cacheEntry['timestamp'] as DateTime;
      final currentTime = DateTime.now();
      if (currentTime.difference(cachedTime) < cacheDuration) {
        return Response(
          data: cacheEntry['data'],
          statusCode: 200,
          requestOptions: RequestOptions(path: url),
        );
      } else {
        // Cache expired, remove it
        _cacheBox.delete(url);
      }
    }

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        _cacheBox.put(url, {
          'data': response.data,
          'timestamp': DateTime.now(),
        });
      }
      return response;
    } catch (e) {
      // Handle different types of errors
      if (_cacheBox.containsKey(url)) {
        // Return stale data if available
        final staleData = _cacheBox.get(url)['data'];
        return Response(
          data: staleData,
          statusCode: 200,
          requestOptions: RequestOptions(path: url),
          statusMessage: 'Stale data due to error: $e',
        );
      } else {
        rethrow;
      }
    }
  }
}
