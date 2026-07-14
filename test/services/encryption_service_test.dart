import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickr/services/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    const passphrase = 'my_secure_passphrase';
    const salt = 'some_random_salt';

    test('deriveKey returns deterministic 256-bit key (32 bytes)', () {
      final key1 = EncryptionService.deriveKey(passphrase, salt);
      final key2 = EncryptionService.deriveKey(passphrase, salt);

      // Check key length
      expect(key1.length, 32);
      
      // Check determinism
      expect(key1, key2);

      // Check different passphrase/salt yields different key
      final keyDifferentPass = EncryptionService.deriveKey('different', salt);
      final keyDifferentSalt = EncryptionService.deriveKey(passphrase, 'different');

      expect(key1, isNot(keyDifferentPass));
      expect(key1, isNot(keyDifferentSalt));
    });

    test('encryptText and decryptText round-trip works', () {
      final keyBytes = EncryptionService.deriveKey(passphrase, salt);
      const plaintext = 'This is a secret message to be encrypted.';

      final ciphertext = EncryptionService.encryptText(plaintext, keyBytes);
      expect(ciphertext, isNotEmpty);
      expect(ciphertext, isNot(plaintext));

      final decrypted = EncryptionService.decryptText(ciphertext, keyBytes);
      expect(decrypted, plaintext);
    });

    test('decryptText returns error message when wrong key is used', () {
      final correctKey = EncryptionService.deriveKey(passphrase, salt);
      final wrongKey = EncryptionService.deriveKey('wrong_passphrase', salt);
      const plaintext = 'Highly confidential data.';

      final ciphertext = EncryptionService.encryptText(plaintext, correctKey);
      final decryptedWithWrongKey = EncryptionService.decryptText(ciphertext, wrongKey);

      expect(decryptedWithWrongKey, '[Decryption Failed: Invalid Passphrase or Corrupted Data]');
    });

    test('decryptText returns error message when ciphertext is invalid or corrupted', () {
      final keyBytes = EncryptionService.deriveKey(passphrase, salt);
      
      // Too short ciphertext
      final shortCiphertext = base64.encode(List.generate(10, (i) => i));
      final decryptedShort = EncryptionService.decryptText(shortCiphertext, keyBytes);
      expect(decryptedShort, '[Decryption Failed: Invalid Passphrase or Corrupted Data]');

      // Completely invalid base64 string
      final invalidBase64 = 'not-a-base-64-string!!!';
      final decryptedInvalid = EncryptionService.decryptText(invalidBase64, keyBytes);
      expect(decryptedInvalid, '[Decryption Failed: Invalid Passphrase or Corrupted Data]');
    });
  });
}
