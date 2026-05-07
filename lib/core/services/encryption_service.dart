import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _passKey = 'nawa_enc_pass';
  static const _saltKey = 'nawa_enc_salt';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  enc.Encrypter? _encrypter;

  Future<void> _ensureKey() async {
    if (_encrypter != null) return;
    var pass = await _storage.read(key: _passKey);
    var salt = await _storage.read(key: _saltKey);
    if (pass == null || pass.isEmpty) {
      pass = _randomString(32);
      await _storage.write(key: _passKey, value: pass);
    }
    if (salt == null || salt.isEmpty) {
      salt = _randomString(16);
      await _storage.write(key: _saltKey, value: salt);
    }
    final keyBytes = sha256.convert(utf8.encode('$pass:$salt')).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  Future<String> encryptText(String plain) async {
    await _ensureKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter!.encrypt(plain, iv: iv);
    return jsonEncode({'iv': iv.base64, 'data': encrypted.base64});
  }

  Future<String> decryptText(String payload) async {
    await _ensureKey();
    try {
      final m = jsonDecode(payload) as Map;
      final iv = enc.IV.fromBase64(m['iv'] as String);
      final data = enc.Encrypted.fromBase64(m['data'] as String);
      return _encrypter!.decrypt(data, iv: iv);
    } catch (_) {
      return payload;
    }
  }

  String _randomString(int length) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
