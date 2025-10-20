import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import '../utils/constants.dart';
import '../utils/helpers.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notification service
  static Future<void> initialize() async {
    try {
      // Request permission for notifications
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure Firebase messaging
      await _configureFirebaseMessaging();

      // Get FCM token
      await _getFCMToken();
    } catch (e) {
      throw Exception('Failed to initialize notification service: $e');
    }
  }

  // Request notification permission
  static Future<void> _requestPermission() async {
    try {
      // Request permission for notifications
      final status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Notification permission denied');
      }

      // Request permission for Firebase messaging
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        throw Exception('Firebase messaging permission denied');
      }
    } catch (e) {
      throw Exception('Failed to request notification permission: $e');
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
    } catch (e) {
      throw Exception('Failed to initialize local notifications: $e');
    }
  }

  // Configure Firebase messaging
  static Future<void> _configureFirebaseMessaging() async {
    try {
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      throw Exception('Failed to configure Firebase messaging: $e');
    }
  }

  // Get FCM token
  static Future<String?> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      throw Exception('Failed to get FCM token: $e');
    }
  }

  // Save FCM token to Firestore
  static Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('user_tokens').doc(userId).set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save FCM token: $e');
    }
  }

  // Send local notification
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'digital_merry_go_round',
            'Digital Merry Go Round Notifications',
            channelDescription: 'Notifications for Digital Merry Go Round app',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      throw Exception('Failed to show local notification: $e');
    }
  }

  // Schedule notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'digital_merry_go_round_scheduled',
            'Scheduled Notifications',
            channelDescription:
                'Scheduled notifications for Digital Merry Go Round app',
            importance: Importance.high,
            priority: Priority.high,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      throw Exception('Failed to schedule notification: $e');
    }
  }

  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      throw Exception('Failed to cancel notification: $e');
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      throw Exception('Failed to cancel all notifications: $e');
    }
  }

  // Handle foreground message
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification != null) {
        await showLocalNotification(
          id: message.hashCode,
          title: notification.title ?? 'Digital Merry Go Round',
          body: notification.body ?? '',
          payload: message.data.toString(),
        );
      }
    } catch (e) {
      throw Exception('Failed to handle foreground message: $e');
    }
  }

  // Handle notification tap
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    try {
      // Handle notification tap logic here
      // You can navigate to specific screens based on the notification data
      final data = message.data;
      if (data.containsKey('type')) {
        // Handle different notification types
        switch (data['type']) {
          case AppConstants.notificationContribution:
            // Navigate to contribution screen
            break;
          case AppConstants.notificationLoan:
            // Navigate to loan screen
            break;
          case AppConstants.notificationMeeting:
            // Navigate to meeting screen
            break;
          default:
            // Navigate to home screen
            break;
        }
      }
    } catch (e) {
      throw Exception('Failed to handle notification tap: $e');
    }
  }

  // Handle notification tap (local notifications)
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      // Handle local notification tap logic here
      final payload = response.payload;
      if (payload != null) {
        // Parse payload and navigate accordingly
      }
    } catch (e) {
      throw Exception('Failed to handle notification tap: $e');
    }
  }

  // Send contribution reminder
  static Future<void> sendContributionReminder({
    required String userId,
    required String userName,
    required DateTime dueDate,
  }) async {
    try {
      final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
      String title, body;

      if (daysUntilDue == 3) {
        title = 'Contribution Reminder';
        body =
            'Hi $userName, your monthly contribution of KSh ${AppConstants.monthlyContribution.toStringAsFixed(0)} is due in 3 days.';
      } else if (daysUntilDue == 1) {
        title = 'Contribution Due Tomorrow';
        body =
            'Hi $userName, your monthly contribution is due tomorrow. Please make your payment.';
      } else if (daysUntilDue == 0) {
        title = 'Contribution Due Today';
        body =
            'Hi $userName, your monthly contribution is due today. Please make your payment now.';
      } else {
        return; // Don't send reminder for other days
      }

      // Save notification to Firestore
      await _saveNotificationToFirestore(
        userId: userId,
        title: title,
        body: body,
        type: AppConstants.notificationContribution,
      );

      // Show local notification
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        payload: 'contribution_reminder',
      );
    } catch (e) {
      throw Exception('Failed to send contribution reminder: $e');
    }
  }

  // Send penalty notification
  static Future<void> sendPenaltyNotification({
    required String userId,
    required String userName,
    required double penaltyAmount,
  }) async {
    try {
      final title = 'Late Payment Penalty';
      final body =
          'Hi $userName, a penalty of KSh ${penaltyAmount.toStringAsFixed(0)} has been applied for late payment.';

      // Save notification to Firestore
      await _saveNotificationToFirestore(
        userId: userId,
        title: title,
        body: body,
        type: AppConstants.notificationPenalty,
      );

      // Show local notification
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        payload: 'penalty_notification',
      );
    } catch (e) {
      throw Exception('Failed to send penalty notification: $e');
    }
  }

  // Send allocation notification
  static Future<void> sendAllocationNotification({
    required String userId,
    required String userName,
    required double amount,
  }) async {
    try {
      final title = 'Fund Allocation';
      final body =
          'Hi $userName, you have been allocated KSh ${amount.toStringAsFixed(0)} from this month\'s contributions.';

      // Save notification to Firestore
      await _saveNotificationToFirestore(
        userId: userId,
        title: title,
        body: body,
        type: AppConstants.notificationAllocation,
      );

      // Show local notification
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        payload: 'allocation_notification',
      );
    } catch (e) {
      throw Exception('Failed to send allocation notification: $e');
    }
  }

  // Send loan status notification
  static Future<void> sendLoanStatusNotification({
    required String userId,
    required String userName,
    required String status,
    required double amount,
    String? reason,
  }) async {
    try {
      String title, body;

      switch (status) {
        case AppConstants.loanApproved:
          title = 'Loan Approved';
          body =
              'Hi $userName, your loan request of KSh ${amount.toStringAsFixed(0)} has been approved.';
          break;
        case AppConstants.loanRejected:
          title = 'Loan Rejected';
          body =
              'Hi $userName, your loan request of KSh ${amount.toStringAsFixed(0)} has been rejected.${reason != null ? ' Reason: $reason' : ''}';
          break;
        default:
          return;
      }

      // Save notification to Firestore
      await _saveNotificationToFirestore(
        userId: userId,
        title: title,
        body: body,
        type: AppConstants.notificationLoan,
      );

      // Show local notification
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        payload: 'loan_status_notification',
      );
    } catch (e) {
      throw Exception('Failed to send loan status notification: $e');
    }
  }

  // Send meeting notification
  static Future<void> sendMeetingNotification({
    required String userId,
    required String userName,
    required DateTime meetingDate,
    required String meetingLink,
  }) async {
    try {
      final title = 'Monthly Meeting';
      final body =
          'Hi $userName, the monthly meeting is scheduled for ${AppHelpers.formatDate(meetingDate)}. Join here: $meetingLink';

      // Save notification to Firestore
      await _saveNotificationToFirestore(
        userId: userId,
        title: title,
        body: body,
        type: AppConstants.notificationMeeting,
      );

      // Show local notification
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        payload: 'meeting_notification',
      );
    } catch (e) {
      throw Exception('Failed to send meeting notification: $e');
    }
  }

  // Save notification to Firestore
  static Future<void> _saveNotificationToFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _firestore.collection(AppConstants.notificationsCollection).add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      throw Exception('Failed to save notification to Firestore: $e');
    }
  }

  // Get user notifications
  static Future<List<Map<String, dynamic>>> getUserNotifications(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('sentAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      throw Exception('Failed to get user notifications: $e');
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Get unread notification count
  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread notification count: $e');
    }
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Handle background message here
    print('Handling background message: ${message.messageId}');
  } catch (e) {
    print('Error handling background message: $e');
  }
}
