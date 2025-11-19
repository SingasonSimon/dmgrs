import 'package:flutter/foundation.dart';
import '../models/meeting_model.dart';
import '../services/meeting_service.dart';
import '../services/firestore_service.dart';

class MeetingProvider with ChangeNotifier {
  List<MeetingModel> _meetings = [];
  bool _isLoading = false;
  String? _error;

  List<MeetingModel> get meetings => _meetings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get upcoming meetings (excludes archived)
  List<MeetingModel> get upcomingMeetings {
    final now = DateTime.now();
    return _meetings
        .where((meeting) =>
            !meeting.isArchived &&
            meeting.scheduledDate.isAfter(now) &&
            meeting.status == 'scheduled')
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  // Get past meetings (includes archived for history)
  List<MeetingModel> get pastMeetings {
    final now = DateTime.now();
    return _meetings
        .where((meeting) =>
            meeting.scheduledDate.isBefore(now) || meeting.isArchived)
        .toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
  }

  // Get archived meetings (for history)
  List<MeetingModel> get archivedMeetings {
    return _meetings
        .where((meeting) => meeting.isArchived)
        .toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
  }

  // Get active meetings (non-archived)
  List<MeetingModel> get activeMeetings {
    return _meetings
        .where((meeting) => !meeting.isArchived)
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  // Get meetings by status
  List<MeetingModel> getMeetingsByStatus(String status) {
    return _meetings
        .where((meeting) => meeting.status == status)
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }

  // Load all meetings
  Future<void> loadMeetings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _meetings = await FirestoreService.retryOperation(
        () => MeetingService.getAllMeetings(),
        maxRetries: 2, // Reduce retries for permission errors
      );
      _error = null;
    } catch (e) {
      final errorMessage = e.toString();
      // Check if it's a permission error
      if (errorMessage.contains('permission-denied') || 
          errorMessage.contains('PERMISSION_DENIED')) {
        _error = 'Permission denied. Please ensure Firestore security rules allow reading meetings.';
      } else {
        _error = 'Failed to load meetings: $e';
      }
      _meetings = [];
      print('MeetingProvider: Error loading meetings - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user meetings
  Future<void> loadUserMeetings(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _meetings = await FirestoreService.retryOperation(
        () => MeetingService.getUserMeetings(userId),
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to load user meetings: $e';
      _meetings = [];
      print('MeetingProvider: Error loading user meetings - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create meeting
  Future<String?> createMeeting({
    required String title,
    required String description,
    required DateTime scheduledDate,
    required String organizerId,
    required String organizerName,
    List<String>? attendeeIds,
    String? meetingType,
    String? googleMeetUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final meetingId = await FirestoreService.retryOperation(
        () => MeetingService.createMeeting(
          title: title,
          description: description,
          scheduledDate: scheduledDate,
          organizerId: organizerId,
          organizerName: organizerName,
          attendeeIds: attendeeIds ?? [],
          meetingType: meetingType ?? 'general',
          googleMeetUrl: googleMeetUrl ?? '',
        ),
      );

      // Reload meetings
      await loadMeetings();
      return meetingId;
    } catch (e) {
      _error = 'Failed to create meeting: $e';
      print('MeetingProvider: Error creating meeting - $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update meeting status
  Future<bool> updateMeetingStatus(String meetingId, String status) async {
    try {
      final success = await FirestoreService.retryOperation(
        () => MeetingService.updateMeetingStatus(meetingId, status),
      );

      if (success) {
        // Update local state
        final index = _meetings.indexWhere((m) => m.meetingId == meetingId);
        if (index != -1) {
          _meetings[index] = _meetings[index].copyWith(status: status);
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _error = 'Failed to update meeting status: $e';
      print('MeetingProvider: Error updating meeting status - $e');
      return false;
    }
  }

  // Delete meeting
  Future<bool> deleteMeeting(String meetingId) async {
    try {
      final success = await FirestoreService.retryOperation(
        () => MeetingService.deleteMeeting(meetingId),
      );

      if (success) {
        _meetings.removeWhere((m) => m.meetingId == meetingId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = 'Failed to delete meeting: $e';
      print('MeetingProvider: Error deleting meeting - $e');
      return false;
    }
  }

  // Add attendee to meeting
  Future<bool> addAttendee(String meetingId, String userId) async {
    try {
      final success = await FirestoreService.retryOperation(
        () => MeetingService.addAttendee(meetingId, userId),
      );

      if (success) {
        // Update local state
        final index = _meetings.indexWhere((m) => m.meetingId == meetingId);
        if (index != -1) {
          final currentAttendees = List<String>.from(_meetings[index].attendeeIds);
          if (!currentAttendees.contains(userId)) {
            currentAttendees.add(userId);
            _meetings[index] = _meetings[index].copyWith(attendeeIds: currentAttendees);
            notifyListeners();
          }
        }
      }

      return success;
    } catch (e) {
      _error = 'Failed to add attendee: $e';
      print('MeetingProvider: Error adding attendee - $e');
      return false;
    }
  }

  // Remove attendee from meeting
  Future<bool> removeAttendee(String meetingId, String userId) async {
    try {
      final success = await FirestoreService.retryOperation(
        () => MeetingService.removeAttendee(meetingId, userId),
      );

      if (success) {
        // Update local state
        final index = _meetings.indexWhere((m) => m.meetingId == meetingId);
        if (index != -1) {
          final currentAttendees = List<String>.from(_meetings[index].attendeeIds);
          currentAttendees.remove(userId);
          _meetings[index] = _meetings[index].copyWith(attendeeIds: currentAttendees);
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _error = 'Failed to remove attendee: $e';
      print('MeetingProvider: Error removing attendee - $e');
      return false;
    }
  }

  // Get meeting statistics
  Future<Map<String, dynamic>> getMeetingStats() async {
    try {
      return await FirestoreService.retryOperation(
        () => MeetingService.getMeetingStats(),
      );
    } catch (e) {
      print('MeetingProvider: Error getting meeting stats - $e');
      return {};
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

