import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_secrets.dart';
import '../models/app_settings.dart';

class SettingsService {
  const SettingsService(this._storage);

  final FlutterSecureStorage _storage;

  static const _employeeNumberKey = 'employeeNumber';
  static const _userNameKey = 'userName';
  static const _emailKey = 'email';
  static const _notionTokenKey = 'notionToken';
  static const _notionDatabaseIdKey = 'notionDatabaseId';
  static const _imgbbApiKeyKey = 'imgbbApiKey';
  static const _lastSyncCheckAtKey = 'lastSyncCheckAt';
  static const _lastSyncCheckResultKey = 'lastSyncCheckResult';

  Future<AppSettings> load() async {
    return AppSettings(
      employeeNumber: await _storage.read(key: _employeeNumberKey) ?? '',
      userName: await _storage.read(key: _userNameKey) ?? '',
      email: await _storage.read(key: _emailKey) ?? '',
      notionToken: AppSecrets.notionToken.isNotEmpty
          ? AppSecrets.notionToken
          : await _storage.read(key: _notionTokenKey) ?? '',
      notionDatabaseId: AppSecrets.notionDatabaseId.isNotEmpty
          ? AppSecrets.notionDatabaseId
          : await _storage.read(key: _notionDatabaseIdKey) ?? '',
      imgbbApiKey: AppSecrets.imgbbApiKey.isNotEmpty
          ? AppSecrets.imgbbApiKey
          : await _storage.read(key: _imgbbApiKeyKey) ?? '',
      lastSyncCheckAt: await _storage.read(key: _lastSyncCheckAtKey),
      lastSyncCheckResult: await _storage.read(key: _lastSyncCheckResultKey) ?? '',
    );
  }

  Future<void> save(AppSettings settings) async {
    await _storage.write(key: _employeeNumberKey, value: settings.employeeNumber);
    await _storage.write(key: _userNameKey, value: settings.userName);
    await _storage.write(key: _emailKey, value: settings.email);

    if (!AppSecrets.hasExternalDefaults) {
      await _storage.write(key: _notionTokenKey, value: settings.notionToken);
      await _storage.write(key: _notionDatabaseIdKey, value: settings.notionDatabaseId);
      await _storage.write(key: _imgbbApiKeyKey, value: settings.imgbbApiKey);
    }

    await _storage.write(key: _lastSyncCheckAtKey, value: settings.lastSyncCheckAt);
    await _storage.write(
      key: _lastSyncCheckResultKey,
      value: settings.lastSyncCheckResult,
    );
  }
}
