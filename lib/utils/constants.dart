class AppConstants {
  // App Information
  static const String appName = 'Digital Merry Go Round';
  static const String appVersion = '1.0.0';

  // Financial Constants
  static const double monthlyContribution = 1000.0; // KSh 1,000
  static const double lendingPoolPercentage = 0.5; // 50%
  static const double memberDistributionPercentage = 0.5; // 50%
  static const double penaltyPercentage = 0.1; // 10%
  static const int maxConsecutiveMisses = 3;

  // User Roles
  static const String memberRole = 'member';
  static const String adminRole = 'admin';

  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentCompleted = 'completed';
  static const String paymentFailed = 'failed';
  static const String paymentOverdue = 'overdue';

  // Loan Status
  static const String loanPending = 'pending';
  static const String loanApproved = 'approved';
  static const String loanRejected = 'rejected';
  static const String loanActive = 'active';
  static const String loanCompleted = 'completed';

  // Notification Types
  static const String notificationContribution = 'contribution';
  static const String notificationPenalty = 'penalty';
  static const String notificationAllocation = 'allocation';
  static const String notificationLoan = 'loan';
  static const String notificationMeeting = 'meeting';
  static const String notificationWarning = 'warning';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String contributionsCollection = 'contributions';
  static const String allocationsCollection = 'allocations';
  static const String cyclesCollection = 'cycles';
  static const String lendingPoolCollection = 'lendingPool';
  static const String loansCollection = 'loans';
  static const String penaltiesCollection = 'penalties';
  static const String meetingsCollection = 'meetings';
  static const String notificationsCollection = 'notifications';
  static const String transactionsCollection = 'transactions';

  // M-Pesa Constants (Sandbox)
  static const String mpesaSandboxUrl = 'https://sandbox.safaricom.co.ke';
  static const String mpesaProductionUrl = 'https://api.safaricom.co.ke';
  static const String mpesaBusinessShortCode = '174379'; // Sandbox
  static const String mpesaPasskey =
      'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919'; // Sandbox

  // AWS S3
  static const String s3BucketName = 'digital-merry-go-round-documents';
  static const String s3Region = 'us-east-1';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxPhoneLength = 15;
  static const int maxDescriptionLength = 500;

  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authError = 'Authentication failed. Please try again.';
  static const String permissionError =
      'You do not have permission to perform this action.';

  // Success Messages
  static const String contributionSuccess =
      'Contribution recorded successfully!';
  static const String loanRequestSuccess =
      'Loan request submitted successfully!';
  static const String profileUpdateSuccess = 'Profile updated successfully!';
}
