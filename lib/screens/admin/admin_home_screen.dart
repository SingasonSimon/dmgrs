import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contribution_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/modern_bottom_nav.dart';
import '../../widgets/modern_navigation_drawer.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/simple_chart.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../shared/notifications_screen.dart';
import '../shared/welcome_screen.dart';
import 'admin_loan_screen.dart';
import 'admin_allocation_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_groups_screen.dart';
import 'admin_add_user_screen.dart';
import 'admin_edit_user_screen.dart';

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
    if (!mounted) return;

    try {
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
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  void _onTabTapped(int index) {
    if (!mounted) return;

    setState(() {
      _currentIndex = index;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    }
  }

  void _showLogoutDialog() {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
    ).then((confirmed) async {
      if (confirmed == true) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signOut();
        if (mounted) {
          // Navigate back to welcome screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        }
      }
    });
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Members';
      case 2:
        return 'Loans';
      case 3:
        return 'Allocations';
      case 4:
        return 'Reports';
      default:
        return 'Admin Dashboard';
    }
  }

  List<Widget> _getAppBarActions() {
    switch (_currentIndex) {
      case 0: // Dashboard
        return [
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
          IconButton(
            icon: const Icon(Icons.groups),
            tooltip: 'Manage Groups',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminGroupsScreen(),
                ),
              );
            },
          ),
        ];
      case 1: // Members
        return [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminAddUserScreen(),
                ),
              );
              // Refresh member list if user was created
              if (result == true && mounted) {
                setState(() {
                  // This will trigger a rebuild and refresh the member list
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger a rebuild of the members tab
              setState(() {});
            },
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: _getAppBarActions(),
      ),
      drawer: ModernNavigationDrawer(
        onLogoutTap: _showLogoutDialog,
        onNavigationTap: _onTabTapped,
        isAdmin: true,
      ),
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
          AdminReportsScreen(),
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
    return RefreshIndicator(
      onRefresh: () async {
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return StatCard(
                        title: 'Total Users',
                        value: 'Loading...',
                        icon: Icons.people,
                        iconColor: Colors.blue,
                      );
                    }

                    if (snapshot.hasError) {
                      return StatCard(
                        title: 'Total Users',
                        value: 'Error',
                        icon: Icons.people,
                        iconColor: Colors.red,
                      );
                    }

                    final memberCount = snapshot.data ?? 0;
                    return StatCard(
                      title: 'Total Users',
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
            // Loan Status Chart (Top)
            SimplePieChart(
              title: 'Loan Status Distribution',
              data: loanStatusData,
              size: 200,
            ),
            const SizedBox(height: 24),
            // Monthly Contributions Chart (Below)
            SimpleLineChart(title: 'Monthly Contributions', data: monthlyData),
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

class _MembersTab extends StatefulWidget {
  const _MembersTab();

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  static const int _itemsPerPage = 10;
  int _currentPage = 0;
  List<UserModel> _allMembers = [];
  List<UserModel> _displayedMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final members = await FirestoreService.getActiveMembers();
      if (mounted) {
        setState(() {
          _allMembers = members;
          _currentPage = 0;
          _updateDisplayedMembers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateDisplayedMembers() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _allMembers.length);
    _displayedMembers = _allMembers.sublist(startIndex, endIndex);
  }

  void _nextPage() {
    if ((_currentPage + 1) * _itemsPerPage < _allMembers.length) {
      setState(() {
        _currentPage++;
        _updateDisplayedMembers();
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _updateDisplayedMembers();
      });
    }
  }

  int get _totalPages => (_allMembers.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No members found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first member to get started',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminAddUserScreen(),
                  ),
                );
                // Refresh member list if user was created
                if (result == true && mounted) {
                  _loadMembers();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Member'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Pagination info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${_displayedMembers.length} of ${_allMembers.length} members',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_totalPages > 1)
                Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),

        // Members list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadMembers();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _displayedMembers.length,
              itemBuilder: (context, index) {
                final member = _displayedMembers[index];
                return _buildEnhancedMemberCard(context, member);
              },
            ),
          ),
        ),

        // Pagination controls
        if (_totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous page',
                ),
                const SizedBox(width: 16),
                ...List.generate(
                  _totalPages.clamp(0, 5), // Show max 5 page numbers
                  (index) {
                    final pageNumber = _currentPage < 3
                        ? index
                        : _currentPage - 2 + index;

                    if (pageNumber >= _totalPages) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _currentPage = pageNumber;
                            _updateDisplayedMembers();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _currentPage == pageNumber
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _currentPage == pageNumber
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Text(
                            '${pageNumber + 1}',
                            style: TextStyle(
                              color: _currentPage == pageNumber
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: _currentPage == pageNumber
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed:
                      (_currentPage + 1) * _itemsPerPage < _allMembers.length
                      ? _nextPage
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next page',
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _viewMemberDetails(BuildContext context, UserModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, Icons.email, 'Email', member.email),
            _buildDetailRow(
              context,
              Icons.phone,
              'Phone',
              PhoneFormatter.getDisplayFormat(member.phone),
            ),
            _buildDetailRow(context, Icons.badge, 'Role', member.role),
            _buildDetailRow(
              context,
              Icons.circle,
              'Status',
              member.status,
              valueColor: member.status == 'active'
                  ? Colors.green
                  : Colors.orange,
            ),
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'Joined',
              AppHelpers.formatDate(member.joinedAt),
            ),
            if (member.lastLoginAt != null)
              _buildDetailRow(
                context,
                Icons.login,
                'Last Login',
                AppHelpers.formatDate(member.lastLoginAt!),
              ),
            _buildDetailRow(
              context,
              Icons.warning,
              'Consecutive Misses',
              '${member.consecutiveMisses}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editMember(BuildContext context, UserModel member) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEditUserScreen(user: member),
      ),
    );
    // Refresh member list if user was updated
    if (result == true && mounted) {
      _loadMembers();
    }
  }

  void _deactivateMember(BuildContext context, UserModel member) {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Deactivate Member',
      message:
          'Are you sure you want to deactivate ${member.name}? They will no longer be able to access the app.',
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final updatedMember = member.copyWith(status: 'inactive');
          await FirestoreService.updateUser(updatedMember);
          if (mounted) {
            AppHelpers.showSuccessSnackBar(
              context,
              'Member deactivated successfully',
            );
            // Refresh the member list
            _loadMembers();
          }
        } catch (e) {
          if (mounted) {
            AppHelpers.showErrorSnackBar(
              context,
              'Failed to deactivate member: $e',
            );
          }
        }
      }
    });
  }

  void _deleteMember(BuildContext context, UserModel member) {
    AppHelpers.showConfirmationDialog(
      context,
      title: 'Delete Member',
      message:
          'Are you sure you want to permanently delete ${member.name}? This action cannot be undone and will remove all their data.',
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          await FirestoreService.deleteUser(member.userId);
          if (mounted) {
            AppHelpers.showSuccessSnackBar(
              context,
              'Member deleted successfully',
            );
            // Refresh the member list
            _loadMembers();
          }
        } catch (e) {
          if (mounted) {
            AppHelpers.showErrorSnackBar(
              context,
              'Failed to delete member: $e',
            );
          }
        }
      }
    });
  }

  Widget _buildEnhancedMemberCard(BuildContext context, UserModel member) {
    final isAdmin = member.role == AppConstants.adminRole;
    final roleColor = isAdmin ? Colors.red : Colors.blue;
    final roleIcon = isAdmin ? Icons.admin_panel_settings : Icons.person;

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar, name, and role badge
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: roleColor.withOpacity(0.1),
                  child: Icon(roleIcon, color: roleColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: roleColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              member.role.toUpperCase(),
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Member details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (member.phone.isNotEmpty) ...[
                    _buildDetailRow(
                      context,
                      Icons.phone,
                      'Phone',
                      PhoneFormatter.getDisplayFormat(member.phone),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildDetailRow(
                    context,
                    Icons.calendar_today,
                    'Joined',
                    AppHelpers.formatDate(member.joinedAt),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    Icons.badge,
                    'Status',
                    member.status.toUpperCase(),
                    valueColor: member.status == 'active'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewMemberDetails(context, member),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('View'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editMember(context, member),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deactivateMember(context, member),
                        icon: const Icon(Icons.person_off, size: 18),
                        label: const Text('Deactivate'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteMember(context, member),
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
