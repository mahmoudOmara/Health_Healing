import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:health_healing/models/health_issue.dart';
import 'package:health_healing/models/health_issue_update.dart';
// Assuming firebase_auth is used for userId
import 'package:firebase_auth/firebase_auth.dart';

class HealthIssueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference _healthIssuesCollection;

  HealthIssueService() {
    _healthIssuesCollection = _firestore.collection('health_issues');
  }

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Add a new health issue
  Future<String?> addHealthIssue(HealthIssue issue) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }
    try {
      // Create a mutable copy of the map to set/override userId
      Map<String, dynamic> issueData = issue.toFirestore();
      issueData['userId'] = _currentUserId; // Ensure current user's ID is set

      DocumentReference docRef = await _healthIssuesCollection.add(issueData);
      return docRef.id;
    } catch (e) {
      print("Error adding health issue: $e");
      return null;
    }
  }

  // Get all health issues for the current user (real-time stream)
  Stream<List<HealthIssue>> getHealthIssues() {
    if (_currentUserId == null) {
      return Stream.value([]); // Return empty stream if user not logged in
    }
    return _healthIssuesCollection
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HealthIssue.fromFirestore(doc))
          .toList();
    });
  }

  // Update an existing health issue
  Future<void> updateHealthIssue(HealthIssue issue) async {
    if (issue.id == null) {
      throw Exception("Issue ID cannot be null for update");
    }
    if (_currentUserId == null ) { // Removed issue.userId check as it might not be populated from client if not careful
        throw Exception("User not logged in");
    }
    try {
      // Fetch the document first to ensure it belongs to the user
      DocumentSnapshot docSnapshot = await _healthIssuesCollection.doc(issue.id).get();
      if (!docSnapshot.exists || (docSnapshot.data() as Map<String, dynamic>)['userId'] != _currentUserId) {
          throw Exception("User not authorized to update this issue or issue does not exist");
      }

      // Ensure updatedAt is set and userId is correct
      Map<String, dynamic> issueData = issue.toFirestore();
      issueData['updatedAt'] = Timestamp.now();
      issueData['userId'] = _currentUserId; // Re-affirm userId for security

      await _healthIssuesCollection.doc(issue.id).update(issueData);
    } catch (e) {
      print("Error updating health issue: $e");
      rethrow;
    }
  }

  // Add an update/log to a health issue
  Future<void> addHealthIssueUpdate(
      String issueId, HealthIssueUpdate update) async {
    if (_currentUserId == null) {
        throw Exception("User not logged in");
    }
    try {
      // First, verify the main issue belongs to the current user before adding an update
      DocumentSnapshot issueDoc = await _healthIssuesCollection.doc(issueId).get();
      if (!issueDoc.exists || (issueDoc.data() as Map<String, dynamic>)['userId'] != _currentUserId) {
          throw Exception("User not authorized to update this issue or issue does not exist");
      }

      await _healthIssuesCollection
          .doc(issueId)
          .collection('issue_updates')
          .add(update.toFirestore());
      // Also update the 'updatedAt' timestamp of the main health issue
      await _healthIssuesCollection.doc(issueId).update({'updatedAt': Timestamp.now()});
    } catch (e) {
      print("Error adding health issue update: $e");
      rethrow;
    }
  }

  // Get updates for a specific health issue (real-time stream)
  Stream<List<HealthIssueUpdate>> getHealthIssueUpdates(String issueId) {
     if (_currentUserId == null) {
      return Stream.value([]);
    }
    return _healthIssuesCollection
        .doc(issueId)
        .collection('issue_updates')
        .orderBy('updateDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HealthIssueUpdate.fromFirestore(doc))
          .toList();
    });
  }

  // Upload a file to Firebase Storage
  Future<Map<String, String>?> uploadFile(File file, String path) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }
    try {
      String fileName = file.path.split('/').last;
      String fullPath = 'user_uploads/$_currentUserId/$path/$fileName'; // User-specific path
      Reference storageRef = _storage.ref().child(fullPath);
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();
      return {'fileName': fileName, 'downloadURL': downloadURL};
    } catch (e) {
      print("Error uploading file: $e");
      return null;
    }
  }

  // Delete a health issue (Optional, implement if needed later)
  // Future<void> deleteHealthIssue(String issueId) async {
  //   if (_currentUserId == null) {
  //       throw Exception("User not logged in");
  //   }
  //   try {
  //     // Add security check: ensure the issue belongs to the current user
  //     DocumentSnapshot issueDoc = await _healthIssuesCollection.doc(issueId).get();
  //     if (!issueDoc.exists || (issueDoc.data() as Map<String, dynamic>)['userId'] != _currentUserId) {
  //         throw Exception("User not authorized to delete this issue or issue does not exist");
  //     }
  //     // Note: Deleting a document does not automatically delete its subcollections.
  //     // If issue_updates need to be deleted, it requires a separate process (e.g., a cloud function).
  //     await _healthIssuesCollection.doc(issueId).delete();
  //   } catch (e) {
  //     print("Error deleting health issue: $e");
  //     rethrow;
  //   }
  // }
}

