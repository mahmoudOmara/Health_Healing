import 'dart:io';

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_storage/firebase_storage.dart";
import "package:health_healing/models/health_issue.dart";
import "package:health_healing/models/health_issue_update.dart";
// Assuming firebase_auth is used for userId
import "package:firebase_auth/firebase_auth.dart";

class HealthIssueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference _healthIssuesCollection;

  HealthIssueService() {
    _healthIssuesCollection = _firestore.collection("health_issues");
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
      issueData["userId"] = _currentUserId; // Ensure current user's ID is set

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
        .where("userId", isEqualTo: _currentUserId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HealthIssue.fromFirestore(doc))
          .toList();
    });
  }
  
  // Get a single health issue stream (for refreshing detail screen)
  Stream<HealthIssue> getHealthIssueStream(String issueId) {
     if (_currentUserId == null) {
      throw Exception("User not logged in");
    }
    return _healthIssuesCollection
        .doc(issueId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || (doc.data() as Map<String, dynamic>)["userId"] != _currentUserId) {
            throw Exception("Issue not found or not authorized");
          }
          return HealthIssue.fromFirestore(doc);
        });
  }

  // Update an existing health issue
  Future<void> updateHealthIssue(HealthIssue issue) async {
    if (issue.id == null) {
      throw Exception("Issue ID cannot be null for update");
    }
    if (_currentUserId == null ) { 
        throw Exception("User not logged in");
    }
    try {
      DocumentSnapshot docSnapshot = await _healthIssuesCollection.doc(issue.id!).get();
      if (!docSnapshot.exists || (docSnapshot.data() as Map<String, dynamic>)["userId"] != _currentUserId) {
          throw Exception("User not authorized to update this issue or issue does not exist");
      }

      Map<String, dynamic> issueData = issue.toFirestore();
      issueData["updatedAt"] = Timestamp.now();
      issueData["userId"] = _currentUserId; 

      await _healthIssuesCollection.doc(issue.id!).update(issueData);
    } catch (e) {
      print("Error updating health issue: $e");
      rethrow;
    }
  }

  // Add an update/log to a health issue
  Future<void> addHealthIssueUpdate(
      String issueId, HealthIssueUpdate update, String userId) async { 
    if (userId.isEmpty) { 
        throw Exception("User not logged in or userId not provided");
    }
    try {
      DocumentSnapshot issueDoc = await _healthIssuesCollection.doc(issueId).get();
      if (!issueDoc.exists || (issueDoc.data() as Map<String, dynamic>)["userId"] != userId) {
          throw Exception("User not authorized to update this issue or issue does not exist");
      }
      Map<String, dynamic> updateData = update.toFirestore();
      updateData["userId"] = userId; 

      await _healthIssuesCollection
          .doc(issueId)
          .collection("issue_updates")
          .add(updateData);
      await _healthIssuesCollection.doc(issueId).update({"updatedAt": Timestamp.now()});
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
        .collection("issue_updates")
        .orderBy("updateDate", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HealthIssueUpdate.fromFirestore(doc))
          .toList();
    });
  }

  // Upload a file to Firebase Storage and return its name, URL, and description
  Future<Map<String, String>?> uploadFileWithDescription(File file, String issueId, String description, String originalFileName) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }
    if (issueId.isEmpty) {
      throw Exception("Issue ID cannot be empty for file upload");
    }
    try {
      String storagePath = "user_uploads/$_currentUserId/health_issues/$issueId/$originalFileName";
      Reference storageRef = _storage.ref().child(storagePath);
      
      // Optional: Add metadata if needed, e.g., content type
      // final metadata = SettableMetadata(contentType: "image/jpeg"); // Example for image
      // UploadTask uploadTask = storageRef.putFile(file, metadata);
      UploadTask uploadTask = storageRef.putFile(file);
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();
      return {
        "fileName": originalFileName, 
        "downloadURL": downloadURL,
        "description": description
      };
    } catch (e) {
      print("Error uploading file with description to Firebase Storage: $e");
      // More specific error handling if possible
      if (e is FirebaseException) {
        print("Firebase Storage Error Code: ${e.code}");
        print("Firebase Storage Error Message: ${e.message}");
      }
      rethrow; // Rethrow to allow UI to catch and display message
    }
  }
}

