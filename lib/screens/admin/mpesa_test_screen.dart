import 'package:flutter/material.dart';
import '../../services/mpesa_service.dart';
import '../../utils/constants.dart';
import '../../widgets/modern_card.dart';

class MpesaTestScreen extends StatefulWidget {
  const MpesaTestScreen({super.key});

  @override
  State<MpesaTestScreen> createState() => _MpesaTestScreenState();
}

class _MpesaTestScreenState extends State<MpesaTestScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _testResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M-Pesa Connection Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testConnection,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Environment Info
            ModernCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Environment Configuration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Environment',
                      AppConstants.isMpesaSandbox ? 'Sandbox' : 'Production',
                      AppConstants.isMpesaSandbox
                          ? Colors.orange
                          : Colors.green,
                    ),
                    _buildInfoRow(
                      'Base URL',
                      AppConstants.isMpesaSandbox
                          ? AppConstants.mpesaSandboxUrl
                          : AppConstants.mpesaProductionUrl,
                      null,
                    ),
                    _buildInfoRow(
                      'Business Short Code',
                      AppConstants.isMpesaSandbox
                          ? AppConstants.mpesaSandboxBusinessShortCode
                          : AppConstants.mpesaBusinessShortCode,
                      null,
                    ),
                    _buildInfoRow(
                      'Consumer Key',
                      AppConstants.mpesaConsumerKey.startsWith('your_')
                          ? 'Not configured'
                          : '${AppConstants.mpesaConsumerKey.substring(0, 8)}...',
                      AppConstants.mpesaConsumerKey.startsWith('your_')
                          ? Colors.red
                          : Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testConnection,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_protected_setup),
                label: Text(_isLoading ? 'Testing...' : 'Test Connection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Results
            if (_testResult != null) ...[
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _testResult!['success']
                                ? Icons.check_circle
                                : Icons.error,
                            color: _testResult!['success']
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Test Results',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'Status',
                        _testResult!['success'] ? 'Success' : 'Failed',
                        _testResult!['success'] ? Colors.green : Colors.red,
                      ),
                      _buildInfoRow('Message', _testResult!['message'], null),
                      _buildInfoRow(
                        'Environment',
                        _testResult!['environment'],
                        null,
                      ),
                      if (_testResult!['accessToken'] != null)
                        _buildInfoRow(
                          'Access Token',
                          _testResult!['accessToken'],
                          null,
                        ),
                      if (_testResult!['serviceAvailable'] != null)
                        _buildInfoRow(
                          'Service Available',
                          _testResult!['serviceAvailable'] ? 'Yes' : 'No',
                          _testResult!['serviceAvailable']
                              ? Colors.green
                              : Colors.red,
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Instructions
            ModernCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Instructions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '1. Register at https://daraja.safaricom.co.ke/\n'
                      '2. Create a sandbox app\n'
                      '3. Get your Consumer Key and Secret\n'
                      '4. Update the constants in lib/utils/constants.dart\n'
                      '5. Test the connection using this screen\n'
                      '6. Switch to production when ready',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      final result = await MpesaService.testConnection();
      setState(() {
        _testResult = result;
      });
    } catch (e) {
      setState(() {
        _testResult = {
          'success': false,
          'message': 'Test failed: $e',
          'environment': AppConstants.isMpesaSandbox ? 'Sandbox' : 'Production',
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
