import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:iiuc_bazaar/Navigation/Buttom_Nav_Bar.dart';

class LoginController extends GetxController {
  // Firebase authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observables to track state
  var email = ''.obs;
  var password = ''.obs;
  var errorMessage = ''.obs;
  var isLoading = false.obs;

  // Email validation
  bool validateEmail(String email) {
    if (email.isEmpty) {
      errorMessage.value = "Email cannot be empty";
      return false;
    } else if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      errorMessage.value = "Invalid email format";
      return false;
    }
    errorMessage.value = "";
    return true;
  }

  // Password validation
  bool validatePassword(String password) {
    if (password.isEmpty) {
      errorMessage.value = "Password cannot be empty";
      return false;
    }
    errorMessage.value = "";
    return true;
  }

  // Login function
  Future<void> loginUser() async {
    if (validateEmail(email.value) && validatePassword(password.value)) {
      isLoading.value = true;
      try {
        // Sign in the user
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email.value,
          password: password.value,
        );

        // Check if the user is authenticated and if their email is verified
        if (userCredential.user != null && userCredential.user!.emailVerified) {
          // Update emailVerified field in Firestore
          await updateEmailVerificationStatus();

          // Navigate to profile screen after successful login
          Get.offAllNamed('/profile'); // This will navigate to the Profile screen
          Get.offAll(() => const MyBottomNavBar(), arguments: 3); // Pass the tab index (3 for Profile tab)
        } else {
          // If the email is not verified
          errorMessage.value = "Please verify your email before logging in.";
          await _auth.signOut(); // Optionally sign out the user
        }
      } on FirebaseAuthException catch (e) {
        errorMessage.value = e.message ?? "Login failed";
      } finally {
        isLoading.value = false;
      }
    }
  }

  // Update email verification status in Firestore
  Future<void> updateEmailVerificationStatus() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user != null) {
      // Ensure the latest info is fetched
      await user.reload();
      user = auth.currentUser;

      if (user != null && user.emailVerified) {
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        try {
          // Update the user's emailVerified status in Firestore
          await firestore.collection('users').doc(user.uid).update({
            'emailVerified': true,
          });
          print('Email verification status updated in Firestore.');
        } catch (e) {
          print('Error updating Firestore: $e');
        }
      }
    }
  }
}
