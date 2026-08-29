// lib/features/auth/auth_repository.dart
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/storage.dart';
import '../../core/db.dart';

class AuthRepository {
  final _dio = ApiClient.instance.dio;

  Future<void> signin(String email, String password) async {
    final r = await _dio.post('/v1/users/signin',
        data: {'email': email, 'password': password});
    await _persist(r.data);
  }

  Future<void> signup(String email, String password, String username) async {
    final r = await _dio.post('/v1/users/signup',
        data: {'email': email, 'password': password, 'username': username});
    if (r.data['access_token'] != null) await _persist(r.data);
  }

  Future<void> _persist(Map<String, dynamic> data) async {
    await Storage.write('access_token', data['access_token']);
    if (data['refresh_token'] != null) {
      await Storage.write('refresh_token', data['refresh_token']);
    }
    await sb.auth.setSession(data['refresh_token']);
  }

  /// Validates the stored session against /me.
  Future<bool> hasValidSession() async {
    if (await Storage.read('access_token') == null) return false;
    try {
      await _dio.get('/v1/users/me');
      return true;
    } on DioException {
      return false;
    }
  }

  Future<void> signout() => Storage.clear();
}