import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod_http_cache_app/providers/api_provider.dart';
import 'package:flutter_riverpod_http_cache_app/providers/posts_provider.dart';
import 'package:flutter_riverpod_http_cache_app/services/api_service.dart';
import 'posts_provider_test.mocks.dart';
import 'package:flutter_riverpod_http_cache_app/constants/api_config.dart';

@GenerateMocks([Dio, Box])
void main() {
  late MockDio mockDio;
  late MockBox mockBox;
  late ApiService apiService;
  late ProviderContainer container;

  setUp(() {
    mockDio = MockDio();
    mockBox = MockBox();
    apiService =
        ApiService(mockDio, mockBox, cacheDuration: Duration(minutes: 10));

    // デフォルトのスタブを設定
    when(mockBox.get(any, defaultValue: null)).thenReturn(null);

    container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(mockDio),
        cacheBoxProvider.overrideWithValue(mockBox),
        apiServiceProvider.overrideWithValue(apiService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('postsProvider', () {
    final url = ApiConfig.postsEndpoint;
    final responseData = [
      {'id': 1, 'title': 'Test Post', 'body': 'This is a test.'}
    ];
    final timestamp = DateTime.now();

    test('fetches posts successfully from API', () async {
      when(mockBox.containsKey(url)).thenReturn(false);
      final mockResponse = Response(
        data: responseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: url),
      );
      when(mockDio.get(url)).thenAnswer((_) async => mockResponse);

      final asyncValue = await container.read(postsProvider.future);
      expect(asyncValue, responseData);
      verify(mockDio.get(url)).called(1);
    });

    test('fetches posts from cache if valid', () async {
      when(mockBox.containsKey(url)).thenReturn(true);
      when(mockBox.get(url))
          .thenReturn({'data': responseData, 'timestamp': timestamp});

      final asyncValue = await container.read(postsProvider.future);
      expect(asyncValue, responseData);
      verifyNever(mockDio.get(url));
    });

    test('handles API error and returns stale data if cache exists', () async {
      when(mockBox.containsKey(url)).thenReturn(true);
      when(mockBox.get(url, defaultValue: null))
          .thenReturn({'data': responseData, 'timestamp': timestamp});

      when(mockDio.get(url)).thenThrow(DioException(
        requestOptions: RequestOptions(path: url),
        type: DioExceptionType.unknown,
        error: 'Network Error',
      ));

      final asyncValue = await container.read(postsProvider.future);
      expect(asyncValue, responseData);
    });

    test('throws error if API fails and no cache exists', () async {
      when(mockBox.containsKey(url)).thenReturn(false);
      when(mockDio.get(url)).thenThrow(DioException(
        requestOptions: RequestOptions(path: url),
        type: DioExceptionType.unknown,
        error: 'Network Error',
      ));

      expect(
          container.read(postsProvider.future), throwsA(isA<DioException>()));
    });
  });
}
