import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_healing/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'users';

  // Create or update user document in Firestore
  Future<void> createUserDocumentIfNotExists(User user) async {
    final DocumentReference userDocRef = _firestore.collection(_collectionPath).doc(user.uid);

    // Check if the document already exists
    final DocumentSnapshot userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      // Document doesn't exist, create it
      final newUser = UserModel(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? '', // Get phone number from Firebase Auth user
        createdAt: Timestamp.now(),
        // Initialize other fields as needed (e.g., name, dob can be null initially)
      );

      try {
        await userDocRef.set(newUser.toFirestore());
        print('New user document created in Firestore for UID: ${user.uid}');
      } catch (e) {
        print('Error creating user document in Firestore: $e');
        // Handle error appropriately (e.g., log it, show a message)
        rethrow; // Rethrow to potentially handle it in the UI layer
      }
    } else {
      // Document exists, maybe update last login time or check for missing fields
      print('User document already exists for UID: ${user.uid}');
      // Example: Update last login time (if you add that field to UserModel)
      // await userDocRef.update({'lastLogin': Timestamp.now()});
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection(_collectionPath).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collectionPath).doc(uid).update(data);
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }
}

