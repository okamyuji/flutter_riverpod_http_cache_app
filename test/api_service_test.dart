import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod_http_cache_app/services/api_service.dart';
import 'api_service_test.mocks.dart';
import 'package:flutter_riverpod_http_cache_app/constants/api_config.dart';

@GenerateMocks([Dio, Box])
void main() {
  late MockDio mockDio;
  late MockBox mockBox;
  late ApiService apiService;

  setUp(() {
    mockDio = MockDio();
    mockBox = MockBox();
    apiService =
        ApiService(mockDio, mockBox, cacheDuration: Duration(minutes: 10));

    // デフォルトのスタブを設定
    when(mockBox.get(any, defaultValue: null)).thenReturn(null);
  });

  group('ApiService', () {
    final url = ApiConfig.postsEndpoint;
    final responseData = [
      {'id': 1, 'title': 'Test Post', 'body': 'This is a test.'}
    ];
    final timestamp = DateTime.now();

    test('returns cached data if cache is valid', () async {
      when(mockBox.containsKey(url)).thenReturn(true);
      when(mockBox.get(url, defaultValue: null))
          .thenReturn({'data': responseData, 'timestamp': timestamp});

      final response = await apiService.get(url);
      expect(response.data, responseData);
      verifyNever(mockDio.get(url));
    });

    test('fetches from API and caches data if cache is expired', () async {
      final expiredTimestamp = timestamp.subtract(Duration(minutes: 15));
      when(mockBox.containsKey(url)).thenReturn(true);
      when(mockBox.get(url))
          .thenReturn({'data': responseData, 'timestamp': expiredTimestamp});

      final mockResponse = Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: url),
      );
      when(mockDio.get(url)).thenAnswer((_) async => mockResponse);

      final response = await apiService.get(url);
      expect(response.data, responseData);
      verify(mockDio.get(url)).called(1);
      verify(mockBox.put(url, any)).called(1);
    });

    test('fetches from API and caches data if no cache exists', () async {
      when(mockBox.containsKey(url)).thenReturn(false);
      final mockResponse = Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: url),
      );
      when(mockDio.get(url)).thenAnswer((_) async => mockResponse);

      final response = await apiService.get(url);
      expect(response.data, responseData);
      verify(mockDio.get(url)).called(1);
      verify(mockBox.put(url, any)).called(1);
    });

    test('returns stale data if API call fails and cache exists', () async {
      when(mockBox.containsKey(url)).thenReturn(true);
      when(mockBox.get(url, defaultValue: null))
          .thenReturn({'data': responseData, 'timestamp': timestamp});

      when(mockDio.get(url)).thenThrow(DioException(
        requestOptions: RequestOptions(path: url),
        type: DioExceptionType.unknown,
        error: 'Network Error',
      ));

      final response = await apiService.get(url);
      expect(response.data, responseData);
    });

    test('throws error if API call fails and no cache exists', () async {
      when(mockBox.containsKey(url)).thenReturn(false);
      when(mockDio.get(url)).thenThrow(DioException(
        requestOptions: RequestOptions(path: url),
        type: DioExceptionType.unknown,
        error: 'Network Error',
      ));

      expect(() => apiService.get(url), throwsA(isA<DioException>()));
    });
  });
}
