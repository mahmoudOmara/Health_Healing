import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String eventId;
  final String healthIssueId;
  final String healthIssueName; // Denormalized for easier display
  final String eventTitle;
  final String? eventDescription;
  final Timestamp eventDate; // Specific day
  final String? eventTime; // e.g., "08:00 AM", "14:30"
  final String eventType; // e.g., "Medication", "Appointment", "Follow-up", "Custom"
  final bool isDone;
  final Timestamp createdAt;
  final String userId;

  CalendarEvent({
    required this.eventId,
    required this.healthIssueId,
    required this.healthIssueName,
    required this.eventTitle,
    this.eventDescription,
    required this.eventDate,
    this.eventTime,
    required this.eventType,
    this.isDone = false,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'healthIssueId': healthIssueId,
      'healthIssueName': healthIssueName,
      'eventTitle': eventTitle,
      'eventDescription': eventDescription,
      'eventDate': eventDate,
      'eventTime': eventTime,
      'eventType': eventType,
      'isDone': isDone,
      'createdAt': createdAt,
      'userId': userId,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map, String documentId) {
    return CalendarEvent(
      eventId: documentId, // Use Firestore document ID as eventId
      healthIssueId: map['healthIssueId'] ?? '',
      healthIssueName: map['healthIssueName'] ?? '',
      eventTitle: map['eventTitle'] ?? '',
      eventDescription: map['eventDescription'],
      eventDate: map['eventDate'] ?? Timestamp.now(),
      eventTime: map['eventTime'],
      eventType: map['eventType'] ?? 'Custom',
      isDone: map['isDone'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      userId: map['userId'] ?? '',
    );
  }

  CalendarEvent copyWith({
    String? eventId,
    String? healthIssueId,
    String? healthIssueName,
    String? eventTitle,
    String? eventDescription,
    Timestamp? eventDate,
    String? eventTime,
    String? eventType,
    bool? isDone,
    Timestamp? createdAt,
    String? userId,
  }) {
    return CalendarEvent(
      eventId: eventId ?? this.eventId,
      healthIssueId: healthIssueId ?? this.healthIssueId,
      healthIssueName: healthIssueName ?? this.healthIssueName,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDescription: eventDescription ?? this.eventDescription,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      eventType: eventType ?? this.eventType,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}

