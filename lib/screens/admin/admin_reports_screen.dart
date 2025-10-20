import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/contribution_provider.dart';
import '../../providers/loan_provider.dart';
import '../../widgets/simple_chart.dart';
import '../../widgets/modern_card.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';

  final List<String> _periods = [
    'This Month',
    'Last Month',
    'This Quarter',
    'Last Quarter',
    'This Year',
    'Last Year',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    contributionProvider.loadContributions();
    loanProvider.loadLoans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Contributions', icon: Icon(Icons.payments)),
            Tab(text: 'Loans', icon: Icon(Icons.account_balance)),
            Tab(text: 'Financials', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Select Period',
            onPressed: _showPeriodSelector,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildContributionsTab(),
          _buildLoansTab(),
          _buildFinancialsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer2<ContributionProvider, LoanProvider>(
      builder: (context, contributionProvider, loanProvider, child) {
        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKeyMetrics(contributionProvider, loanProvider),
                const SizedBox(height: 24),
                _buildTrendsChart(contributionProvider, loanProvider),
                const SizedBox(height: 24),
                _buildPerformanceIndicators(contributionProvider, loanProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeyMetrics(
    ContributionProvider contributionProvider,
    LoanProvider loanProvider,
  ) {
    final totalContributions = contributionProvider.contributions.fold(
      0.0,
      (sum, contribution) => sum + contribution.amount,
    );

    final totalLoans = loanProvider.loans.fold(
      0.0,
      (sum, loan) => sum + loan.finalAmount,
    );

    final activeLoans = loanProvider.loans
        .where((loan) => loan.status == AppConstants.loanActive)
        .length;

    final completedLoans = loanProvider.loans
        .where((loan) => loan.status == AppConstants.loanCompleted)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
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
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            ModernCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payments,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Contributions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppHelpers.formatCurrency(totalContributions),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            ModernCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 32,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Loans',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppHelpers.formatCurrency(totalLoans),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            ModernCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 32, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    'Active Loans',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$activeLoans',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            ModernCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 32, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    'Completed Loans',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedLoans',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendsChart(
    ContributionProvider contributionProvider,
    LoanProvider loanProvider,
  ) {
    final monthlyData = _generateMonthlyTrendsData(
      contributionProvider,
      loanProvider,
    );

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Trends',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SimpleLineChart(
            data: monthlyData,
            title: '',
            lineColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicators(
    ContributionProvider contributionProvider,
    LoanProvider loanProvider,
  ) {
    final totalContributions = contributionProvider.contributions.fold(
      0.0,
      (sum, contribution) => sum + contribution.amount,
    );

    final totalLoans = loanProvider.loans.fold(
      0.0,
      (sum, loan) => sum + loan.finalAmount,
    );

    final completedLoans = loanProvider.loans
        .where((loan) => loan.status == AppConstants.loanCompleted)
        .length;

    final totalLoansCount = loanProvider.loans.length;
    final completionRate = totalLoansCount > 0
        ? (completedLoans / totalLoansCount) * 100
        : 0.0;

    // Get actual member count from Firestore
    final memberCount = contributionProvider.contributions
        .map((c) => c.userId)
        .toSet()
        .length;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Indicators',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIndicator(
                  'Loan Completion Rate',
                  '${completionRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  completionRate >= 70 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIndicator(
                  'Average Contribution',
                  AppHelpers.formatCurrency(
                    totalContributions / (memberCount > 0 ? memberCount : 1),
                  ),
                  Icons.payments,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIndicator(
                  'Total Members',
                  '$memberCount',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIndicator(
                  'Fund Utilization',
                  '${((totalLoans / (totalContributions > 0 ? totalContributions : 1)) * 100).toStringAsFixed(1)}%',
                  Icons.account_balance_wallet,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContributionsTab() {
    return Consumer<ContributionProvider>(
      builder: (context, contributionProvider, child) {
        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContributionsSummary(contributionProvider),
                const SizedBox(height: 24),
                _buildContributionsChart(contributionProvider),
                const SizedBox(height: 24),
                _buildTopContributors(contributionProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContributionsSummary(ContributionProvider contributionProvider) {
    final totalContributions = contributionProvider.contributions.fold(
      0.0,
      (sum, contribution) => sum + contribution.amount,
    );

    final thisMonth = DateTime.now().month;
    final thisYear = DateTime.now().year;
    final monthlyContributions = contributionProvider.contributions
        .where((c) => c.date.month == thisMonth && c.date.year == thisYear)
        .fold(0.0, (sum, contribution) => sum + contribution.amount);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contributions Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Contributions',
                  AppHelpers.formatCurrency(totalContributions),
                  Icons.payments,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'This Month',
                  AppHelpers.formatCurrency(monthlyContributions),
                  Icons.calendar_month,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContributionsChart(ContributionProvider contributionProvider) {
    final monthlyData = _generateMonthlyContributionsData(contributionProvider);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Contributions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SimpleLineChart(
            data: monthlyData,
            title: '',
            lineColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTopContributors(ContributionProvider contributionProvider) {
    final contributorMap = <String, double>{};

    for (final contribution in contributionProvider.contributions) {
      contributorMap[contribution.userId] =
          (contributorMap[contribution.userId] ?? 0) + contribution.amount;
    }

    final sortedContributors = contributorMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topContributors = sortedContributors.take(5).toList();

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Contributors',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...topContributors.map((entry) {
            // For now, show user ID until we implement user lookup
            final userName = 'User ${entry.key.substring(0, 8)}...';
            final userInitials = userName
                .split(' ')
                .map((n) => n[0])
                .take(2)
                .join('')
                .toUpperCase();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      userInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          AppHelpers.formatCurrency(entry.value),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLoansTab() {
    return Consumer<LoanProvider>(
      builder: (context, loanProvider, child) {
        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLoansSummary(loanProvider),
                const SizedBox(height: 24),
                _buildLoansChart(loanProvider),
                const SizedBox(height: 24),
                _buildLoanStatusDistribution(loanProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoansSummary(LoanProvider loanProvider) {
    final totalLoans = loanProvider.loans.fold(
      0.0,
      (sum, loan) => sum + loan.finalAmount,
    );

    final activeLoans = loanProvider.loans
        .where((loan) => loan.status == AppConstants.loanActive)
        .fold(0.0, (sum, loan) => sum + loan.finalAmount);

    final completedLoans = loanProvider.loans
        .where((loan) => loan.status == AppConstants.loanCompleted)
        .fold(0.0, (sum, loan) => sum + loan.finalAmount);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loans Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Loans',
                  AppHelpers.formatCurrency(totalLoans),
                  Icons.account_balance,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Active Loans',
                  AppHelpers.formatCurrency(activeLoans),
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Completed Loans',
                  AppHelpers.formatCurrency(completedLoans),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Total Count',
                  '${loanProvider.loans.length}',
                  Icons.numbers,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoansChart(LoanProvider loanProvider) {
    final monthlyData = _generateMonthlyLoansData(loanProvider);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Loans',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SimpleLineChart(
            data: monthlyData,
            title: '',
            lineColor: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildLoanStatusDistribution(LoanProvider loanProvider) {
    final statusCounts = <String, int>{};

    for (final loan in loanProvider.loans) {
      statusCounts[loan.status] = (statusCounts[loan.status] ?? 0) + 1;
    }

    final statusData = statusCounts.entries.map((entry) {
      return ChartData(
        label: _getStatusLabel(entry.key),
        value: entry.value.toDouble(),
      );
    }).toList();

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loan Status Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SimplePieChart(data: statusData, title: ''),
        ],
      ),
    );
  }

  Widget _buildFinancialsTab() {
    return Consumer2<ContributionProvider, LoanProvider>(
      builder: (context, contributionProvider, loanProvider, child) {
        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFinancialSummary(contributionProvider, loanProvider),
                const SizedBox(height: 24),
                _buildProfitabilityAnalysis(contributionProvider, loanProvider),
                const SizedBox(height: 24),
                _buildCashFlowProjection(contributionProvider, loanProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialSummary(
    ContributionProvider contributionProvider,
    LoanProvider loanProvider,
  ) {
    final totalContributions = contributionProvider.contributions.fold(
      0.0,
      (sum, contribution) => sum + contribution.amount,
    );

    final totalLoans = loanProvider.loans.fold(
      0.0,
      (sum, loan) => sum + loan.finalAmount,
    );

    final totalInterest = loanProvider.loans
        .where((loan) => loan.status == AppConstants.loanCompleted)
        .fold(
          0.0,
          (sum, loan) => sum + (loan.finalAmount - loan.requestedAmount),
        );

    final availableFunds = totalContributions - totalLoans;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildFinancialItem(
                'Total Contributions',
                AppHelpers.formatCurrency(totalContributions),
                Icons.payments,
                Colors.green,
              ),
              _buildFinancialItem(
                'Total Loans',
                AppHelpers.formatCurrency(totalLoans),
                Icons.account_balance,
                Colors.blue,
              ),
              _buildFinancialItem(
                'Interest Earned',
                AppHelpers.formatCurrency(totalInterest),
                Icons.trending_up,
                Colors.orange,
              ),
              _buildFinancialItem(
                'Available Funds',
                AppHelpers.formatCurrency(availableFunds),
                Icons.account_balance_wallet,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfitabilityAnalysis(
    ContributionProvider contributionProvider,
    LoanProvider loanProvider,
  ) {
    final totalContributions = contributionProvider.contributions.fold(
      0.0,
      (sum, contribution) => sum + contribution.amount,
    );

    final totalInterest = loanProvider.loans
        .where((loan) => loan.status == AppConstants.loanCompleted)
        .fold(
          0.0,
          (sum, loan) => sum + (loan.finalAmount - loan.requestedAmount),
        );

    final profitabilityRate = totalContributions > 0
        ? (totalInterest / totalContributions) * 100
        : 0.0;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profitability Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIndicator(
                  'Interest Rate',
                  '${profitabilityRate.toStringAsFixed(2)}%',
                  Icons.percent,
                  profitabilityRate > 5 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIndicator(
                  'Total Interest',
                  AppHelpers.formatCurrency(totalInterest),
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowProjection(
    ContributionProvider contributionProvider,
    LoanProvider loanProvider,
  ) {
    // Simple cash flow projection based on current data
    final monthlyContributions = contributionProvider.contributions
        .where((c) => c.date.month == DateTime.now().month)
        .fold(0.0, (sum, contribution) => sum + contribution.amount);

    final projectedMonthlyIncome = monthlyContributions;
    final projectedYearlyIncome = projectedMonthlyIncome * 12;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cash Flow Projection',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIndicator(
                  'Monthly Income',
                  AppHelpers.formatCurrency(projectedMonthlyIncome),
                  Icons.calendar_month,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIndicator(
                  'Yearly Projection',
                  AppHelpers.formatCurrency(projectedYearlyIncome),
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<ChartData> _generateMonthlyTrendsData(
    ContributionProvider contributionProvider,
    LoanProvider loanProvider,
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
      double monthContributions = 0;
      for (final contribution in contributionProvider.contributions) {
        if (contribution.date.isAfter(
              monthStart.subtract(const Duration(days: 1)),
            ) &&
            contribution.date.isBefore(monthEnd.add(const Duration(days: 1)))) {
          monthContributions += contribution.amount;
        }
      }

      // Calculate loans for this month
      double monthLoans = 0;
      for (final loan in loanProvider.loans) {
        if (loan.requestDate.isAfter(
              monthStart.subtract(const Duration(days: 1)),
            ) &&
            loan.requestDate.isBefore(monthEnd.add(const Duration(days: 1)))) {
          monthLoans += loan.finalAmount;
        }
      }

      monthlyData.add(
        ChartData(label: months[i], value: monthContributions + monthLoans),
      );
    }

    return monthlyData;
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

  List<ChartData> _generateMonthlyLoansData(LoanProvider loanProvider) {
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

      // Calculate loans for this month
      double monthTotal = 0;
      for (final loan in loanProvider.loans) {
        if (loan.requestDate.isAfter(
              monthStart.subtract(const Duration(days: 1)),
            ) &&
            loan.requestDate.isBefore(monthEnd.add(const Duration(days: 1)))) {
          monthTotal += loan.finalAmount;
        }
      }

      monthlyData.add(ChartData(label: months[i], value: monthTotal));
    }

    return monthlyData;
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  void _showPeriodSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _periods.map((period) {
            return ListTile(
              title: Text(period),
              selected: period == _selectedPeriod,
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
