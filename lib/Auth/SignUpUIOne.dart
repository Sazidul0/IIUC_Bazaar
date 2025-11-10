import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:iiuc_bazaar/Auth/LogIn.dart';
import 'package:iiuc_bazaar/Auth/Sign_up_Controller.dart';
import 'package:iiuc_bazaar/Components/my_button.dart'; // Assuming MyButton is defined elsewhere

List<String> list = <String>['Buyer', 'Seller']; // User type options

class SignUpOne extends StatefulWidget {
  const SignUpOne({super.key});

  @override
  State<SignUpOne> createState() => _SignUpOneState();
}

class _SignUpOneState extends State<SignUpOne> {
  final SignUpController signUpController = Get.put(SignUpController());

  String dropdownValue = list.first;
  String _errorMessage = "";
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Controllers for TextFields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _registerUser() async {
    // Check for empty fields
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        mobileNumberController.text.isEmpty) {
      Get.snackbar("Error", "Please fill all the fields.");
      return;
    }

    // Email validation
    if (!emailController.text.endsWith("@ugrad.iiuc.ac.bd")) {
      Get.snackbar("Error", "You must use your university email.\nExample: C201023@ugrad.iiuc.ac.bd");
      return;
    }

    // Start loading
    setState(() {
      _isLoading = true;
    });

    try {
      bool isRegistered = await signUpController.registerUser(
        emailController.text,
        passwordController.text,
      );
      if (isRegistered) {
        Get.snackbar("Success", "Please check your email for verification.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        Get.snackbar("Error", "An error occurred during registration.");
      }
    } finally {
      // Stop loading
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 67),
                  Text(
                    "Sign Up",
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: HexColor("#4f4f4f"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 0, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.supervised_user_circle),
                        Text(
                          " Select User Type",
                          style: GoogleFonts.poppins(fontSize: 18, color: HexColor("#4f4f4f"), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Obx(() => DropdownButton<String>(
                      value: signUpController.userType.value,
                      icon: const Icon(Icons.arrow_drop_down),
                      elevation: 16,
                      style: GoogleFonts.poppins(fontSize: 15, color: HexColor("#8d8d8d")),
                      isExpanded: true,
                      onChanged: (String? value) {
                        signUpController.setUserType(value!);
                      },
                      items: list.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                    )),
                    const SizedBox(height: 20),

                    // Name Input
                    Text("Name", style: GoogleFonts.poppins(fontSize: 16, color: HexColor("#8d8d8d"))),
                    const SizedBox(height: 5),
                    TextField(
                      controller: nameController,
                      onChanged: signUpController.setName,
                      decoration: InputDecoration(
                        hintText: "Enter your name",
                        fillColor: HexColor("#f0f3f1"),
                        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        hintStyle: GoogleFonts.poppins(fontSize: 15, color: HexColor("#8d8d8d")),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        filled: true,
                        prefixIcon: Icon(Icons.person_outline, color: HexColor("#4f4f4f")),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email Input
                    Text("Email", style: GoogleFonts.poppins(fontSize: 16, color: HexColor("#8d8d8d"))),
                    const SizedBox(height: 5),
                    TextField(
                      controller: emailController,
                      onChanged: signUpController.setEmail,
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
                    const SizedBox(height: 20),

                    // Phone Number Input
                    Text("Phone Number", style: GoogleFonts.poppins(fontSize: 16, color: HexColor("#8d8d8d"))),
                    const SizedBox(height: 5),
                    TextField(
                      controller: mobileNumberController,
                      onChanged: signUpController.setMobileNumber,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "Enter your phone number",
                        fillColor: HexColor("#f0f3f1"),
                        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        hintStyle: GoogleFonts.poppins(fontSize: 15, color: HexColor("#8d8d8d")),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        filled: true,
                        prefixIcon: Icon(Icons.phone_android_outlined, color: HexColor("#4f4f4f")),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Input
                    Text("Password", style: GoogleFonts.poppins(fontSize: 16, color: HexColor("#8d8d8d"))),
                    const SizedBox(height: 5),
                    TextField(
                      controller: passwordController,
                      onChanged: signUpController.setPassword,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: "*************",
                        fillColor: HexColor("#f0f3f1"),
                        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        hintStyle: GoogleFonts.poppins(fontSize: 15, color: HexColor("#8d8d8d")),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        filled: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: HexColor("#8d8d8d"),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        prefixIcon: Icon(Icons.lock_outline, color: HexColor("#4f4f4f")),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Proceed Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : MyButton(
                      buttonText: 'Proceed',
                      onPressed: _registerUser,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
