import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod_http_cache_app/providers/api_provider.dart';
import 'package:flutter_riverpod_http_cache_app/app.dart';
import 'posts_list_widget_test.mocks.dart';
import 'package:flutter_riverpod_http_cache_app/constants/api_config.dart';
import 'package:flutter_riverpod_http_cache_app/constants/strings.dart';

@GenerateMocks([Dio, Box])
void main() {
  late MockDio mockDio;
  late MockBox mockBox;

  setUp(() {
    mockDio = MockDio();
    mockBox = MockBox();

    // デフォルトのスタブを設定
    when(mockBox.get(any, defaultValue: null)).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(mockDio),
        cacheBoxProvider.overrideWithValue(mockBox),
      ],
      child: MyApp(),
    );
  }

  testWidgets('Displays posts when data is loaded',
      (WidgetTester tester) async {
    final url = '/posts';
    final responseData = [
      {'id': 1, 'title': 'Test Post', 'body': 'This is a test.'}
    ];

    when(mockBox.containsKey(url)).thenReturn(false);
    final mockResponse = Response(
      data: responseData,
      statusCode: 200,
      requestOptions: RequestOptions(path: url),
    );
    when(mockDio.get(url)).thenAnswer((_) async => mockResponse);

    await tester.pumpWidget(createWidgetUnderTest());

    // ローディング状態を確認
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 非同期処理の完了を待つ
    await tester.pump();
    await tester.pump(Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Test Post'), findsOneWidget);
    expect(find.text('This is a test.'), findsOneWidget);
  });

  testWidgets('Displays cached posts when available',
      (WidgetTester tester) async {
    final url = '/posts';
    final responseData = [
      {'id': 1, 'title': 'Cached Post', 'body': 'This is cached data.'}
    ];
    final timestamp = DateTime.now();

    when(mockBox.containsKey(url)).thenReturn(true);
    when(mockBox.get(url))
        .thenReturn({'data': responseData, 'timestamp': timestamp});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Cached Post'), findsOneWidget);
    expect(find.text('This is cached data.'), findsOneWidget);
    verifyNever(mockDio.get(url));
  });

  testWidgets('Displays error when API fails and no cache exists',
      (WidgetTester tester) async {
    final url = ApiConfig.postsEndpoint;

    when(mockBox.containsKey(url)).thenReturn(false);
    when(mockDio.get(url)).thenThrow(DioException(
      requestOptions: RequestOptions(path: url),
      type: DioExceptionType.unknown,
      error: 'Network Error',
    ));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining(Strings.genericErrorPrefix), findsOneWidget);
  });
}
