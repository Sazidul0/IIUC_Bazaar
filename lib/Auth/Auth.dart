import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiuc_bazaar/Auth/LogIn.dart';
import 'package:iiuc_bazaar/Navigation/Buttom_Nav_Bar.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          // User is authenticated; show the main navigation
          return const MyBottomNavBar();
        }

        // User is not authenticated; show login screen
        return const LoginScreen();
      },
    );
  }
}
