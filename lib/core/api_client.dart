// lib/core/api_client.dart
import 'package:dio/dio.dart';
import 'config.dart';
import 'storage.dart';

class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  late final Dio dio = _build();

  Dio _build() {
    final d = Dio(BaseOptions(
      baseUrl: AppConfig.coreApiUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    d.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await Storage.read('access_token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        final isRefreshCall = e.requestOptions.path.contains('/refresh');
        if (e.response?.statusCode == 401 && !isRefreshCall) {
          if (await _refresh()) {
            final token = await Storage.read('access_token');
            e.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              return handler.resolve(await d.fetch(e.requestOptions));
            } catch (_) {}
          }
          await Storage.clear();
        }
        handler.next(e);
      },
    ));
    return d;
  }

  Future<bool> _refresh() async {
    final refresh = await Storage.read('refresh_token');
    if (refresh == null) return false;
    try {
      final r = await Dio().post(
        '${AppConfig.coreApiUrl}/v1/users/refresh',
        data: {'refresh_token': refresh},
      );
      await Storage.write('access_token', r.data['access_token']);
      await Storage.write('refresh_token', r.data['refresh_token']);
      return true;
    } catch (_) {
      return false;
    }
  }
}