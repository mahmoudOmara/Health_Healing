import 'package:cloud_firestore/cloud_firestore.dart';

class HealthIssueUpdate {
  final String? id;
  final String updateText;
  final Timestamp updateDate;
  final List<Map<String, String>>? files; // { "fileName": "...", "downloadURL": "..." }

  HealthIssueUpdate({
    this.id,
    required this.updateText,
    required this.updateDate,
    this.files,
  });

  factory HealthIssueUpdate.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HealthIssueUpdate(
      id: doc.id,
      updateText: data['updateText'] ?? '',
      updateDate: data['updateDate'] ?? Timestamp.now(),
      files: (data['files'] as List<dynamic>?)
          ?.map((file) => Map<String, String>.from(file as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'updateText': updateText,
      'updateDate': updateDate,
      if (files != null) 'files': files,
    };
  }
}

