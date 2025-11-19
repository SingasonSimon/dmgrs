import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingModel {
  final String meetingId;
  final String title;
  final String description;
  final DateTime scheduledDate;
  final String organizerId;
  final String organizerName;
  final List<String> attendeeIds;
  final String meetingType;
  final String status;
  final String googleMeetUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? notes;
  final bool isArchived;
  final DateTime? archivedAt;

  MeetingModel({
    required this.meetingId,
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.organizerId,
    required this.organizerName,
    required this.attendeeIds,
    required this.meetingType,
    required this.status,
    required this.googleMeetUrl,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.endedAt,
    this.notes,
    this.isArchived = false,
    this.archivedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'meetingId': meetingId,
      'title': title,
      'description': description,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'organizerId': organizerId,
      'organizerName': organizerName,
      'attendeeIds': attendeeIds,
      'meetingType': meetingType,
      'status': status,
      'googleMeetUrl': googleMeetUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'notes': notes,
      'isArchived': isArchived,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
    };
  }

  // Create from Map (from Firestore)
  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    // Validate required fields
    final meetingId = map['meetingId']?.toString() ?? '';
    if (meetingId.isEmpty) {
      throw Exception('MeetingModel: meetingId is required');
    }
    
    final scheduledDate = (map['scheduledDate'] as Timestamp?)?.toDate();
    if (scheduledDate == null) {
      throw Exception('MeetingModel: scheduledDate is required');
    }
    
    return MeetingModel(
      meetingId: meetingId,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      scheduledDate: scheduledDate,
      organizerId: map['organizerId']?.toString() ?? '',
      organizerName: map['organizerName']?.toString() ?? '',
      attendeeIds: List<String>.from(map['attendeeIds'] ?? []),
      meetingType: map['meetingType']?.toString() ?? 'general',
      status: map['status']?.toString() ?? 'scheduled',
      googleMeetUrl: map['googleMeetUrl']?.toString() ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
      notes: map['notes']?.toString(),
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: (map['archivedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Copy with method
  MeetingModel copyWith({
    String? meetingId,
    String? title,
    String? description,
    DateTime? scheduledDate,
    String? organizerId,
    String? organizerName,
    List<String>? attendeeIds,
    String? meetingType,
    String? status,
    String? googleMeetUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? endedAt,
    String? notes,
    bool? isArchived,
    DateTime? archivedAt,
  }) {
    return MeetingModel(
      meetingId: meetingId ?? this.meetingId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      meetingType: meetingType ?? this.meetingType,
      status: status ?? this.status,
      googleMeetUrl: googleMeetUrl ?? this.googleMeetUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  // Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case 'scheduled':
        return 'blue';
      case 'in_progress':
        return 'green';
      case 'completed':
        return 'gray';
      case 'cancelled':
        return 'red';
      default:
        return 'gray';
    }
  }

  // Check if meeting is upcoming
  bool get isUpcoming {
    return DateTime.now().isBefore(scheduledDate) && status == 'scheduled';
  }

  // Check if meeting is today
  bool get isToday {
    final now = DateTime.now();
    final meetingDate = scheduledDate;
    return now.year == meetingDate.year &&
        now.month == meetingDate.month &&
        now.day == meetingDate.day;
  }

  // Get meeting duration
  Duration? get duration {
    if (startedAt != null && endedAt != null) {
      return endedAt!.difference(startedAt!);
    }
    return null;
  }

  // Get formatted duration
  String get formattedDuration {
    final dur = duration;
    if (dur == null) return 'N/A';

    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get attendee count
  int get attendeeCount => attendeeIds.length;

  @override
  String toString() {
    return 'MeetingModel(meetingId: $meetingId, title: $title, scheduledDate: $scheduledDate, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeetingModel && other.meetingId == meetingId;
  }

  @override
  int get hashCode => meetingId.hashCode;
}
