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


  // Get all meetings (excluding archived ones from active view)
  static Future<List<MeetingModel>> getAllMeetings({bool includeArchived = false}) async {
    try {
      // First try with orderBy, if it fails due to index, fetch without orderBy
      try {
        Query query = _firestore
            .collection(AppConstants.meetingsCollection)
            .orderBy('scheduledDate', descending: false);
        
        // Exclude archived meetings unless explicitly requested
        if (!includeArchived) {
          query = query.where('isArchived', isEqualTo: false);
        }
        
        final meetings = await query.get();

        final result = meetings.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return null;
                // Ensure meetingId is set from document ID if missing
                if (data['meetingId'] == null || data['meetingId'] == '') {
                  data['meetingId'] = doc.id;
                }
                return MeetingModel.fromMap(data);
              } catch (e) {
                print('MeetingService: Error parsing meeting ${doc.id}: $e');
                return null;
              }
            })
            .whereType<MeetingModel>()
            .toList();
        
        // Sort by scheduled date
        result.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
        return result;
      } catch (e) {
        // If orderBy fails, try without it and sort in memory
        print('MeetingService: orderBy query failed, trying without orderBy: $e');
        Query query = _firestore.collection(AppConstants.meetingsCollection);
        
        // Exclude archived meetings unless explicitly requested
        if (!includeArchived) {
          query = query.where('isArchived', isEqualTo: false);
        }
        
        final meetings = await query.get();

        final result = meetings.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return null;
                // Ensure meetingId is set from document ID if missing
                if (data['meetingId'] == null || data['meetingId'] == '') {
                  data['meetingId'] = doc.id;
                }
                return MeetingModel.fromMap(data);
              } catch (e) {
                print('MeetingService: Error parsing meeting ${doc.id}: $e');
                return null;
              }
            })
            .whereType<MeetingModel>()
            .toList();
        
        // Sort by scheduled date in memory
        result.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
        return result;
      }
    } catch (e) {
      print('MeetingService: Error getting meetings - $e');
      rethrow;
    }
  }

  // Get user's meetings (includes meetings where user is organizer or attendee)
  static Future<List<MeetingModel>> getUserMeetings(String userId, {bool includeArchived = false}) async {
    try {
      // Get meetings where user is an attendee
      QuerySnapshot attendeeMeetings;
      try {
        Query attendeeQuery = _firestore
            .collection(AppConstants.meetingsCollection)
            .where('attendeeIds', arrayContains: userId);
        
        if (!includeArchived) {
          attendeeQuery = attendeeQuery.where('isArchived', isEqualTo: false);
        }
        
        attendeeMeetings = await attendeeQuery
            .orderBy('scheduledDate', descending: false)
            .get();
      } catch (e) {
        // If orderBy fails, try without it
        print('MeetingService: attendee query orderBy failed, trying without: $e');
        Query attendeeQuery = _firestore
            .collection(AppConstants.meetingsCollection)
            .where('attendeeIds', arrayContains: userId);
        
        if (!includeArchived) {
          attendeeQuery = attendeeQuery.where('isArchived', isEqualTo: false);
        }
        
        attendeeMeetings = await attendeeQuery.get();
      }

      // Get meetings where user is the organizer
      QuerySnapshot organizerMeetings;
      try {
        Query organizerQuery = _firestore
            .collection(AppConstants.meetingsCollection)
            .where('organizerId', isEqualTo: userId);
        
        if (!includeArchived) {
          organizerQuery = organizerQuery.where('isArchived', isEqualTo: false);
        }
        
        organizerMeetings = await organizerQuery
            .orderBy('scheduledDate', descending: false)
            .get();
      } catch (e) {
        // If orderBy fails, try without it
        print('MeetingService: organizer query orderBy failed, trying without: $e');
        Query organizerQuery = _firestore
            .collection(AppConstants.meetingsCollection)
            .where('organizerId', isEqualTo: userId);
        
        if (!includeArchived) {
          organizerQuery = organizerQuery.where('isArchived', isEqualTo: false);
        }
        
        organizerMeetings = await organizerQuery.get();
      }

      // Combine and deduplicate
      final allMeetingIds = <String>{};
      final allMeetings = <MeetingModel>[];

      for (final doc in attendeeMeetings.docs) {
        if (!allMeetingIds.contains(doc.id)) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            // Ensure meetingId is set from document ID if missing
            if (data['meetingId'] == null || data['meetingId'] == '') {
              data['meetingId'] = doc.id;
            }
            final meeting = MeetingModel.fromMap(data);
            allMeetings.add(meeting);
            allMeetingIds.add(doc.id);
          } catch (e) {
            print('MeetingService: Error parsing attendee meeting ${doc.id}: $e');
          }
        }
      }

      for (final doc in organizerMeetings.docs) {
        if (!allMeetingIds.contains(doc.id)) {
          try {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            // Ensure meetingId is set from document ID if missing
            if (data['meetingId'] == null || data['meetingId'] == '') {
              data['meetingId'] = doc.id;
            }
            final meeting = MeetingModel.fromMap(data);
            allMeetings.add(meeting);
            allMeetingIds.add(doc.id);
          } catch (e) {
            print('MeetingService: Error parsing organizer meeting ${doc.id}: $e');
          }
        }
      }

      // Sort by scheduled date
      allMeetings.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

      return allMeetings;
    } catch (e) {
      print('MeetingService: Error getting user meetings - $e');
      rethrow;
    }
  }

  // Get upcoming meetings (excludes archived)
  static Future<List<MeetingModel>> getUpcomingMeetings() async {
    try {
      final now = DateTime.now();
      QuerySnapshot meetings;
      
      try {
        // Try with compound query first
        meetings = await _firestore
            .collection(AppConstants.meetingsCollection)
            .where('isArchived', isEqualTo: false)
            .where('scheduledDate', isGreaterThan: Timestamp.fromDate(now))
            .where('status', isEqualTo: AppConstants.meetingScheduled)
            .orderBy('scheduledDate', descending: false)
            .get();
      } catch (e) {
        // If compound query fails, fetch all and filter in memory
        print('MeetingService: compound query failed, fetching all: $e');
        final allMeetings = await _firestore
            .collection(AppConstants.meetingsCollection)
            .where('isArchived', isEqualTo: false)
            .get();
        
        // Filter in memory
        final filtered = allMeetings.docs.where((doc) {
          final data = doc.data();
          final scheduledDate = (data['scheduledDate'] as Timestamp?)?.toDate();
          final status = data['status'] as String?;
          final isArchived = data['isArchived'] as bool? ?? false;
          return !isArchived &&
              scheduledDate != null &&
              scheduledDate.isAfter(now) &&
              status == AppConstants.meetingScheduled;
        }).toList();
        
        final result = filtered
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return null;
                if (data['meetingId'] == null || data['meetingId'] == '') {
                  data['meetingId'] = doc.id;
                }
                return MeetingModel.fromMap(data);
              } catch (e) {
                print('MeetingService: Error parsing upcoming meeting ${doc.id}: $e');
                return null;
              }
            })
            .whereType<MeetingModel>()
            .toList();
        
        result.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
        return result;
      }

      final result = meetings.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) return null;
              if (data['meetingId'] == null || data['meetingId'] == '') {
                data['meetingId'] = doc.id;
              }
              return MeetingModel.fromMap(data);
            } catch (e) {
              print('MeetingService: Error parsing upcoming meeting ${doc.id}: $e');
              return null;
            }
          })
          .whereType<MeetingModel>()
          .toList();
      
      // Sort by scheduled date
      result.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      return result;
    } catch (e) {
      print('MeetingService: Error getting upcoming meetings - $e');
      rethrow;
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

  // Delete meeting (archives completed meetings, permanently deletes others)
  static Future<bool> deleteMeeting(String meetingId) async {
    try {
      // Get the meeting first to check its status
      final meetingDoc = await _firestore
          .collection(AppConstants.meetingsCollection)
          .doc(meetingId)
          .get();

      if (!meetingDoc.exists) {
        print('MeetingService: Meeting $meetingId not found');
        return false;
      }

      final meetingData = meetingDoc.data();
      if (meetingData == null) {
        print('MeetingService: Meeting $meetingId has no data');
        return false;
      }

      final status = meetingData['status'] as String? ?? '';
      final isCompleted = status == AppConstants.meetingCompleted;
      final scheduledDate = (meetingData['scheduledDate'] as Timestamp?)?.toDate();
      final isPast = scheduledDate != null && scheduledDate.isBefore(DateTime.now());

      // If meeting is completed or past, archive it instead of deleting
      if (isCompleted || (isPast && status == AppConstants.meetingScheduled)) {
        await _firestore
            .collection(AppConstants.meetingsCollection)
            .doc(meetingId)
            .update({
              'isArchived': true,
              'archivedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        print('MeetingService: Archived meeting $meetingId (completed/past meeting)');
      } else {
        // For non-completed meetings, permanently delete
        await _firestore
            .collection(AppConstants.meetingsCollection)
            .doc(meetingId)
            .delete();

        print('MeetingService: Permanently deleted meeting $meetingId');
      }

      return true;
    } catch (e) {
      print('MeetingService: Error deleting meeting - $e');
      return false;
    }
  }

  // Get archived meetings (for history)
  static Future<List<MeetingModel>> getArchivedMeetings() async {
    try {
      final meetings = await _firestore
          .collection(AppConstants.meetingsCollection)
          .where('isArchived', isEqualTo: true)
          .orderBy('scheduledDate', descending: true)
          .get();

      final result = meetings.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) return null;
              if (data['meetingId'] == null || data['meetingId'] == '') {
                data['meetingId'] = doc.id;
              }
              return MeetingModel.fromMap(data);
            } catch (e) {
              print('MeetingService: Error parsing archived meeting ${doc.id}: $e');
              return null;
            }
          })
          .whereType<MeetingModel>()
          .toList();

      return result;
    } catch (e) {
      print('MeetingService: Error getting archived meetings - $e');
      // If orderBy fails, fetch without it
      try {
        final meetings = await _firestore
            .collection(AppConstants.meetingsCollection)
            .where('isArchived', isEqualTo: true)
            .get();

        final result = meetings.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return null;
                if (data['meetingId'] == null || data['meetingId'] == '') {
                  data['meetingId'] = doc.id;
                }
                return MeetingModel.fromMap(data);
              } catch (e) {
                print('MeetingService: Error parsing archived meeting ${doc.id}: $e');
                return null;
              }
            })
            .whereType<MeetingModel>()
            .toList();

        // Sort by scheduled date descending
        result.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
        return result;
      } catch (e2) {
        print('MeetingService: Error getting archived meetings (fallback) - $e2');
        return [];
      }
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
