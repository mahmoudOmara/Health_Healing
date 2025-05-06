import 'package:cloud_firestore/cloud_firestore.dart';

class HealthIssue {
  final String? id;
  final String userId;
  final String issueName;
  final Timestamp startDate;
  final String severityLevel;
  String status;
  final String? symptoms;
  final String? medications;
  final String? doctorClinic;
  final bool isRecurring;
  final Timestamp? nextFollowUpDate;
  final List<Map<String, String>>? fileUploads; // { "fileName": "...", "downloadURL": "..." }
  final Timestamp createdAt;
  Timestamp updatedAt;

  HealthIssue({
    this.id,
    required this.userId,
    required this.issueName,
    required this.startDate,
    required this.severityLevel,
    this.status = 'Active', // Default status
    this.symptoms,
    this.medications,
    this.doctorClinic,
    this.isRecurring = false, // Default value
    this.nextFollowUpDate,
    this.fileUploads,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HealthIssue.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HealthIssue(
      id: doc.id,
      userId: data['userId'] ?? '',
      issueName: data['issueName'] ?? '',
      startDate: data['startDate'] ?? Timestamp.now(),
      severityLevel: data['severityLevel'] ?? '',
      status: data['status'] ?? 'Active',
      symptoms: data['symptoms'],
      medications: data['medications'],
      doctorClinic: data['doctorClinic'],
      isRecurring: data['isRecurring'] ?? false,
      nextFollowUpDate: data['nextFollowUpDate'],
      fileUploads: (data['fileUploads'] as List<dynamic>?)
          ?.map((file) => Map<String, String>.from(file as Map))
          .toList(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'issueName': issueName,
      'startDate': startDate,
      'severityLevel': severityLevel,
      'status': status,
      if (symptoms != null) 'symptoms': symptoms,
      if (medications != null) 'medications': medications,
      if (doctorClinic != null) 'doctorClinic': doctorClinic,
      'isRecurring': isRecurring,
      if (nextFollowUpDate != null) 'nextFollowUpDate': nextFollowUpDate,
      if (fileUploads != null) 'fileUploads': fileUploads,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

