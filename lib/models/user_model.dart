import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phoneNumber;
  final Timestamp createdAt;
  // Add other fields as needed (e.g., name, dob, profilePicUrl)
  String? name;
  DateTime? dob;
  String? profilePicUrl;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.createdAt,
    this.name,
    this.dob,
    this.profilePicUrl,
  });

  // Factory constructor to create a UserModel from a Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      name: data['name'],
      dob: (data['dob'] as Timestamp?)?.toDate(),
      profilePicUrl: data['profilePicUrl'],
    );
  }

  // Method to convert UserModel to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
      if (name != null) 'name': name,
      if (dob != null) 'dob': Timestamp.fromDate(dob!),
      if (profilePicUrl != null) 'profilePicUrl': profilePicUrl,
      // Do not include uid here as it's the document ID
    };
  }
}

