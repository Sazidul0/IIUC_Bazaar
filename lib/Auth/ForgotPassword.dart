import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:iiuc_bazaar/Auth/LogIn.dart';
import 'package:iiuc_bazaar/Components/my_button.dart'; // Assuming MyButton is defined elsewhere

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (emailController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your email address.");
      return;
    }

    if (!emailController.text.endsWith("@ugrad.iiuc.ac.bd")) {
      Get.snackbar("Error", "Use your university email.\nExample: C201023@ugrad.iiuc.ac.bd");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Send password reset email
      await _auth.sendPasswordResetEmail(email: emailController.text);
      Get.snackbar("Success", "A password reset link has been sent to your email.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle errors
      if (e.code == 'user-not-found') {
        Get.snackbar("Error", "No user found with this email.");
      } else {
        Get.snackbar("Error", "An error occurred: ${e.message}");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Forgot Password",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HexColor("#ffffff"),
          ),
        ),
        backgroundColor: HexColor("#4f4f4f"),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "Enter your registered university email. We'll send a password reset link to your email.",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: HexColor("#8d8d8d"),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // Email Input
                Text("Email", style: GoogleFonts.poppins(fontSize: 16, color: HexColor("#8d8d8d"))),
                const SizedBox(height: 5),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "Your_ID@ugrad.iiuc.ac.bd",
                    fillColor: HexColor("#f0f3f1"),
                    contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    hintStyle: GoogleFonts.poppins(fontSize: 15, color: HexColor("#8d8d8d")),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    filled: true,
                    prefixIcon: Icon(Icons.mail_outline, color: HexColor("#4f4f4f")),
                  ),
                ),
                const SizedBox(height: 30),

                // Reset Password Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : MyButton(
                  buttonText: 'Send Reset Link',
                  onPressed: _resetPassword,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
