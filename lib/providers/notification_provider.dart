import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Load notifications for a user
  Future<void> loadUserNotifications(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      _notifications = await FirestoreService.getUserNotifications(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await FirestoreService.updateNotification(notificationId, {
        'isRead': true,
      });

      final index = _notifications.indexWhere(
        (n) => n.notificationId == notificationId,
      );
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      await FirestoreService.markAllNotificationsAsRead(userId);

      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark all notifications as read: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: title,
        message: message,
        type: type,
        data: data,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await FirestoreService.createNotification(notification);

      // Add to local list
      _notifications.insert(0, notification);
      notifyListeners();
    } catch (e) {
      _setError('Failed to create notification: $e');
    }
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get recent notifications (last 10)
  List<NotificationModel> get recentNotifications {
    return _notifications.take(10).toList();
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Set error message
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _error = null;
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
}
