// lib/core/storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Storage {
  static const _s = FlutterSecureStorage();

  static Future<String?> read(String k) => _s.read(key: k);
  static Future<void> write(String k, String v) => _s.write(key: k, value: v);
  static Future<void> delete(String k) => _s.delete(key: k);
  static Future<void> clear() async {
    await _s.delete(key: 'access_token');
    await _s.delete(key: 'refresh_token');
  }
}