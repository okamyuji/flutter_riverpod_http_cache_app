import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../services/api_service.dart';

// Dioのプロバイダー
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
});

// Hiveのキャッシュボックスプロバイダー
final cacheBoxProvider = Provider<Box>((ref) {
  return Hive.box('httpCache');
});

// ApiServiceのプロバイダー
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  final cacheBox = ref.watch(cacheBoxProvider);
  return ApiService(dio, cacheBox);
});
