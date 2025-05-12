import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_healing/models/calendar_event.dart';
import 'package:health_healing/models/health_issue.dart'; // Assuming HealthIssue model exists

class CalendarEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  // Firestore collection reference
  CollectionReference<CalendarEvent> _calendarEventsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('calendarEvents')
        .withConverter<CalendarEvent>(
          fromFirestore: (snapshots, _) => CalendarEvent.fromMap(snapshots.data()!, snapshots.id),
          toFirestore: (event, _) => event.toMap(),
        );
  }

  // Simpler collection reference for health issues (assuming it's at a similar path)
  CollectionReference<HealthIssue> _healthIssuesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('health_issues') // Or your actual health issues collection name
        .withConverter<HealthIssue>(
          fromFirestore: (snapshots, _) => HealthIssue.fromMap(snapshots.data()!, snapshots.id),
          toFirestore: (issue, _) => issue.toMap(),
        );
  }

  // Add a new calendar event
  Future<void> addCalendarEvent(CalendarEvent event) async {
    if (_currentUser == null) throw Exception('User not logged in');
    try {
      await _calendarEventsCollection(_currentUser!.uid).doc(event.eventId).set(event);
    } catch (e) {
      print('Error adding calendar event: $e');
      rethrow;
    }
  }

  // Update an existing calendar event (e.g., mark as done)
  Future<void> updateCalendarEvent(CalendarEvent event) async {
    if (_currentUser == null) throw Exception('User not logged in');
    try {
      await _calendarEventsCollection(_currentUser!.uid).doc(event.eventId).update(event.toMap());
    } catch (e) {
      print('Error updating calendar event: $e');
      rethrow;
    }
  }

  // Delete a calendar event
  Future<void> deleteCalendarEvent(String eventId) async {
    if (_currentUser == null) throw Exception('User not logged in');
    try {
      await _calendarEventsCollection(_currentUser!.uid).doc(eventId).delete();
    } catch (e) {
      print('Error deleting calendar event: $e');
      rethrow;
    }
  }

  // Get calendar events for a specific day
  Stream<List<CalendarEvent>> getCalendarEventsForDay(DateTime date) {
    if (_currentUser == null) return Stream.value([]);
    
    Timestamp startOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 0, 0, 0));
    Timestamp endOfDay = Timestamp.fromDate(DateTime(date.year, date.month, date.day, 23, 59, 59));

    return _calendarEventsCollection(_currentUser!.uid)
        .where('eventDate', isGreaterThanOrEqualTo: startOfDay)
        .where('eventDate', isLessThanOrEqualTo: endOfDay)
        .orderBy('eventDate')
        .orderBy('eventTime') // Optional: if you want to sort by time within the day
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get calendar events for a specific month (useful for marking calendar days)
  Stream<List<CalendarEvent>> getCalendarEventsForMonth(DateTime month) {
    if (_currentUser == null) return Stream.value([]);
    
    DateTime firstDayOfMonth = DateTime(month.year, month.month, 1);
    DateTime lastDayOfMonth = DateTime(month.year, month.month + 1, 0); // 0th day of next month is last day of current

    Timestamp startOfMonth = Timestamp.fromDate(firstDayOfMonth);
    Timestamp endOfMonth = Timestamp.fromDate(lastDayOfMonth.add(Duration(days: 1))); // exclusive end

    return _calendarEventsCollection(_currentUser!.uid)
        .where('eventDate', isGreaterThanOrEqualTo: startOfMonth)
        .where('eventDate', isLessThan: endOfMonth) // Use isLessThan for exclusive end
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get all calendar events linked to a specific health issue
  Stream<List<CalendarEvent>> getCalendarEventsForIssue(String healthIssueId) {
    if (_currentUser == null) return Stream.value([]);
    return _calendarEventsCollection(_currentUser!.uid)
        .where('healthIssueId', isEqualTo: healthIssueId)
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get all health issues for the current user (to populate dropdown)
  Future<List<HealthIssue>> getAllHealthIssues() async {
    if (_currentUser == null) throw Exception('User not logged in');
    try {
      final snapshot = await _healthIssuesCollection(_currentUser!.uid).orderBy('name').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching health issues: $e');
      rethrow;
    }
  }
}

