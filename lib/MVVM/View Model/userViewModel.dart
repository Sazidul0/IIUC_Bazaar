// user_view_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/userModel.dart';


class UserViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user data to Firestore
  Future<void> saveUserData(UserModel user) async {
    try {
      // Store user data in the 'users' collection
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception("Error saving user data: $e");
    }
  }

  // Fetch user data by UID (if needed)
  Future<UserModel?> fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception("Error fetching user data: $e");
    }
  }
}
