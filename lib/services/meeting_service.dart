import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meeting_model.dart';
import '../utils/constants.dart';

class MeetingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new meeting
  static Future<String> createMeeting({
    required String title,
    required String description,
    required DateTime scheduledDate,
    required String organizerId,
    required String organizerName,
    List<String>? attendeeIds,
    String? meetingType,
    String? googleMeetUrl,
  }) async {
    try {
      final meetingId = _firestore
          .collection(AppConstants.meetingsCollection)
          .doc()
          .id;

      final meeting = MeetingModel(
        meetingId: meetingId,
        title: title,
        description: description,
        scheduledDate: scheduledDate,
        organizerId: organizerId,
        organizerName: organizerName,
        attendeeIds: attendeeIds ?? [],
        meetingType: meetingType ?? 'general',
        status: AppConstants.meetingScheduled,
        googleMeetUrl: googleMeetUrl ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.meetingsCollection)
          .doc(meetingId)
          .set(meeting.toMap());

      print('MeetingService: Created meeting $meetingId');
      return meetingId;
    } catch (e) {
      throw Exception('Failed to create meeting: $e');
    }
  }


  // Get all meetings
  static Future<List<MeetingModel>> getAllMeetings() async {
    try {
      final meetings = await _firestore
          .collection(AppConstants.meetingsCollection)
          .orderBy('scheduledDate', descending: false)
          .get();

      return meetings.docs
          .map((doc) => MeetingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('MeetingService: Error getting meetings - $e');
      return [];
    }
  }

  // Get user's meetings
  static Future<List<MeetingModel>> getUserMeetings(String userId) async {
    try {
      final meetings = await _firestore
          .collection(AppConstants.meetingsCollection)
          .where('attendeeIds', arrayContains: userId)
          .orderBy('scheduledDate', descending: false)
          .get();

      return meetings.docs
          .map((doc) => MeetingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('MeetingService: Error getting user meetings - $e');
      return [];
    }
  }

  // Get upcoming meetings
  static Future<List<MeetingModel>> getUpcomingMeetings() async {
    try {
      final now = DateTime.now();
      final meetings = await _firestore
          .collection(AppConstants.meetingsCollection)
          .where('scheduledDate', isGreaterThan: Timestamp.fromDate(now))
          .where('status', isEqualTo: AppConstants.meetingScheduled)
          .orderBy('scheduledDate', descending: false)
          .get();

      return meetings.docs
          .map((doc) => MeetingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('MeetingService: Error getting upcoming meetings - $e');
      return [];
    }
  }

  // Join meeting
  static Future<bool> joinMeeting(String meetingUrl) async {
    try {
      final uri = Uri.parse(meetingUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw Exception('Could not launch meeting URL');
      }
    } catch (e) {
      print('MeetingService: Error joining meeting - $e');
      return false;
    }
  }

  // Update meeting status
  static Future<bool> updateMeetingStatus(
    String meetingId,
    String status,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.meetingsCollection)
          .doc(meetingId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('MeetingService: Updated meeting $meetingId status to $status');
      return true;
    } catch (e) {
      print('MeetingService: Error updating meeting status - $e');
      return false;
    }
  }

  // Add attendee to meeting
  static Future<bool> addAttendee(String meetingId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.meetingsCollection)
          .doc(meetingId)
          .update({
            'attendeeIds': FieldValue.arrayUnion([userId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('MeetingService: Added attendee $userId to meeting $meetingId');
      return true;
    } catch (e) {
      print('MeetingService: Error adding attendee - $e');
      return false;
    }
  }

  // Remove attendee from meeting
  static Future<bool> removeAttendee(String meetingId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.meetingsCollection)
          .doc(meetingId)
          .update({
            'attendeeIds': FieldValue.arrayRemove([userId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('MeetingService: Removed attendee $userId from meeting $meetingId');
      return true;
    } catch (e) {
      print('MeetingService: Error removing attendee - $e');
      return false;
    }
  }

  // Delete meeting
  static Future<bool> deleteMeeting(String meetingId) async {
    try {
      await _firestore
          .collection(AppConstants.meetingsCollection)
          .doc(meetingId)
          .delete();

      print('MeetingService: Deleted meeting $meetingId');
      return true;
    } catch (e) {
      print('MeetingService: Error deleting meeting - $e');
      return false;
    }
  }

  // Get meeting statistics
  static Future<Map<String, dynamic>> getMeetingStats() async {
    try {
      final totalMeetings = await _firestore
          .collection(AppConstants.meetingsCollection)
          .get();

      final scheduledMeetings = await _firestore
          .collection(AppConstants.meetingsCollection)
          .where('status', isEqualTo: AppConstants.meetingScheduled)
          .get();

      final completedMeetings = await _firestore
          .collection(AppConstants.meetingsCollection)
          .where('status', isEqualTo: AppConstants.meetingCompleted)
          .get();

      final cancelledMeetings = await _firestore
          .collection(AppConstants.meetingsCollection)
          .where('status', isEqualTo: AppConstants.meetingCancelled)
          .get();

      return {
        'totalMeetings': totalMeetings.docs.length,
        'scheduledMeetings': scheduledMeetings.docs.length,
        'completedMeetings': completedMeetings.docs.length,
        'cancelledMeetings': cancelledMeetings.docs.length,
      };
    } catch (e) {
      print('MeetingService: Error getting meeting stats - $e');
      return {};
    }
  }

  // Create recurring meeting
  static Future<List<String>> createRecurringMeeting({
    required String title,
    required String description,
    required DateTime startDate,
    required int numberOfOccurrences,
    required int intervalDays,
    required String organizerId,
    required String organizerName,
    List<String>? attendeeIds,
    String? meetingType,
    String? googleMeetUrl,
  }) async {
    try {
      final meetingIds = <String>[];

      for (int i = 0; i < numberOfOccurrences; i++) {
        final meetingDate = startDate.add(Duration(days: i * intervalDays));
        final meetingId = await createMeeting(
          title: '$title (${i + 1}/$numberOfOccurrences)',
          description: description,
          scheduledDate: meetingDate,
          organizerId: organizerId,
          organizerName: organizerName,
          attendeeIds: attendeeIds,
          meetingType: meetingType,
          googleMeetUrl: googleMeetUrl,
        );
        meetingIds.add(meetingId);
      }

      print('MeetingService: Created $numberOfOccurrences recurring meetings');
      return meetingIds;
    } catch (e) {
      throw Exception('Failed to create recurring meetings: $e');
    }
  }
}
