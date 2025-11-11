import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'package:iiuc_bazaar/Pages/Home.dart';
import 'package:iiuc_bazaar/Pages/Products.dart';
import 'package:iiuc_bazaar/Pages/Cart.dart';
import 'package:iiuc_bazaar/Pages/Profile.dart';
import 'package:iiuc_bazaar/Auth/LogIn.dart';

import 'package:iiuc_bazaar/widget/chatbot_floating_button.dart'; // 👈 Import new widget

class MyBottomNavBar extends StatefulWidget {
  final int initialIndex;

  const MyBottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<MyBottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<MyBottomNavBar> {
  late int myCurrentIndex;

  final List<Widget> pages = [
    const Home(),
    Products(),
    const Cart(),
    const Profile(),
  ];

  @override
  void initState() {
    super.initState();
    myCurrentIndex = widget.initialIndex;
  }

  void onTabTapped(int index) {
    if ((index == 2 || index == 3) && FirebaseAuth.instance.currentUser == null) {
      // Redirect unauthenticated users
      Get.to(() => const LoginScreen())?.then((_) {
        setState(() {}); // Refresh user state after returning
      });
    } else {
      setState(() {
        myCurrentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final User? currentUser = snapshot.data;

        if (currentUser == null) {
          return const LoginScreen();
        }

        return Scaffold(
          body: Stack(
            children: [
              // ✅ Keep your tab pages
              IndexedStack(
                index: myCurrentIndex,
                children: pages,
              ),

              // 🧠 Add floating chatbot overlay
              const FloatingChatbot(),
            ],
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 25,
                  offset: const Offset(8, 20),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.green,
                unselectedItemColor: Colors.black,
                currentIndex: myCurrentIndex,
                onTap: onTabTapped,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                  BottomNavigationBarItem(icon: Icon(Icons.store), label: "Products"),
                  BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
