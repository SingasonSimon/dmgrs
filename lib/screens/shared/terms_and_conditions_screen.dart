import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By creating an account and using the Digital Merry Go Round System (DMGRS), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.',
            ),
            _buildSection(
              context,
              '2. Membership Requirements',
              'To become a member, you must:\n'
                  '• Be at least 18 years old\n'
                  '• Provide accurate and complete information during registration\n'
                  '• Agree to make monthly contributions of KSh ${AppConstants.monthlyContribution.toStringAsFixed(0)}\n'
                  '• Maintain an active account status',
            ),
            _buildSection(
              context,
              '3. Monthly Contributions',
              'Members are required to make monthly contributions of KSh ${AppConstants.monthlyContribution.toStringAsFixed(0)}. Contributions must be made by the due date each month. Late payments may incur penalties as outlined in section 4.',
            ),
            _buildSection(
              context,
              '4. Penalties and Late Payments',
              'A penalty of 10% will be applied to late contributions. Members who miss three consecutive payments may face suspension or removal from the group.',
            ),
            _buildSection(
              context,
              '5. Fund Allocation',
              'Contributions are allocated as follows:\n'
                  '• 50% goes to the lending pool for group loans\n'
                  '• 50% is distributed to members on a rotating basis\n'
                  '• Allocation order is determined by the group cycle system',
            ),
            _buildSection(
              context,
              '6. Loan Policy',
              'Members may request loans from the lending pool:\n'
                  '• Loan amounts cannot exceed available pool balance\n'
                  '• Minimum loan amount is KSh 1,000\n'
                  '• Interest rate is 10% per annum\n'
                  '• Loans require admin approval\n'
                  '• Repayment schedules are created based on loan amount',
            ),
            _buildSection(
              context,
              '7. Account Security',
              'You are responsible for:\n'
                  '• Maintaining the confidentiality of your account credentials\n'
                  '• All activities that occur under your account\n'
                  '• Notifying us immediately of any unauthorized access',
            ),
            _buildSection(
              context,
              '8. Privacy Policy',
              'We collect and use your personal information in accordance with our Privacy Policy. By using our services, you consent to the collection and use of your information as described in the Privacy Policy.',
            ),
            _buildSection(
              context,
              '9. Group Meetings',
              'Members are expected to attend monthly group meetings. Meeting schedules and details will be communicated through the app notifications.',
            ),
            _buildSection(
              context,
              '10. Termination',
              'Your membership may be terminated if:\n'
                  '• You violate these Terms and Conditions\n'
                  '• You fail to make required contributions\n'
                  '• You engage in fraudulent activities\n'
                  '• The group decides to remove you',
            ),
            _buildSection(
              context,
              '11. Limitation of Liability',
              'DMGRS is not liable for any losses or damages arising from:\n'
                  '• Technical failures or system errors\n'
                  '• Unauthorized access to your account\n'
                  '• Decisions made by group administrators\n'
                  '• Changes in group policies',
            ),
            _buildSection(
              context,
              '12. Changes to Terms',
              'We reserve the right to modify these Terms and Conditions at any time. Members will be notified of significant changes. Continued use of the service after changes constitutes acceptance of the new terms.',
            ),
            _buildSection(
              context,
              '13. Contact Information',
              'For questions or concerns regarding these Terms and Conditions, please contact the group administrators through the app.',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using DMGRS, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

