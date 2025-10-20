# Digital Merry Go Round System

A Flutter mobile application for automating traditional Chama group savings and lending operations in Kenya.

## Features

### Core Functionality
- **Member Authentication**: Secure sign-up, login, and password management
- **Monthly Contributions**: Automated KSh 1,000 monthly contribution tracking
- **Fund Allocation**: 50/50 split between lending pool and member distribution
- **M-Pesa Integration**: STK Push payment processing (sandbox/production ready)
- **Loan Management**: Request, approval, and repayment tracking system
- **Penalty System**: Automated 10% fines for late payments
- **Virtual Meetings**: Google Meet integration for monthly meetings
- **Real-time Notifications**: Push notifications and SMS alerts

### User Roles
- **Members**: Contribute monthly, request loans, view history
- **Administrators**: Manage members, approve loans, oversee operations

## Technology Stack

- **Frontend**: Flutter (iOS & Android)
- **Backend**: Firebase (Auth, Firestore, FCM, Functions)
- **Storage**: AWS S3 for documents
- **Payments**: M-Pesa Daraja API
- **State Management**: Provider
- **Notifications**: Firebase Cloud Messaging + Local Notifications

## Setup Instructions

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / Xcode
- Firebase project
- M-Pesa Daraja API credentials

### 1. Clone and Install Dependencies
```bash
git clone <https://github.com/SingasonSimon/dmgrs.git>
cd digital_merry_go_round
flutter pub get
```

### 2. Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Create Firestore database
4. Enable Cloud Messaging
5. Download configuration files:
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)
6. Update `lib/firebase_options.dart` with your project configuration

### 3. M-Pesa Setup
1. Register for M-Pesa Daraja API at [Safaricom Developer Portal](https://developer.safaricom.co.ke/)
2. Get your Consumer Key and Consumer Secret
3. Update `lib/services/mpesa_service.dart` with your credentials:
   ```dart
   static const String consumerKey = 'your_consumer_key';
   static const String consumerSecret = 'your_consumer_secret';
   ```

### 4. AWS S3 Setup (Optional)
1. Create an AWS S3 bucket
2. Configure IAM user with S3 permissions
3. Update `lib/services/s3_service.dart` with your credentials:
   ```dart
   static const String _accessKeyId = 'your_access_key_id';
   static const String _secretAccessKey = 'your_secret_access_key';
   ```

### 5. Run the Application
```bash
# For development
flutter run

# For production build
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── user_model.dart
│   ├── contribution_model.dart
│   ├── loan_model.dart
│   └── allocation_model.dart
├── services/                 # Business logic services
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── mpesa_service.dart
│   ├── notification_service.dart
│   └── s3_service.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── contribution_provider.dart
│   └── loan_provider.dart
├── screens/                  # UI screens
│   ├── auth/                 # Authentication screens
│   ├── member/               # Member screens
│   └── admin/                # Admin screens
├── widgets/                  # Reusable widgets
└── utils/                    # Utilities and constants
    ├── constants.dart
    ├── validators.dart
    └── helpers.dart
```

## Key Features Implementation

### Authentication System
- Email/password authentication
- Role-based access control (Member/Admin)
- Password reset via email
- Profile management

### Contribution Management
- Monthly KSh 1,000 contribution tracking
- M-Pesa STK Push integration
- Payment status monitoring
- Contribution history

### Fund Allocation
- 50% to lending pool
- 50% to random member (non-repeating rotation)
- Cycle management system
- Fair distribution algorithm

### Loan System
- Loan request submission
- Admin approval workflow
- Interest calculation (10% per annum)
- Repayment schedule tracking
- Outstanding balance monitoring

### Penalty System
- Automatic 10% fine for late payments
- Consecutive miss tracking
- Warning system (3 consecutive misses)
- Membership suspension workflow

## Security Features

- Firebase Security Rules
- Data encryption
- Input validation
- Secure API endpoints
- Role-based permissions

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

## Deployment

### Android
1. Generate signed APK:
   ```bash
   flutter build apk --release
   ```
2. Upload to Google Play Store

### iOS
1. Build for iOS:
   ```bash
   flutter build ios --release
   ```
2. Upload to App Store Connect

## Configuration

### Environment Variables
Create a `.env` file in the root directory:
```
MPESA_CONSUMER_KEY=your_consumer_key
MPESA_CONSUMER_SECRET=your_consumer_secret
MPESA_BUSINESS_SHORT_CODE=your_short_code
MPESA_PASSKEY=your_passkey
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_S3_BUCKET=your_bucket_name
```

### Firebase Security Rules
Update Firestore security rules in Firebase Console:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Contributions - users can read their own, admins can read all
    match /contributions/{contributionId} {
      allow read: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null;
    }
    
    // Similar rules for other collections...
  }
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Email: support@digitalmerrygoround.com
- Documentation: [Link to documentation]
- Issues: [GitHub Issues]

## Roadmap

- [ ] Multi-group support
- [ ] Advanced reporting
- [ ] Mobile money integration (beyond M-Pesa)
- [ ] Offline mode
- [ ] Web application
- [ ] API for third-party integrations

## Acknowledgments

- Safaricom for M-Pesa Daraja API
- Firebase for backend services
- Flutter team for the framework
- Kenyan Chama communities for inspiration# dmgrs
