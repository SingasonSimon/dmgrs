import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:digital_merry_go_round/models/allocation_model.dart';
import 'package:digital_merry_go_round/models/user_model.dart';
import 'package:digital_merry_go_round/providers/auth_provider.dart';
import 'package:digital_merry_go_round/providers/contribution_provider.dart';
import 'package:digital_merry_go_round/providers/group_provider.dart';
import 'package:digital_merry_go_round/screens/member/fund_allocation_screen.dart';

AuthProvider makeTestAuth(String userId) {
  final user = UserModel(
    userId: userId,
    name: 'Test User',
    email: 'test@example.com',
    phone: '+254700000000',
    role: 'member',
    status: 'active',
    joinedAt: DateTime.now(),
  );
  return AuthProvider.test(user);
}

class StubContributionProvider extends ContributionProvider {
  final List<AllocationModel> _fakeAllocations;
  StubContributionProvider(this._fakeAllocations);

  @override
  List<AllocationModel> get allocations => _fakeAllocations;

  @override
  bool get isLoading => false;

  @override
  Future<void> loadCurrentCycle() async {}

  @override
  Future<void> loadAllocations() async {}

  @override
  Future<void> loadLendingPoolBalance() async {}
}

AllocationModel makeAllocation({
  required String id,
  required String userId,
  required double amount,
  String? groupId,
  bool disbursed = false,
}) {
  return AllocationModel(
    allocationId: id,
    userId: userId,
    amount: amount,
    date: DateTime.now(),
    cycleId: 'c1',
    groupId: groupId,
    disbursed: disbursed,
  );
}

void main() {
  testWidgets('Allocations filter: Only Mine shows current user allocations', (
    tester,
  ) async {
    final fakeAuth = makeTestAuth('u1');
    final fakeContrib = StubContributionProvider([
      makeAllocation(id: 'a1', userId: 'u1', amount: 1000),
      makeAllocation(id: 'a2', userId: 'u2', amount: 2000),
    ]);
    final fakeGroups = _StubGroupProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<ContributionProvider>.value(
            value: fakeContrib,
          ),
          ChangeNotifierProvider<GroupProvider>.value(value: fakeGroups),
        ],
        child: const MaterialApp(home: FundAllocationScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Only Mine is default true → expect only one allocation tile (u1)
    expect(find.byType(ListTile), findsOneWidget);
  });
}

class _StubGroupProvider extends GroupProvider {
  @override
  bool get isLoading => false;

  @override
  Future<void> loadUserGroups(String userId) async {}
}
