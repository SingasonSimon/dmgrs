import 'package:flutter_test/flutter_test.dart';
import 'package:digital_merry_go_round/models/group_model.dart';

void main() {
  group('Group Creation Tests', () {
    test('GroupModel validation works correctly', () {
      // Test valid group name
      final validNameError = GroupModel.validateGroupName('Test Group');
      expect(validNameError, isNull);

      // Test invalid group name (too short)
      final shortNameError = GroupModel.validateGroupName('Hi');
      expect(shortNameError, isNotNull);
      expect(shortNameError, contains('at least 3 characters'));

      // Test invalid group name (too long)
      final longNameError = GroupModel.validateGroupName('a' * 51);
      expect(longNameError, isNotNull);
      expect(longNameError, contains('less than 50 characters'));

      // Test valid description
      final validDescError = GroupModel.validateDescription(
        'A test group description',
      );
      expect(validDescError, isNull);

      // Test invalid description (too long)
      final longDescError = GroupModel.validateDescription('a' * 501);
      expect(longDescError, isNotNull);
      expect(longDescError, contains('less than 500 characters'));
    });

    test('GroupModel creates successfully', () {
      final group = GroupModel(
        groupId: 'test_id_123',
        groupName: 'Test Group',
        description: 'Test Description',
        adminId: 'admin_123',
        memberIds: ['user1', 'user2'],
        createdAt: DateTime.now(),
      );

      expect(group.groupId, equals('test_id_123'));
      expect(group.groupName, equals('Test Group'));
      expect(group.description, equals('Test Description'));
      expect(group.adminId, equals('admin_123'));
      expect(group.memberIds, equals(['user1', 'user2']));
      expect(group.memberCount, equals(2));
      expect(group.isActive, isTrue);
    });

    test('GroupModel business logic works', () {
      final group = GroupModel(
        groupId: 'test_id',
        groupName: 'Test Group',
        description: 'Test',
        adminId: 'admin_123',
        memberIds: ['user1', 'user2'],
        createdAt: DateTime.now(),
      );

      expect(group.hasMembers, isTrue);
      expect(group.isMember('user1'), isTrue);
      expect(group.isMember('user3'), isFalse);
      expect(group.isAdmin('admin_123'), isTrue);
      expect(group.isAdmin('user1'), isFalse);
      expect(group.canManage('admin_123'), isTrue);
      expect(group.canManage('user1'), isTrue);
    });
  });
}
