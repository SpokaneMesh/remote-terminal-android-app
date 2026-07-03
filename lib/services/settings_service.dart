import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  static const _storage = FlutterSecureStorage();

  static const _keyUrl = 'server_url';
  static const _keyUsername = 'username';
  static const _keyPassword = 'password';

  static Future<Map<String, String?>> load() async {
    return {
      'url': await _storage.read(key: _keyUrl),
      'username': await _storage.read(key: _keyUsername),
      'password': await _storage.read(key: _keyPassword),
    };
  }

  static Future<void> save({
    required String url,
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _keyUrl, value: url.trimRight().replaceAll(RegExp(r'/$'), ''));
    await _storage.write(key: _keyUsername, value: username.trim());
    await _storage.write(key: _keyPassword, value: password);
  }

  static Future<bool> get isConfigured async {
    final url = await _storage.read(key: _keyUrl);
    final username = await _storage.read(key: _keyUsername);
    return url != null && url.isNotEmpty && username != null && username.isNotEmpty;
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
