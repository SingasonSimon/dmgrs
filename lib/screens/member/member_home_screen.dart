import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contribution_provider.dart';
import '../../providers/loan_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/modern_bottom_nav.dart';
import '../../widgets/modern_navigation_drawer.dart';
import '../../widgets/modern_card.dart';
import '../shared/notifications_screen.dart';
import 'contribution_screen.dart';
import 'loan_screen.dart';
import 'profile_screen.dart';
import 'fund_allocation_screen.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contributionProvider = Provider.of<ContributionProvider>(
      context,
      listen: false,
    );
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      contributionProvider.loadUserContributions(authProvider.userId);
      loanProvider.loadUserLoans(authProvider.userId);
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
    return WillPopScope(
      onWillPop: () async {
        // Prevent back button from closing app
        if (_currentIndex > 0) {
          _onTabTapped(0); // Go to dashboard
          return false;
        }
        return true; // Allow back button to close app only from dashboard
      },
      child: Scaffold(
        drawer: ModernNavigationDrawer(
          onLogoutTap: _showLogoutDialog,
          onNavigationTap: _onTabTapped,
          isAdmin: false,
        ),
        body: Column(
          children: [
            // Custom header with menu and notifications
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const Spacer(),
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
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  _DashboardTab(onTabTapped: _onTabTapped),
                  const _PaymentsTab(),
                  const LoanScreen(),
                  const ProfileScreen(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: ModernBottomNav(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          isAdmin: false,
        ),
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Contributions', icon: Icon(Icons.payment)),
              Tab(text: 'Allocations', icon: Icon(Icons.rotate_right)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [ContributionScreen(), FundAllocationScreen()],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Function(int) onTabTapped;

  const _DashboardTab({required this.onTabTapped});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(''), automaticallyImplyLeading: false),
      body: RefreshIndicator(
        onRefresh: () async {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final contributionProvider = Provider.of<ContributionProvider>(
            context,
            listen: false,
          );
          final loanProvider = Provider.of<LoanProvider>(
            context,
            listen: false,
          );

          if (authProvider.isAuthenticated) {
            await Future.wait([
              contributionProvider.loadUserContributions(authProvider.userId),
              loanProvider.loadUserLoans(authProvider.userId),
            ]);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(context),

              const SizedBox(height: 24),

              // Financial Summary
              _buildFinancialSummary(context),

              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context),

              const SizedBox(height: 24),

              // Quick Stats Cards
              _buildQuickStats(context),

              const SizedBox(height: 24),

              // Recent Contributions
              _buildRecentContributions(context),

              const SizedBox(height: 24),

              // Active Loans
              _buildActiveLoans(context),

              const SizedBox(height: 24),

              // Progress Tracking
              _buildProgressTracking(context),

              const SizedBox(height: 24),

              // Upcoming Events
              _buildUpcomingEvents(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final now = DateTime.now();
        final hour = now.hour;
        String greeting;

        if (hour < 12) {
          greeting = 'Good Morning';
        } else if (hour < 17) {
          greeting = 'Good Afternoon';
        } else {
          greeting = 'Good Evening';
        }

        return ModernCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    authProvider.userDisplayName.isNotEmpty
                        ? authProvider.userDisplayName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting,',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.userDisplayName.isNotEmpty
                            ? authProvider.userDisplayName
                            : 'Member',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Active Member',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.waving_hand, color: Colors.orange, size: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialSummary(BuildContext context) {
    return Consumer2<ContributionProvider, LoanProvider>(
      builder: (context, contributionProvider, loanProvider, child) {
        final userId = Provider.of<AuthProvider>(context, listen: false).userId;
        final contributionStats = contributionProvider.getContributionStats();
        final loanStats = loanProvider.getUserLoanStats(userId);

        final totalContributed = contributionStats['totalAmount'] ?? 0.0;
        final totalOutstanding = loanStats['totalOutstanding'] ?? 0.0;
        final netPosition = totalContributed - totalOutstanding;

        return ModernCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Financial Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildFinancialItem(
                        context,
                        'Total Contributed',
                        AppHelpers.formatCurrency(totalContributed),
                        Colors.green,
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFinancialItem(
                        context,
                        'Outstanding Loans',
                        AppHelpers.formatCurrency(totalOutstanding),
                        Colors.red,
                        Icons.account_balance,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: netPosition >= 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: netPosition >= 0
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        netPosition >= 0 ? Icons.check_circle : Icons.warning,
                        color: netPosition >= 0 ? Colors.green : Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Position',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              AppHelpers.formatCurrency(netPosition.abs()),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: netPosition >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialItem(
    BuildContext context,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Make Payment',
                'Pay monthly contribution',
                Icons.payment,
                Colors.blue,
                () {
                  // Navigate to payments tab
                  onTabTapped(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Request Loan',
                'Apply for a loan',
                Icons.account_balance,
                Colors.green,
                () {
                  // Navigate to loans tab
                  onTabTapped(2);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'View Allocations',
                'Check fund distributions',
                Icons.rotate_right,
                Colors.orange,
                () {
                  // Navigate to payments tab, allocations section
                  onTabTapped(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Profile',
                'Manage your account',
                Icons.person,
                Colors.purple,
                () {
                  // Navigate to profile tab
                  onTabTapped(3);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ModernCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.05), color.withOpacity(0.1)],
            ),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTracking(BuildContext context) {
    return Consumer2<ContributionProvider, LoanProvider>(
      builder: (context, contributionProvider, loanProvider, child) {
        final userId = Provider.of<AuthProvider>(context, listen: false).userId;
        final userContributions = contributionProvider.getUserContributions(
          userId,
        );
        final userLoans = loanProvider.getUserLoans(userId);

        // Calculate contribution streak
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month);
        final hasContributedThisMonth = userContributions.any(
          (c) =>
              DateTime(c.date.year, c.date.month) == currentMonth &&
              c.isCompleted,
        );

        // Calculate loan progress
        final activeLoans = userLoans.where((l) => l.isActive).toList();
        final completedLoans = userLoans.where((l) => l.isCompleted).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressCard(
                    context,
                    'Contribution Streak',
                    hasContributedThisMonth ? 'Current Month ✓' : 'Pending',
                    hasContributedThisMonth ? Colors.green : Colors.orange,
                    Icons.calendar_today,
                    hasContributedThisMonth ? 1.0 : 0.0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressCard(
                    context,
                    'Loans Completed',
                    '${completedLoans.length} loans',
                    Colors.blue,
                    Icons.done_all,
                    completedLoans.length /
                        (completedLoans.length + activeLoans.length + 1),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
    double progress,
  ) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Consumer2<ContributionProvider, LoanProvider>(
      builder: (context, contributionProvider, loanProvider, child) {
        final contributionStats = contributionProvider.getContributionStats();
        final loanStats = loanProvider.getUserLoanStats(
          Provider.of<AuthProvider>(context, listen: false).userId,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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
                StatCard(
                  title: 'Monthly Contribution',
                  value: AppHelpers.formatCurrency(
                    AppConstants.monthlyContribution,
                  ),
                  icon: Icons.payment,
                  iconColor: Colors.blue,
                ),
                StatCard(
                  title: 'Active Loans',
                  value: '${loanStats['activeLoans']}',
                  icon: Icons.account_balance,
                  iconColor: Colors.green,
                ),
                StatCard(
                  title: 'Total Contributed',
                  value: AppHelpers.formatCurrency(
                    contributionStats['totalAmount'],
                  ),
                  icon: Icons.trending_up,
                  iconColor: Colors.orange,
                ),
                StatCard(
                  title: 'Outstanding Loans',
                  value: AppHelpers.formatCurrency(
                    loanStats['totalOutstanding'],
                  ),
                  icon: Icons.warning,
                  iconColor: Colors.red,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentContributions(BuildContext context) {
    return Consumer<ContributionProvider>(
      builder: (context, contributionProvider, child) {
        final userContributions = contributionProvider.getUserContributions(
          Provider.of<AuthProvider>(context, listen: false).userId,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Contributions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to payments tab (contributions)
                    onTabTapped(1);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (userContributions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No contributions yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start making your monthly contributions to participate in the group.',
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
              ...userContributions
                  .take(3)
                  .map(
                    (contribution) =>
                        _buildContributionCard(context, contribution),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildContributionCard(BuildContext context, contribution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppHelpers.getPaymentStatusColor(
            contribution.status,
          ).withOpacity(0.1),
          child: Icon(
            contribution.isCompleted ? Icons.check : Icons.pending,
            color: AppHelpers.getPaymentStatusColor(contribution.status),
          ),
        ),
        title: Text(
          AppHelpers.formatCurrency(contribution.amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(AppHelpers.formatDate(contribution.date)),
        trailing: Chip(
          label: Text(
            contribution.status.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppHelpers.getPaymentStatusColor(
            contribution.status,
          ).withOpacity(0.1),
          labelStyle: TextStyle(
            color: AppHelpers.getPaymentStatusColor(contribution.status),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveLoans(BuildContext context) {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        final userLoans = loanProvider.getUserLoans(
          Provider.of<AuthProvider>(context, listen: false).userId,
        );
        final activeLoans = userLoans.where((loan) => loan.isActive).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Loans',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to loans tab
                    onTabTapped(2);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activeLoans.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active loans',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You don\'t have any active loans at the moment.',
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
              ...activeLoans
                  .take(2)
                  .map((loan) => _buildLoanCard(context, loan)),
          ],
        );
      },
    );
  }

  Widget _buildLoanCard(BuildContext context, loan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppHelpers.getLoanStatusColor(
            loan.status,
          ).withOpacity(0.1),
          child: Icon(
            Icons.account_balance,
            color: AppHelpers.getLoanStatusColor(loan.status),
          ),
        ),
        title: Text(
          AppHelpers.formatCurrency(loan.finalAmount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          loan.purpose,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Remaining', style: Theme.of(context).textTheme.bodySmall),
            Text(
              AppHelpers.formatCurrency(loan.remainingBalance),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Events & Reminders',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ModernCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_outlined,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Meeting',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'First Saturday of each month',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Upcoming',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.payment, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Contribution Due',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Due by end of each month',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Active',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
