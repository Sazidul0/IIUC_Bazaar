import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:iiuc_bazaar/Auth/ForgotPassword.dart';
import 'package:iiuc_bazaar/Auth/SignUp.dart';
import 'package:iiuc_bazaar/Components/my_button.dart';
import 'package:iiuc_bazaar/Components/my_textfield.dart';
import 'package:get/get.dart';
import 'package:iiuc_bazaar/Auth/Login_Controller.dart';

class LoginBodyScreen extends StatefulWidget {
  const LoginBodyScreen({super.key});

  @override
  State<LoginBodyScreen> createState() => _LoginBodyScreenState();
}

class _LoginBodyScreenState extends State<LoginBodyScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final LoginController loginController = Get.put(LoginController());

  bool _isPasswordVisible = false; // Password visibility state
  String _errorMessage = "";
  bool _isLoading = false; // Loading state

  // Function to sign the user in
  void signUserIn() async {
    // Validate email before proceeding
    if (_errorMessage.isNotEmpty) {
      showErrorMessage(_errorMessage);
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    // Set email and password from TextEditingController to the controller's observables
    loginController.email.value = emailController.text;
    loginController.password.value = passwordController.text;

    // Call the login function
    await loginController.loginUser();

    setState(() {
      _isLoading = false; // Stop loading
    });

    // If there's an error message, show it
    if (loginController.errorMessage.value.isNotEmpty) {
      showErrorMessage(loginController.errorMessage.value);
    }
  }

  // Function to show error messages
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Email validation function
  void validateEmail(String val) {
    if (val.isEmpty) {
      setState(() {
        _errorMessage = "Email cannot be empty";
      });
    } else if (!EmailValidator.validate(val, true)) {
      setState(() {
        _errorMessage = "Invalid Email Address";
      });
    } else {
      setState(() {
        _errorMessage = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.green,
            body: ListView(
              padding: const EdgeInsets.fromLTRB(0, 400, 0, 0),
              shrinkWrap: true,
              reverse: true,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 535,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: HexColor("#ffffff"),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Log In",
                                    style: GoogleFonts.poppins(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: HexColor("#4f4f4f"),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(15, 0, 0, 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Email",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            color: HexColor("#8d8d8d"),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        MyTextField(
                                          onChanged: (value) {
                                            validateEmail(value);
                                          },
                                          controller: emailController,
                                          hintText: "Enter your email",
                                          obscureText: false,
                                          prefixIcon: const Icon(Icons.mail_outline),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                                          child: Text(
                                            _errorMessage,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Password",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            color: HexColor("#8d8d8d"),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        MyTextField(
                                          controller: passwordController,
                                          hintText: "**************",
                                          obscureText: !_isPasswordVisible,
                                          prefixIcon: const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: HexColor("#8d8d8d"),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordVisible = !_isPasswordVisible;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        MyButton(
                                          onPressed: signUserIn,
                                          buttonText: 'Submit',
                                        ),
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(35, 0, 0, 0),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      "Don't have an account?",
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 13,
                                                        color: HexColor("#8d8d8d"),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      child: Text(
                                                        "Sign Up",
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 15,
                                                          color: HexColor("#44564a"),
                                                        ),
                                                      ),
                                                      onPressed: () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                          const SignUpScreen(),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Center(
                                                  child: TextButton(
                                                    child: Text(
                                                      "Forgot Password          ",
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 15,
                                                        color: HexColor("#44564a"),
                                                      ),
                                                    ),
                                                    onPressed: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                        const ForgotPassword(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -253),
                          child: Image.asset(
                            'assets/images/plants2.png',
                            scale: 1.5,
                            width: double.infinity,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_isLoading) ...[
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
