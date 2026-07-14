import 'package:flutter_test/flutter_test.dart';
import 'package:tickr/models/circle_model.dart';

void main() {
  group('Circle Model Tests', () {
    test('toMap returns correct map representation', () {
      final circle = Circle(
        id: '123',
        name: 'Test Circle',
        inviteCode: 'ABCDEF',
        adminId: 'user_admin',
        members: ['user_admin', 'user_member'],
      );

      final map = circle.toMap();

      expect(map['name'], 'Test Circle');
      expect(map['inviteCode'], 'ABCDEF');
      expect(map['adminId'], 'user_admin');
      expect(map['members'], ['user_admin', 'user_member']);
      // id is not serialized in toMap in the model
      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap creates correct Circle object', () {
      final map = {
        'name': 'Sample Circle',
        'inviteCode': 'XYZ123',
        'adminId': 'admin_uid',
        'members': ['admin_uid', 'member_uid'],
      };

      final circle = Circle.fromMap('circle_id_abc', map);

      expect(circle.id, 'circle_id_abc');
      expect(circle.name, 'Sample Circle');
      expect(circle.inviteCode, 'XYZ123');
      expect(circle.adminId, 'admin_uid');
      expect(circle.members, ['admin_uid', 'member_uid']);
    });

    test('fromMap handles missing or null fields gracefully with defaults', () {
      final map = <String, dynamic>{};

      final circle = Circle.fromMap('some_id', map);

      expect(circle.id, 'some_id');
      expect(circle.name, '');
      expect(circle.inviteCode, '');
      expect(circle.adminId, '');
      expect(circle.members, isEmpty);
    });
  });
}
