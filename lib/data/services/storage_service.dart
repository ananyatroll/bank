import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static final FlutterSecureStorage _secure = FlutterSecureStorage();
  static late final Box<dynamic> _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    final key = await _loadOrCreateKey();
    _box = await Hive.openBox(
      'telebank',
      encryptionCipher: HiveAesCipher(key),
    );
  }

  static Box<dynamic> get box => _box;

  static Future<List<int>> _loadOrCreateKey() async {
    final existing = await _secure.read(key: 'hive_key');
    if (existing != null && existing.isNotEmpty) {
      return base64Url.decode(existing);
    }
    final key = Hive.generateSecureKey();
    await _secure.write(key: 'hive_key', value: base64UrlEncode(key));
    return key;
  }
}
