import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:digital_merry_go_round/models/group_model.dart';
import 'package:digital_merry_go_round/providers/group_provider.dart';
import 'package:digital_merry_go_round/providers/auth_provider.dart';
import 'package:digital_merry_go_round/screens/admin/admin_groups_screen.dart';

class FakeGroupProvider extends GroupProvider {
  final List<GroupModel> _seedGroups;
  FakeGroupProvider(this._seedGroups);

  @override
  List<GroupModel> get groups => _seedGroups;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadGroups() async {
    // no-op
  }
}

class FakeAuthProvider extends AuthProvider {
  FakeAuthProvider() : super();

  @override
  String get userId => 'test_admin_user';

  @override
  bool get isAuthenticated => true;

  @override
  String get userRole => 'admin';
}

GroupModel makeGroup(String id, String name, {int members = 3}) {
  return GroupModel(
    groupId: id,
    groupName: name,
    description: 'Test group $name',
    adminId: 'admin_1',
    memberIds: List.generate(members, (i) => 'user_$i'),
    createdAt: DateTime.now(),
  );
}

void main() {
  testWidgets('AdminGroupsScreen renders seeded groups', (tester) async {
    final fakeProvider = FakeGroupProvider([
      makeGroup('g1', 'Alpha Group', members: 4),
      makeGroup('g2', 'Beta Group', members: 2),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GroupProvider>.value(value: fakeProvider),
        ],
        child: const MaterialApp(home: AdminGroupsScreen()),
      ),
    );

    // Initial frame
    await tester.pumpAndSettle();

    expect(find.text('Group Management'), findsOneWidget);
    expect(find.text('Alpha Group'), findsOneWidget);
    expect(find.text('Beta Group'), findsOneWidget);
    expect(find.byIcon(Icons.groups), findsWidgets);

    // Check that group IDs are displayed
    expect(find.text('ID: g1'), findsOneWidget);
    expect(find.text('ID: g2'), findsOneWidget);
  });
}
