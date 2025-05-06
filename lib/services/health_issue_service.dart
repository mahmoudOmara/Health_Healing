import 'dart:io';

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_storage/firebase_storage.dart";
import "package:health_healing/models/health_issue.dart";
import "package:health_healing/models/health_issue_update.dart";
import "package:firebase_auth/firebase_auth.dart";

class HealthIssueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference _healthIssuesCollection;

  HealthIssueService() {
    _healthIssuesCollection = _firestore.collection("health_issues");
  }

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<String?> addHealthIssue(HealthIssue issue) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }
    try {
      Map<String, dynamic> issueData = issue.toFirestore();
      issueData["userId"] = _currentUserId;
      DocumentReference docRef = await _healthIssuesCollection.add(issueData);
      return docRef.id;
    } catch (e) {
      print("Error adding health issue: $e");
      return null;
    }
  }

  Stream<List<HealthIssue>> getHealthIssues() {
    if (_currentUserId == null) {
      return Stream.value([]);
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

  Stream<HealthIssue> getHealthIssueStream(String issueId) {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }
    return _healthIssuesCollection.doc(issueId).snapshots().map((doc) {
      if (!doc.exists || (doc.data() as Map<String, dynamic>)["userId"] != _currentUserId) {
        throw Exception("Issue not found or not authorized");
      }
      return HealthIssue.fromFirestore(doc);
    });
  }

  Future<void> updateHealthIssue(HealthIssue issue) async {
    if (issue.id == null) {
      throw Exception("Issue ID cannot be null for update");
    }
    if (_currentUserId == null) {
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

  Future<void> addHealthIssueUpdate(String issueId, HealthIssueUpdate update) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in or userId not provided");
    }
    try {
      DocumentSnapshot issueDoc = await _healthIssuesCollection.doc(issueId).get();
      if (!issueDoc.exists || (issueDoc.data() as Map<String, dynamic>)["userId"] != _currentUserId) {
        throw Exception("User not authorized to update this issue or issue does not exist");
      }
      Map<String, dynamic> updateData = update.toFirestore();
      updateData["userId"] = _currentUserId; // Ensure update is associated with the user

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

  // Renamed from getHealthIssueUpdates to match usage in detail screen
  Stream<List<HealthIssueUpdate>> getIssueUpdatesStream(String issueId) {
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

  // Signature: File file, String issueId, String description, String originalFileName
  Future<Map<String, String>> uploadFileWithDescription(File file, String issueId, String description, String originalFileName) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }
    if (issueId.isEmpty) {
      throw Exception("Issue ID cannot be empty for file upload");
    }
    try {
      String storagePath = "user_uploads/$_currentUserId/health_issues/$issueId/$originalFileName";
      Reference storageRef = _storage.ref().child(storagePath);
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();
      
      // Create file metadata to store in Firestore
      Map<String, String> fileMetadata = {
        "fileId": storageRef.name, // Using storage ref name as a unique ID for the file within this issue
        "fileName": originalFileName,
        "downloadURL": downloadURL,
        "description": description,
        "uploadedAt": Timestamp.now().millisecondsSinceEpoch.toString(), // Storing as string for simplicity, or use Timestamp
        "storagePath": storagePath // Store the path for deletion
      };

      // Add file metadata to the health issue document in Firestore
      await _healthIssuesCollection.doc(issueId).update({
        "fileUploads": FieldValue.arrayUnion([fileMetadata]),
        "updatedAt": Timestamp.now(),
      });

      return fileMetadata; // Return the full metadata including the new fileId
    } catch (e) {
      print("Error uploading file with description to Firebase Storage: $e");
      if (e is FirebaseException) {
        print("Firebase Storage Error Code: ${e.code}");
        print("Firebase Storage Error Message: ${e.message}");
      }
      rethrow;
    }
  }

  // New method to delete a file from storage and Firestore
  Future<void> deleteFileFromIssue(String issueId, Map<String, String> fileData) async {
    if (_currentUserId == null) {
      throw Exception("User not logged in");
    }
    if (issueId.isEmpty) {
      throw Exception("Issue ID cannot be empty");
    }
    if (fileData['storagePath'] == null || fileData['storagePath']!.isEmpty) {
        throw Exception("Storage path is missing in file data, cannot delete from storage.");
    }

    try {
      // 1. Delete from Firebase Storage
      Reference storageRef = _storage.ref().child(fileData['storagePath']!);
      await storageRef.delete();

      // 2. Remove from Firestore array in HealthIssue document
      // We need to use the fileId or a unique identifier stored in fileData to remove it accurately.
      // Assuming fileData contains a unique 'fileId' that was generated during upload.
      if (fileData['fileId'] == null || fileData['fileId']!.isEmpty) {
          throw Exception("File ID is missing, cannot reliably remove from Firestore.");
      }

      await _healthIssuesCollection.doc(issueId).update({
        "fileUploads": FieldValue.arrayRemove([fileData]), // This removes based on exact map match
        "updatedAt": Timestamp.now(),
      });

    } catch (e) {
      print("Error deleting file: $e");
      if (e is FirebaseException && e.code == 'object-not-found') {
        // If file not found in storage, it might have been already deleted or path is wrong.
        // Proceed to attempt removal from Firestore if that's desired behavior.
        print("File not found in Storage, attempting to remove from Firestore metadata.");
         await _healthIssuesCollection.doc(issueId).update({
            "fileUploads": FieldValue.arrayRemove([fileData]),
            "updatedAt": Timestamp.now(),
        }).catchError((fsError) {
            print("Error removing file metadata from Firestore after storage deletion failed: $fsError");
            // Decide if to rethrow fsError or the original storage error
        });
      }
      rethrow;
    }
  }
}

