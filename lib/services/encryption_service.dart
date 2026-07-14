import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyPrefix = 'encryption_key_';

  // Derives a 256-bit key from a user passphrase and salt using PBKDF2
  static Uint8List deriveKey(String passphrase, String salt) {
    final pkcs = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
    pkcs.init(pc.Pbkdf2Parameters(utf8.encode(salt) as Uint8List, 10000, 32));
    return pkcs.process(utf8.encode(passphrase) as Uint8List);
  }

  // Save the derived key securely on the device
  static Future<void> saveKey(String userId, Uint8List keyBytes) async {
    final base64Key = base64Url.encode(keyBytes);
    await _storage.write(key: '$_keyPrefix$userId', value: base64Key);
  }

  // Retrieve the key from secure storage
  static Future<Uint8List?> getKey(String userId) async {
    final base64Key = await _storage.read(key: '$_keyPrefix$userId');
    if (base64Key == null) return null;
    return base64Url.decode(base64Key);
  }

  // Delete the key from the device (on logout)
  static Future<void> clearKey(String userId) async {
    await _storage.delete(key: '$_keyPrefix$userId');
  }

  // Encrypts text using AES-256 (CBC mode)
  static String encryptText(String plaintext, Uint8List keyBytes) {
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    final combined = BytesBuilder()
      ..add(iv.bytes)
      ..add(encrypted.bytes);
    return base64.encode(combined.toBytes());
  }

  // Decrypts text using AES-256 (CBC mode)
  static String decryptText(String ciphertextBase64, Uint8List keyBytes) {
    try {
      final combined = base64.decode(ciphertextBase64);
      if (combined.length < 16) throw Exception('Invalid ciphertext');

      final ivBytes = combined.sublist(0, 16);
      final encryptedBytes = combined.sublist(16);

      final key = enc.Key(keyBytes);
      final iv = enc.IV(ivBytes);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      return encrypter.decrypt(enc.Encrypted(encryptedBytes), iv: iv);
    } catch (e) {
      return '[Decryption Failed: Invalid Passphrase or Corrupted Data]';
    }
  }
}
