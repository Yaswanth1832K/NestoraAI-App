import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:house_rental/core/network/api_client.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return client;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(httpClientProvider));
});
