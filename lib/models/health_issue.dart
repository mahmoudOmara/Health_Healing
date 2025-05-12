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
  final List<Map<String, String>>? fileUploads; // { "fileName": "...", "downloadURL": "...", "description": "...", "fileId": "..."}
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

  // Factory constructor to create a HealthIssue from a DocumentSnapshot
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

  // Method to convert a HealthIssue instance to a Map for Firestore
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

  // Standard fromMap factory constructor
  factory HealthIssue.fromMap(Map<String, dynamic> data, String? documentId) {
    return HealthIssue(
      id: documentId,
      userId: data['userId'] ?? '',
      issueName: data['issueName'] ?? '',
      startDate: data['startDate'] is Timestamp ? data['startDate'] : Timestamp.now(),
      severityLevel: data['severityLevel'] ?? '',
      status: data['status'] ?? 'Active',
      symptoms: data['symptoms'] as String?,
      medications: data['medications'] as String?,
      doctorClinic: data['doctorClinic'] as String?,
      isRecurring: data['isRecurring'] as bool? ?? false,
      nextFollowUpDate: data['nextFollowUpDate'] is Timestamp ? data['nextFollowUpDate'] : null,
      fileUploads: (data['fileUploads'] as List<dynamic>?)
          ?.map((file) => Map<String, String>.from(file as Map))
          .toList(),
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.now(),
      updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'] : Timestamp.now(),
    );
  }

  // Standard toMap method
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'issueName': issueName,
      'startDate': startDate,
      'severityLevel': severityLevel,
      'status': status,
      'symptoms': symptoms,
      'medications': medications,
      'doctorClinic': doctorClinic,
      'isRecurring': isRecurring,
      'nextFollowUpDate': nextFollowUpDate,
      'fileUploads': fileUploads,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // copyWith method
  HealthIssue copyWith({
    String? id,
    String? userId,
    String? issueName,
    Timestamp? startDate,
    String? severityLevel,
    String? status,
    String? symptoms,
    String? medications,
    String? doctorClinic,
    bool? isRecurring,
    Timestamp? nextFollowUpDate,
    List<Map<String, String>>? fileUploads,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return HealthIssue(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      issueName: issueName ?? this.issueName,
      startDate: startDate ?? this.startDate,
      severityLevel: severityLevel ?? this.severityLevel,
      status: status ?? this.status,
      symptoms: symptoms ?? this.symptoms,
      medications: medications ?? this.medications,
      doctorClinic: doctorClinic ?? this.doctorClinic,
      isRecurring: isRecurring ?? this.isRecurring,
      nextFollowUpDate: nextFollowUpDate ?? this.nextFollowUpDate,
      fileUploads: fileUploads ?? this.fileUploads,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

