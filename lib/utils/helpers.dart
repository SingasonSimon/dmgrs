import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'constants.dart';

class AppHelpers {
  // Format currency (Kenyan Shillings) with smart formatting for large numbers
  static String formatCurrency(double amount) {
    // For amounts over 1000, use K/M/B suffixes for better readability
    if (amount >= 1000000000) {
      return 'KSh ${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return 'KSh ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'KSh ${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      final formatter = NumberFormat.currency(
        locale: 'en_KE',
        symbol: 'KSh ',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    }
  }

  // Format currency for display (alternative compact format)
  static String formatCurrencyCompact(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_KE',
      symbol: 'KSh ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Format date
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  // Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  // Format time only
  static String formatTime(DateTime dateTime) {
    return DateFormat(AppConstants.timeFormat).format(dateTime);
  }

  // Get relative time (e.g., "2 hours ago", "3 days ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Calculate days until next contribution
  static int getDaysUntilNextContribution() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return nextMonth.difference(now).inDays;
  }

  // Calculate penalty amount
  static double calculatePenalty(double amount) {
    return amount * AppConstants.penaltyPercentage;
  }

  // Calculate lending pool amount (50% of contribution)
  static double calculateLendingPoolAmount(double contribution) {
    return contribution * AppConstants.lendingPoolPercentage;
  }

  // Calculate member distribution amount (50% of contribution)
  static double calculateMemberDistributionAmount(double contribution) {
    return contribution * AppConstants.memberDistributionPercentage;
  }

  // Check if payment is overdue
  static bool isPaymentOverdue(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }

  // Get payment status color
  static Color getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.paymentCompleted:
        return Colors.green;
      case AppConstants.paymentPending:
        return Colors.orange;
      case AppConstants.paymentFailed:
        return Colors.red;
      case AppConstants.paymentOverdue:
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  // Get loan status color
  static Color getLoanStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.loanApproved:
        return Colors.green;
      case AppConstants.loanPending:
        return Colors.orange;
      case AppConstants.loanRejected:
        return Colors.red;
      case AppConstants.loanActive:
        return Colors.blue;
      case AppConstants.loanCompleted:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Get loan status display text with better descriptions
  static String getLoanStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.loanPending:
        return 'Under Review';
      case AppConstants.loanApproved:
        return 'Approved & Ready';
      case AppConstants.loanActive:
        return 'In Progress';
      case AppConstants.loanCompleted:
        return 'Fully Repaid';
      case AppConstants.loanRejected:
        return 'Declined';
      default:
        return status.toUpperCase();
    }
  }

  // Get loan status description for better user understanding
  static String getLoanStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.loanPending:
        return 'Your loan request is being reviewed by the admin';
      case AppConstants.loanApproved:
        return 'Your loan has been approved and is ready for disbursement';
      case AppConstants.loanActive:
        return 'Your loan is active and repayments are in progress';
      case AppConstants.loanCompleted:
        return 'Congratulations! You have successfully repaid your loan';
      case AppConstants.loanRejected:
        return 'Your loan request was not approved';
      default:
        return 'Unknown status';
    }
  }

  // Get loan status icon
  static IconData getLoanStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.loanPending:
        return Icons.hourglass_empty;
      case AppConstants.loanApproved:
        return Icons.check_circle_outline;
      case AppConstants.loanActive:
        return Icons.trending_up;
      case AppConstants.loanCompleted:
        return Icons.done_all;
      case AppConstants.loanRejected:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // Get user role display name
  static String getUserRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case AppConstants.adminRole:
        return 'Administrator';
      case AppConstants.memberRole:
        return 'Member';
      default:
        return 'Unknown';
    }
  }

  // Show snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor ?? Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.green,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Show error snackbar with enhanced styling
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
      icon: Icons.error_outline,
      duration: const Duration(seconds: 4),
    );
  }

  // Show success snackbar with enhanced styling
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.green.shade600,
      textColor: Colors.white,
      icon: Icons.check_circle_outline,
      duration: const Duration(seconds: 3),
    );
  }

  // Show info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.blue.shade600,
      textColor: Colors.white,
      icon: Icons.info_outline,
      duration: const Duration(seconds: 3),
    );
  }

  // Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.orange.shade600,
      textColor: Colors.white,
      icon: Icons.warning_outlined,
      duration: const Duration(seconds: 4),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message ?? 'Loading...'),
          ],
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Show confirmation dialog
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // Show error dialog with retry option
  static Future<bool?> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? errorDetails,
    String retryText = 'Retry',
    String dismissText = 'Dismiss',
    VoidCallback? onRetry,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (errorDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                'Details: $errorDetails',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(dismissText),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onRetry();
              },
              child: Text(retryText),
            ),
        ],
      ),
    );
  }

  // Handle common errors with user-friendly messages
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection error. Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check your account permissions.';
    } else if (errorString.contains('not found')) {
      return 'The requested resource was not found.';
    } else if (errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return 'You are not authorized to perform this action.';
    } else if (errorString.contains('validation') ||
        errorString.contains('invalid')) {
      return 'Invalid data provided. Please check your input and try again.';
    } else if (errorString.contains('server') ||
        errorString.contains('internal')) {
      return 'Server error occurred. Please try again later.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Show network error dialog
  static Future<void> showNetworkErrorDialog(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    return showErrorDialog(
      context,
      title: 'Connection Error',
      message:
          'Unable to connect to the server. Please check your internet connection.',
      retryText: 'Retry',
      onRetry: onRetry,
    ).then((_) {});
  }

  // Show validation error dialog
  static Future<void> showValidationErrorDialog(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    return showErrorDialog(
      context,
      title: 'Validation Error',
      message: message,
      retryText: 'Fix',
      onRetry: onRetry,
    ).then((_) {});
  }

  // Generate random ID
  static String generateRandomId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Clean phone number (remove spaces, dashes, etc.)
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }

  // Format phone number for display
  static String formatPhoneNumber(String phone) {
    final cleaned = cleanPhoneNumber(phone);
    if (cleaned.length == 10 && cleaned.startsWith('0')) {
      return cleaned; // 07xxxxxxxx
    } else if (cleaned.length == 12 && cleaned.startsWith('254')) {
      return '0${cleaned.substring(3)}'; // Convert to 07xxxxxxxx
    } else if (cleaned.length == 13 && cleaned.startsWith('254')) {
      return '0${cleaned.substring(3)}'; // Convert to 07xxxxxxxx
    }
    return phone; // Return original if format is unclear
  }

  // Check if string is valid email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Check if string is valid phone number
  static bool isValidPhoneNumber(String phone) {
    final cleaned = cleanPhoneNumber(phone);
    return (cleaned.length == 10 && cleaned.startsWith('0')) ||
        (cleaned.length == 12 && cleaned.startsWith('254')) ||
        (cleaned.length == 13 && cleaned.startsWith('254'));
  }

  // Get initials from name
  static String getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  // Capitalize first letter of each word
  static String capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  // Launch URL
  static Future<void> launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri);
    } else {
      throw Exception('Could not launch $url');
    }
  }
}
