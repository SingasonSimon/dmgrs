import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/contribution_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/modern_card.dart';

class AdminAllocationScreen extends StatefulWidget {
  const AdminAllocationScreen({super.key});

  @override
  State<AdminAllocationScreen> createState() => _AdminAllocationScreenState();
}

class _AdminAllocationScreenState extends State<AdminAllocationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final contributionProvider = Provider.of<ContributionProvider>(
      context,
      listen: false,
    );
    contributionProvider.loadAllocations();
    contributionProvider.loadCurrentCycle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fund Allocations'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current Cycle', icon: Icon(Icons.rotate_right)),
            Tab(text: 'Pending', icon: Icon(Icons.pending)),
            Tab(text: 'Disbursed', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: Consumer<ContributionProvider>(
        builder: (context, contributionProvider, child) {
          if (contributionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCurrentCycleTab(contributionProvider),
              _buildPendingAllocationsTab(contributionProvider),
              _buildDisbursedAllocationsTab(contributionProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentCycleTab(ContributionProvider contributionProvider) {
    final currentCycle = contributionProvider.currentCycle;

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cycle Status Card
            if (currentCycle != null) ...[
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.rotate_right,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Current Cycle Status',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCycleStat(
                              'Progress',
                              '${currentCycle.currentIndex}/${currentCycle.members.length}',
                              Colors.blue,
                              Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCycleStat(
                              'Remaining',
                              '${currentCycle.remainingMembers.length}',
                              Colors.orange,
                              Icons.people,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCycleStat(
                              'Days Left',
                              '${currentCycle.daysRemaining}',
                              Colors.green,
                              Icons.calendar_today,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCycleStat(
                              'Completed',
                              '${currentCycle.completedMembers.length}',
                              Colors.purple,
                              Icons.done_all,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: currentCycle.progressPercentage / 100,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${currentCycle.progressPercentage.toStringAsFixed(1)}% Complete',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (currentCycle.allMembersAllocated) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _completeCycle(context, contributionProvider),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Complete Cycle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Cycle Members List
            Text(
              'Cycle Members',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (currentCycle == null)
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rotate_right,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Active Cycle',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A new cycle will be created when the first contribution is made.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...currentCycle.members.asMap().entries.map((entry) {
                final index = entry.key;
                final memberId = entry.value;
                final isCompleted = index < currentCycle.currentIndex;
                final isCurrent = index == currentCycle.currentIndex;

                return ModernCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : isCurrent
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : isCurrent
                            ? Icons.pending
                            : Icons.schedule,
                        color: isCompleted
                            ? Colors.green
                            : isCurrent
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                    title: Text(
                      'Member ${index + 1}',
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      'ID: ${memberId.substring(0, 8)}...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.1)
                            : isCurrent
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCompleted
                            ? 'Completed'
                            : isCurrent
                            ? 'Current'
                            : 'Pending',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCompleted
                              ? Colors.green
                              : isCurrent
                              ? Colors.blue
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleStat(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAllocationsTab(
    ContributionProvider contributionProvider,
  ) {
    final pendingAllocations = contributionProvider.allocations
        .where((a) => !a.disbursed)
        .toList();

    if (pendingAllocations.isEmpty) {
      return _buildEmptyState(
        'No Pending Allocations',
        'All allocations have been disbursed.',
        Icons.check_circle_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: pendingAllocations.length,
        itemBuilder: (context, index) {
          final allocation = pendingAllocations[index];
          return _buildAllocationCard(
            context,
            allocation,
            contributionProvider,
          );
        },
      ),
    );
  }

  Widget _buildDisbursedAllocationsTab(
    ContributionProvider contributionProvider,
  ) {
    final disbursedAllocations = contributionProvider.allocations
        .where((a) => a.disbursed)
        .toList();

    if (disbursedAllocations.isEmpty) {
      return _buildEmptyState(
        'No Disbursed Allocations',
        'No allocations have been disbursed yet.',
        Icons.account_balance_wallet_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: disbursedAllocations.length,
        itemBuilder: (context, index) {
          final allocation = disbursedAllocations[index];
          return _buildAllocationCard(
            context,
            allocation,
            contributionProvider,
          );
        },
      ),
    );
  }

  Widget _buildAllocationCard(
    BuildContext context,
    allocation,
    ContributionProvider contributionProvider,
  ) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppHelpers.formatCurrency(allocation.amount),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: allocation.disbursed
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    allocation.disbursed ? 'Disbursed' : 'Pending',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: allocation.disbursed
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Allocation ID: ${allocation.allocationId.substring(0, 8)}...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Member ID: ${allocation.userId.substring(0, 8)}...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${AppHelpers.formatDate(allocation.date)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (!allocation.disbursed) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _disburseAllocation(
                    context,
                    allocation,
                    contributionProvider,
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text('Disburse Allocation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _disburseAllocation(
    BuildContext context,
    allocation,
    ContributionProvider contributionProvider,
  ) {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Disburse Allocation',
      message:
          'Are you sure you want to disburse ${AppHelpers.formatCurrency(allocation.amount)} to this member?',
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          await contributionProvider.disburseAllocationById(
            allocation.allocationId,
          );
          if (mounted) {
            AppHelpers.showSuccessSnackBar(
              context,
              'Allocation disbursed successfully!',
            );
          }
        } catch (e) {
          if (mounted) {
            AppHelpers.showErrorSnackBar(
              context,
              'Failed to disburse allocation: $e',
            );
          }
        }
      }
    });
  }

  void _completeCycle(
    BuildContext context,
    ContributionProvider contributionProvider,
  ) {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Complete Cycle',
      message:
          'Are you sure you want to complete the current cycle? This action cannot be undone.',
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          await contributionProvider.completeCurrentCycleManually();
          if (mounted) {
            AppHelpers.showSuccessSnackBar(
              context,
              'Cycle completed successfully!',
            );
          }
        } catch (e) {
          if (mounted) {
            AppHelpers.showErrorSnackBar(
              context,
              'Failed to complete cycle: $e',
            );
          }
        }
      }
    });
  }
}
