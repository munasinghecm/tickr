import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tickr/models/todo_item.dart';

void main() {
  final encryptionKey = Uint8List.fromList(List.generate(32, (i) => i + 1));

  group('TodoItem Model Tests', () {
    test('toMap returns correct map representation', () {
      final now = DateTime.now();
      final item = TodoItem(
        id: 'todo_123',
        text: 'Clean the kitchen',
        isCompleted: false,
        userId: 'user_abc',
        circleId: 'circle_xyz',
        createdAt: now,
      );

      final map = item.toMap();

      expect(map['text'], 'Clean the kitchen');
      expect(map['isCompleted'], false);
      expect(map['userId'], 'user_abc');
      expect(map['circleId'], 'circle_xyz');
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), now);
    });

    test('fromMap creates correct TodoItem object', () {
      final now = DateTime.now();
      final map = {
        'text': 'Buy groceries',
        'isCompleted': true,
        'userId': 'user_abc',
        'circleId': null,
        'createdAt': Timestamp.fromDate(now),
      };

      final item = TodoItem.fromMap('todo_456', map);

      expect(item.id, 'todo_456');
      expect(item.text, 'Buy groceries');
      expect(item.isCompleted, true);
      expect(item.userId, 'user_abc');
      expect(item.circleId, isNull);
      expect(item.createdAt, now);
    });

    test('toMapEncrypted performs encryption when key is provided and not a circle todo', () {
      final now = DateTime.now();
      final item = TodoItem(
        id: 'todo_789',
        text: 'Secret Message',
        isCompleted: false,
        userId: 'user_abc',
        createdAt: now,
      );

      final encryptedMap = item.toMapEncrypted(encryptionKey);

      expect(encryptedMap['text'], isNot('Secret Message'));
      expect(encryptedMap['isCompleted'], false);
      expect(encryptedMap['userId'], 'user_abc');
      expect(encryptedMap['circleId'], isNull);
      expect(encryptedMap['isEncrypted'], true);
    });

    test('toMapEncrypted does not encrypt when key is null', () {
      final now = DateTime.now();
      final item = TodoItem(
        id: 'todo_789',
        text: 'Secret Message',
        isCompleted: false,
        userId: 'user_abc',
        createdAt: now,
      );

      final encryptedMap = item.toMapEncrypted(null);

      expect(encryptedMap['text'], 'Secret Message');
      expect(encryptedMap['isEncrypted'], false);
    });

    test('toMapEncrypted does not encrypt when it is a circle todo (circleId is not null)', () {
      final now = DateTime.now();
      final item = TodoItem(
        id: 'todo_789',
        text: 'Circle Message',
        isCompleted: false,
        userId: 'user_abc',
        circleId: 'circle_123',
        createdAt: now,
      );

      final encryptedMap = item.toMapEncrypted(encryptionKey);

      expect(encryptedMap['text'], 'Circle Message');
      expect(encryptedMap['isEncrypted'], false);
    });

    test('fromMapDecrypted decrypts properly when text is encrypted and key is provided', () {
      final now = DateTime.now();
      final originalItem = TodoItem(
        id: 'todo_999',
        text: 'My secret note',
        isCompleted: false,
        userId: 'user_abc',
        createdAt: now,
      );

      final encryptedMap = originalItem.toMapEncrypted(encryptionKey);

      final decryptedItem = TodoItem.fromMapDecrypted('todo_999', encryptedMap, encryptionKey);

      expect(decryptedItem.text, 'My secret note');
      expect(decryptedItem.id, 'todo_999');
      expect(decryptedItem.isCompleted, false);
      expect(decryptedItem.userId, 'user_abc');
    });

    test('fromMapDecrypted returns encrypted text if isEncrypted is true but key is null', () {
      final now = DateTime.now();
      final originalItem = TodoItem(
        id: 'todo_999',
        text: 'My secret note',
        isCompleted: false,
        userId: 'user_abc',
        createdAt: now,
      );

      final encryptedMap = originalItem.toMapEncrypted(encryptionKey);

      final decryptedItem = TodoItem.fromMapDecrypted('todo_999', encryptedMap, null);

      expect(decryptedItem.text, isNot('My secret note'));
      expect(decryptedItem.text, encryptedMap['text']);
    });
  });
}
