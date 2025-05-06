import 'dart:io';

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_storage/firebase_storage.dart";
import "package:health_healing/models/health_issue.dart";
import "package:health_healing/models/health_issue_update.dart";
import "package:firebase_auth/firebase_auth.dart";
import 'package:intl/intl.dart'; // Added for date formatting in logs
import 'package:mime_type/mime_type.dart'; // Added for MIME type detection
import 'package:path/path.dart' as p; // Added for getting file extension for MIME type

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

      HealthIssue oldIssue = HealthIssue.fromFirestore(docSnapshot);
      Timestamp? oldFollowUpDate = oldIssue.nextFollowUpDate;

      Map<String, dynamic> issueData = issue.toFirestore();
      issueData["updatedAt"] = Timestamp.now();
      issueData["userId"] = _currentUserId;
      await _healthIssuesCollection.doc(issue.id!).update(issueData);

      // Log follow-up date change
      if (issue.nextFollowUpDate != oldFollowUpDate) {
        String logText;
        if (issue.nextFollowUpDate != null) {
          String formattedDate = DateFormat('MMM d, yyyy HH:mm').format(issue.nextFollowUpDate!.toDate());
          if (oldFollowUpDate == null) {
            logText = "Follow-up scheduled for: $formattedDate";
          } else {
            logText = "Follow-up updated to: $formattedDate";
          }
        } else {
          logText = "Follow-up cancelled"; 
        }
        HealthIssueUpdate followUpLog = HealthIssueUpdate(
          updateText: logText,
          updateDate: Timestamp.now(),
        );
        await addHealthIssueUpdate(issue.id!, followUpLog);
      }
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
      updateData["userId"] = _currentUserId; 

      await _healthIssuesCollection
          .doc(issueId)
          .collection("issue_updates")
          .add(updateData);
    } catch (e) {
      print("Error adding health issue update: $e");
      rethrow;
    }
  }

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

      String? mimeType = mime(p.basename(file.path));
      final metadata = SettableMetadata(contentType: mimeType ?? "application/octet-stream");

      UploadTask uploadTask = storageRef.putFile(file, metadata);
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();
      
      Map<String, String> fileMetadata = {
        "fileId": storageRef.name,
        "fileName": originalFileName,
        "downloadURL": downloadURL,
        "description": description,
        "uploadedAt": Timestamp.now().millisecondsSinceEpoch.toString(),
        "storagePath": storagePath,
        "mimeType": mimeType ?? "application/octet-stream"
      };

      await _healthIssuesCollection.doc(issueId).update({
        "fileUploads": FieldValue.arrayUnion([fileMetadata]),
        "updatedAt": Timestamp.now(),
      });

      String logText = "File Uploaded: $originalFileName";
      if (description.isNotEmpty) {
        logText += " - Description: $description";
      }
      HealthIssueUpdate fileLogUpdate = HealthIssueUpdate(
        updateText: logText,
        updateDate: Timestamp.now(),
      );
      await addHealthIssueUpdate(issueId, fileLogUpdate);

      return fileMetadata;
    } catch (e) {
      print("Error uploading file with description to Firebase Storage: $e");
      if (e is FirebaseException) {
        print("Firebase Storage Error Code: ${e.code}");
        print("Firebase Storage Error Message: ${e.message}");
      }
      rethrow;
    }
  }

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
      Reference storageRef = _storage.ref().child(fileData['storagePath']!);
      await storageRef.delete();

      if (fileData['fileId'] == null || fileData['fileId']!.isEmpty) {
          throw Exception("File ID is missing, cannot reliably remove from Firestore.");
      }

      await _healthIssuesCollection.doc(issueId).update({
        "fileUploads": FieldValue.arrayRemove([fileData]),
        "updatedAt": Timestamp.now(),
      });
      
      String logText = "File Deleted: ${fileData['fileName'] ?? 'Unknown file'}";
      HealthIssueUpdate deleteLogUpdate = HealthIssueUpdate(
        updateText: logText,
        updateDate: Timestamp.now(),
      );
      await addHealthIssueUpdate(issueId, deleteLogUpdate);

    } catch (e) {
      print("Error deleting file: $e");
      if (e is FirebaseException && e.code == 'object-not-found') {
        print("File not found in Storage, attempting to remove from Firestore metadata.");
         await _healthIssuesCollection.doc(issueId).update({
            "fileUploads": FieldValue.arrayRemove([fileData]),
            "updatedAt": Timestamp.now(),
        }).catchError((fsError) {
            print("Error removing file metadata from Firestore after storage deletion failed: $fsError");
        });
      }
      rethrow;
    }
  }

  Future<void> addOrUpdateReminder(String issueId, String reminderDetails, {bool isUpdate = false}) async {
    String logText = isUpdate ? "Reminder updated: $reminderDetails" : "Reminder set: $reminderDetails";
    HealthIssueUpdate reminderLog = HealthIssueUpdate(
      updateText: logText,
      updateDate: Timestamp.now(),
    );
    await addHealthIssueUpdate(issueId, reminderLog);
    await _healthIssuesCollection.doc(issueId).update({"updatedAt": Timestamp.now()});
  }

}

