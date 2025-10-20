import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contribution_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/modern_bottom_nav.dart';
import '../../widgets/modern_navigation_drawer.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/simple_chart.dart';
import '../shared/notifications_screen.dart';
import 'admin_loan_screen.dart';
import 'admin_allocation_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Delay loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadData() {
    final contributionProvider = Provider.of<ContributionProvider>(
      context,
      listen: false,
    );
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    contributionProvider.loadContributions();
    contributionProvider.loadAllocations();
    contributionProvider.loadCurrentCycle();
    contributionProvider.loadLendingPoolBalance();

    loanProvider.loadLoans();
    loanProvider.loadLendingPoolBalance();

    if (authProvider.isAuthenticated) {
      notificationProvider.loadUserNotifications(authProvider.userId);
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: AppConstants.mediumAnimation,
      curve: Curves.easeInOut,
    );
  }

  void _showLogoutDialog() {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
    ).then((confirmed) {
      if (confirmed == true) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.signOut();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: ModernNavigationDrawer(onLogoutTap: _showLogoutDialog),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          _AdminDashboardTab(),
          _MembersTab(),
          _LoansTab(),
          _AllocationsTab(),
          _ReportsTab(),
        ],
      ),
      bottomNavigationBar: ModernBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        isAdmin: true,
      ),
    );
  }
}

class _AdminDashboardTab extends StatelessWidget {
  const _AdminDashboardTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final contributionProvider = Provider.of<ContributionProvider>(
            context,
            listen: false,
          );
          final loanProvider = Provider.of<LoanProvider>(
            context,
            listen: false,
          );
          final notificationProvider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );

          await Future.wait([
            contributionProvider.loadContributions(),
            contributionProvider.loadAllocations(),
            contributionProvider.loadCurrentCycle(),
            contributionProvider.loadLendingPoolBalance(),
            loanProvider.loadLoans(),
            loanProvider.loadLendingPoolBalance(),
            if (authProvider.isAuthenticated)
              notificationProvider.loadUserNotifications(authProvider.userId),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats
              _buildQuickStats(context),

              const SizedBox(height: 24),

              // Charts Section
              _buildChartsSection(context),

              const SizedBox(height: 24),

              // Recent Activity
              _buildRecentActivity(context),

              const SizedBox(height: 24),

              // Pending Actions
              _buildPendingActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Consumer2<ContributionProvider, LoanProvider>(
      builder: (context, contributionProvider, loanProvider, child) {
        final contributionStats = contributionProvider.getContributionStats();
        final loanStats = loanProvider.getLoanStats();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                FutureBuilder<int>(
                  future: contributionProvider.getMemberCount(),
                  builder: (context, snapshot) {
                    final memberCount = snapshot.data ?? 0;
                    return StatCard(
                      title: 'Total Members',
                      value: '$memberCount',
                      icon: Icons.people,
                      iconColor: Colors.blue,
                    );
                  },
                ),
                StatCard(
                  title: 'Lending Pool',
                  value: AppHelpers.formatCurrency(
                    loanProvider.lendingPoolBalance,
                  ),
                  icon: Icons.account_balance,
                  iconColor: Colors.green,
                ),
                StatCard(
                  title: 'Pending Loans',
                  value: '${loanStats['pendingLoans']}',
                  icon: Icons.pending,
                  iconColor: Colors.orange,
                ),
                StatCard(
                  title: 'System Revenue',
                  value: AppHelpers.formatCurrency(
                    _calculateSystemRevenue(loanProvider),
                  ),
                  icon: Icons.trending_up,
                  iconColor: Colors.purple,
                ),
                StatCard(
                  title: 'Overdue Payments',
                  value: '${contributionStats['overdueContributions']}',
                  icon: Icons.warning,
                  iconColor: Colors.red,
                ),
                StatCard(
                  title: 'Active Loans',
                  value: '${loanStats['activeLoans']}',
                  icon: Icons.account_balance_wallet,
                  iconColor: Colors.teal,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  double _calculateSystemRevenue(LoanProvider loanProvider) {
    // Calculate total interest earned from completed loans
    double totalInterest = 0;
    for (final loan in loanProvider.loans) {
      if (loan.status == 'completed' && loan.approvedAmount != null) {
        // Calculate interest: (finalAmount - approvedAmount)
        final interest = loan.finalAmount - loan.approvedAmount!;
        totalInterest += interest;
      }
    }
    return totalInterest;
  }

  List<ChartData> _generateMonthlyContributionsData(
    ContributionProvider contributionProvider,
  ) {
    final currentYear = DateTime.now().year;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final monthlyData = <ChartData>[];

    for (int i = 0; i < 12; i++) {
      final month = i + 1;
      final monthStart = DateTime(currentYear, month, 1);
      final monthEnd = DateTime(currentYear, month + 1, 0, 23, 59, 59);

      // Calculate contributions for this month
      double monthTotal = 0;
      for (final contribution in contributionProvider.contributions) {
        if (contribution.date.isAfter(
              monthStart.subtract(const Duration(days: 1)),
            ) &&
            contribution.date.isBefore(monthEnd.add(const Duration(days: 1)))) {
          monthTotal += contribution.amount;
        }
      }

      monthlyData.add(ChartData(label: months[i], value: monthTotal));
    }

    return monthlyData;
  }

  Widget _buildChartsSection(BuildContext context) {
    return Consumer2<ContributionProvider, LoanProvider>(
      builder: (context, contributionProvider, loanProvider, child) {
        final loanStats = loanProvider.getLoanStats();

        // Sample data for charts
        final loanStatusData = [
          ChartData(
            label: 'Pending',
            value: loanStats['pendingLoans']?.toDouble() ?? 0,
          ),
          ChartData(
            label: 'Active',
            value: loanStats['activeLoans']?.toDouble() ?? 0,
          ),
          ChartData(
            label: 'Completed',
            value: loanStats['completedLoans']?.toDouble() ?? 0,
          ),
          ChartData(
            label: 'Rejected',
            value: loanStats['rejectedLoans']?.toDouble() ?? 0,
          ),
        ];

        // Generate monthly contributions data for the full year
        final monthlyData = _generateMonthlyContributionsData(
          contributionProvider,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SimplePieChart(
                    title: 'Loan Status',
                    data: loanStatusData,
                    size: 120,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SimpleBarChart(
                    title: 'Monthly Contributions',
                    data: monthlyData,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Consumer3<ContributionProvider, LoanProvider, NotificationProvider>(
      builder:
          (
            context,
            contributionProvider,
            loanProvider,
            notificationProvider,
            child,
          ) {
            final recentActivities = _getRecentActivities(
              contributionProvider,
              loanProvider,
              notificationProvider,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (recentActivities.isEmpty)
                  ModernCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.timeline,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No recent activity',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Activity feed will appear here as members interact with the system.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentActivities
                      .take(5)
                      .map((activity) => _buildActivityItem(context, activity)),
              ],
            );
          },
    );
  }

  Widget _buildPendingActions(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        final pendingLoans = loanProvider.pendingLoans;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Actions',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (pendingLoans.isEmpty)
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending actions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pending loan approvals and other actions will appear here.',
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
              ...pendingLoans
                  .take(3)
                  .map((loan) => _buildPendingLoanItem(context, loan)),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getRecentActivities(
    ContributionProvider contributionProvider,
    LoanProvider loanProvider,
    NotificationProvider notificationProvider,
  ) {
    final activities = <Map<String, dynamic>>[];

    // Add recent contributions
    final recentContributions = contributionProvider.contributions
        .where((c) => c.status == 'completed')
        .take(3)
        .toList();

    for (final contribution in recentContributions) {
      activities.add({
        'type': 'contribution',
        'title': 'Payment Received',
        'message':
            'KES ${contribution.amount.toStringAsFixed(0)} contribution completed',
        'time': contribution.paidDate ?? contribution.date,
        'icon': Icons.payment,
        'color': Colors.green,
      });
    }

    // Add recent loan activities
    final recentLoans = loanProvider.loans
        .where((l) => l.status == 'active' || l.status == 'completed')
        .take(3)
        .toList();

    for (final loan in recentLoans) {
      activities.add({
        'type': 'loan',
        'title': loan.status == 'active' ? 'Loan Approved' : 'Loan Completed',
        'message':
            'KES ${loan.finalAmount.toStringAsFixed(0)} loan ${loan.status}',
        'time': loan.status == 'active' ? loan.approvalDate : loan.dueDate,
        'icon': Icons.account_balance,
        'color': loan.status == 'active' ? Colors.blue : Colors.purple,
      });
    }

    // Add recent notifications
    final recentNotifications = notificationProvider.recentNotifications
        .where((n) => n.type != 'system')
        .take(3)
        .toList();

    for (final notification in recentNotifications) {
      activities.add({
        'type': 'notification',
        'title': notification.title,
        'message': notification.message,
        'time': notification.createdAt,
        'icon': _getNotificationIcon(notification.type),
        'color': _getNotificationColor(notification.type),
      });
    }

    // Sort by time (most recent first)
    activities.sort(
      (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
    );

    return activities;
  }

  Widget _buildActivityItem(
    BuildContext context,
    Map<String, dynamic> activity,
  ) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['message'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppHelpers.formatDate(activity['time'] as DateTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingLoanItem(BuildContext context, loan) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.pending, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loan Request',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'KES ${loan.requestedAmount.toStringAsFixed(0)} - ${loan.purpose}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Requested ${AppHelpers.formatDate(loan.requestDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Navigate to loan management
              // This would typically open the loan details or approval screen
            },
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'payment':
        return Icons.payment;
      case 'loan':
        return Icons.account_balance;
      case 'allocation':
        return Icons.account_balance_wallet;
      case 'meeting':
        return Icons.event;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'payment':
        return Colors.green;
      case 'loan':
        return Colors.blue;
      case 'allocation':
        return Colors.orange;
      case 'meeting':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new member
              AppHelpers.showSnackBar(
                context,
                'Add member functionality coming soon!',
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Members management coming soon!')),
    );
  }
}

class _LoansTab extends StatelessWidget {
  const _LoansTab();

  @override
  Widget build(BuildContext context) {
    return const AdminLoanScreen();
  }
}

class _AllocationsTab extends StatelessWidget {
  const _AllocationsTab();

  @override
  Widget build(BuildContext context) {
    return const AdminAllocationScreen();
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const Center(child: Text('Reports coming soon!')),
    );
  }
}
