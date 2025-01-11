import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../constants/api_config.dart';

final postsProvider = FutureProvider((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.get(ApiConfig.postsEndpoint);
  return response.data as List<dynamic>;
});
