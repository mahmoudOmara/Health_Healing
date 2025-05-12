import 'package:cloud_firestore/cloud_firestore.dart';

class HealthIssueUpdate {
  final String? id;
  final String updateText;
  final Timestamp timestamp; // Changed from updateDate to timestamp
  final String? updateType; // Added updateType
  final List<Map<String, String>>? files; // { "fileName": "...", "downloadURL": "..." }

  HealthIssueUpdate({
    this.id,
    required this.updateText,
    required this.timestamp, // Changed from updateDate
    this.updateType, // Added
    this.files,
  });

  factory HealthIssueUpdate.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HealthIssueUpdate(
      id: doc.id,
      updateText: data['updateText'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(), // Changed from updateDate
      updateType: data['updateType'] as String?,
      files: (data['files'] as List<dynamic>?)
          ?.map((file) => Map<String, String>.from(file as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'updateText': updateText,
      'timestamp': timestamp, // Changed from updateDate
      if (updateType != null) 'updateType': updateType, // Added
      if (files != null) 'files': files,
    };
  }
}

