import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../MVVM/Models/UserModel.dart';

class SignUpController extends GetxController {
  // Reactive variables for the form fields
  var name = ''.obs;
  var email = ''.obs;
  var mobileNumber = ''.obs;
  var password = ''.obs;

  // Reactive variable for userType
  var userType = 'Buyer'.obs; // Default value set to 'Buyer'

  // Method to set the userType
  void setUserType(String type) {
    userType.value = type;
  }

  // Method to set the name
  void setName(String value) {
    name.value = value;
  }

  // Method to set the email
  void setEmail(String value) {
    email.value = value;
  }

  // Method to set the mobile number
  void setMobileNumber(String value) {
    mobileNumber.value = value;
  }

  // Method to set the password
  void setPassword(String value) {
    password.value = value;
  }

  // Register user method to create the user in Firebase
  Future<bool> registerUser(String email, String password) async {
    try {
      // Register the user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the user object
      User? user = userCredential.user;

      // If user is created successfully
      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        // Add the user to Firestore after registration
        UserModel userModel = UserModel(
          uid: user.uid,
          name: name.value,
          email: user.email ?? '',
          mobileNumber: mobileNumber.value,
          userType: userType.value, // Save the userType
        );

        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userModel.toMap());

        // Successfully registered and verification email sent
        return true;
      }

      return false;
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  // Post sign-up details method (optional, based on your original code)
  Future<void> postSignUpDetails() async {
    // Any additional post sign-up actions (if needed)
  }
}
