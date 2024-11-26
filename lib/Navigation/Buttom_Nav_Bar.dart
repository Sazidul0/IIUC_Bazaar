import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iiuc_bazaar/Pages/Home.dart';
import 'package:iiuc_bazaar/Pages/Products.dart';
import 'package:iiuc_bazaar/Pages/Cart.dart';
import 'package:iiuc_bazaar/Pages/Profile.dart';
import 'package:iiuc_bazaar/Auth/LogIn.dart';
import 'package:get/get.dart';

class MyBottomNavBar extends StatefulWidget {
  final int initialIndex;

  const MyBottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<MyBottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<MyBottomNavBar> {
  late int myCurrentIndex; // Dynamic initial index

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
// If trying to access Cart or Profile and the user is not logged in
      Get.to(() => const LoginScreen())?.then((_) {
// Refresh user state after navigating back from login
        setState(() {});
      });
    } else {
      setState(() {
        myCurrentIndex = index; // No restriction on Home and Products
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

// Access the current user state
        User? currentUser = snapshot.data;

// If the user is not logged in, show the login screen
        if (currentUser == null) {
          return const LoginScreen(); // Directly show the login screen
        }

// If user is logged in, show the main application interface
        return Scaffold(
          body: IndexedStack(
            index: myCurrentIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 25,
                  offset: const Offset(8, 20))
            ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                selectedItemColor: Colors.redAccent,
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