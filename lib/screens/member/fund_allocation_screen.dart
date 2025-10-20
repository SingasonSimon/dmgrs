import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contribution_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class FundAllocationScreen extends StatefulWidget {
  const FundAllocationScreen({super.key});

  @override
  State<FundAllocationScreen> createState() => _FundAllocationScreenState();
}

class _FundAllocationScreenState extends State<FundAllocationScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final contributionProvider = Provider.of<ContributionProvider>(
      context,
      listen: false,
    );
    contributionProvider.loadCurrentCycle();
    contributionProvider.loadAllocations();
    contributionProvider.loadLendingPoolBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fund Allocation'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Consumer<ContributionProvider>(
        builder: (context, contributionProvider, child) {
          if (contributionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Cycle Info
                  _buildCurrentCycleCard(context, contributionProvider),

                  const SizedBox(height: 16),

                  // Lending Pool Balance
                  _buildLendingPoolCard(context, contributionProvider),

                  const SizedBox(height: 16),

                  // Recent Allocations
                  _buildAllocationsSection(context, contributionProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentCycleCard(
    BuildContext context,
    ContributionProvider provider,
  ) {
    final cycle = provider.currentCycle;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rotate_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Cycle',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (cycle == null) ...[
              Text(
                'No active cycle found. Initialize a new cycle to start fund allocation.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _initializeCycle(provider),
                  child: const Text('Initialize Cycle'),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildCycleStat(
                      context,
                      'Members',
                      '${cycle.members.length}',
                      Icons.people,
                    ),
                  ),
                  Expanded(
                    child: _buildCycleStat(
                      context,
                      'Completed',
                      '${cycle.currentIndex}',
                      Icons.check_circle,
                    ),
                  ),
                  Expanded(
                    child: _buildCycleStat(
                      context,
                      'Remaining',
                      '${cycle.remainingMembers.length}',
                      Icons.schedule,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: cycle.progressPercentage / 100,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 8),
              Text(
                '${cycle.progressPercentage.toStringAsFixed(1)}% Complete',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              // Complete cycle button removed for members - only admin can complete cycles
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCycleStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildLendingPoolCard(
    BuildContext context,
    ContributionProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lending Pool',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              AppHelpers.formatCurrency(provider.lendingPoolBalance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Available for loans',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationsSection(
    BuildContext context,
    ContributionProvider provider,
  ) {
    final userAllocations = provider.getUserAllocations(
      Provider.of<AuthProvider>(context, listen: false).userId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Allocations',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (userAllocations.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.money_off,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No allocations yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You haven\'t received any fund allocations yet. Keep contributing to participate in the rotation.',
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
          ...userAllocations.map(
            (allocation) => _buildAllocationCard(context, allocation),
          ),
      ],
    );
  }

  Widget _buildAllocationCard(BuildContext context, allocation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: allocation.isDisbursed
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          child: Icon(
            allocation.isDisbursed ? Icons.check : Icons.pending,
            color: allocation.isDisbursed ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          AppHelpers.formatCurrency(allocation.amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Allocated: ${AppHelpers.formatDate(allocation.date)}'),
        trailing: Chip(
          label: Text(
            allocation.isDisbursed ? 'DISBURSED' : 'PENDING',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          backgroundColor: allocation.isDisbursed
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          labelStyle: TextStyle(
            color: allocation.isDisbursed ? Colors.green : Colors.orange,
          ),
        ),
      ),
    );
  }

  void _initializeCycle(ContributionProvider provider) {
    provider
        .initializeCycle()
        .then((_) {
          AppHelpers.showSuccessSnackBar(
            context,
            'Cycle initialized successfully!',
          );
        })
        .catchError((error) {
          AppHelpers.showErrorSnackBar(
            context,
            'Failed to initialize cycle: $error',
          );
        });
  }
}
