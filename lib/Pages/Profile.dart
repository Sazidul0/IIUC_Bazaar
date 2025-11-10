import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:iiuc_bazaar/Auth/LogIn.dart'; // Assuming LogIn screen exists for navigation
import 'package:iiuc_bazaar/Pages/Buyer/OrderInProcess.dart';
import 'package:iiuc_bazaar/Pages/Buyer/PurchasedItems.dart';
import 'package:iiuc_bazaar/Pages/Buyer/ViewReview.dart';
import 'package:iiuc_bazaar/Pages/Notification.dart';
import 'package:iiuc_bazaar/Pages/Seller/AddNewProduct.dart';
import 'package:iiuc_bazaar/Pages/Seller/ManageOrders.dart';
import 'package:iiuc_bazaar/Pages/Seller/UpdateProduct.dart';
import 'package:iiuc_bazaar/Pages/Seller/ViewSales.dart';

import '../MVVM/Models/userModel.dart';
import '../MVVM/View Model/userViewModel.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  // Function to handle sign out
  void signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // After sign out, navigate to the login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      // If there's an error signing out, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }



  // Function to fetch user details from Firestore
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      UserViewModel userViewModel = UserViewModel();
      return await userViewModel.fetchUserData(uid);
    } catch (e) {
      throw Exception("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser; // Get current user
    if (user == null) {
      // If no user is logged in, navigate to the login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      return const SizedBox();
    }

    return FutureBuilder<UserModel?>(
      future: getUserDetails(user.uid), // Fetch user details using UID
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Redirect to login page if there’s an error fetching data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          });
          return const Center(child: Text('Error fetching user data'));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          // If there's no user data available, redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          });
          return const Center(child: Text('No user data found'));
        }

        var userDetails = snapshot.data!;
        var size = Get.size; // Get screen size
        final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

        return Scaffold(
          key: _scaffoldKey, // Assign the GlobalKey to the Scaffold
          drawer: Drawer(
              child:  Drawer(
                child: Column(
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        // color: Colors.blue,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_circle, size: 80, color: Colors.blue),
                          SizedBox(height: 8),
                          Text(
                            userDetails.name ?? "Name not available",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text("Email"),
                      subtitle: Text(userDetails.email ?? "Email not available"),
                    ),
                    ListTile(
                      leading: Icon(Icons.phone),
                      title: Text("Phone"),
                      subtitle: Text(userDetails.mobileNumber ?? "Phone not available"),
                    ),
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text("User Type"),
                      subtitle: Text(userDetails.userType ?? "N/A"),
                    ),
                    ListTile(
                      title: Row(
                        children: [

                          IconButton(
                            icon: Icon(Icons.exit_to_app),
                            onPressed: () {
                              _showExitConfirmationDialog(context);
                            },
                          ),
                          Text(" Exit"),
                        ],
                      ),
                    ),
                    Spacer(), // Push the sign-out button to the bottom
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () => signOut(context),
                        child: Text("Sign Out"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          foregroundColor: Colors.white,
                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),// The drawer code provided above
          ),
          // backgroundColor: Colors.blue,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,

                ),
                width: size.width,

                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(21.0),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                color: Colors.black,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                _scaffoldKey.currentState?.openDrawer(); // Open the drawer when tapped
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  Icons.account_circle,
                                  size: size.width * 0.15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: size.width * 0.02),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: size.width * 0.05),
                              Text(
                                "${userDetails.name ?? 'Name not Found!'}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: size.width * 0.05,
                                ),
                              ),
                              Text(
                                "${userDetails.email ?? 'No email provided'}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width * 0.03,
                                ),
                              ),
                              SizedBox(height: size.width * 0.05),
                            ],
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotificationPage(), // Replace with your notification page widget
                                ),
                              );
                            },
                            child: Icon(
                              Icons.notifications,
                              size: size.width * 0.1,
                              color: Colors.white,
                            ),
                          ),

                        ],
                      ),
                    ),
                    // Middle Section Based on UserType

                    // Bottom Section (Same for Both Seller and Buyer)
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
                      child: Center(
                        child: Column(
                          children: [

                            userDetails.userType == 'Seller' ? SellerProfile(userDetails) : BuyerProfile(userDetails),
                            SizedBox(
                              height: size.width*0.1,
                            ),
                            // ElevatedButton(
                            //   onPressed: () => signOut(context),
                            //   child: Text("Sign Out"),
                            //   style: ElevatedButton.styleFrom(
                            //     backgroundColor: Colors.red,
                            //     padding: EdgeInsets.symmetric(
                            //       horizontal: size.width * 0.1,
                            //       vertical: size.height * 0.02,
                            //     ),
                            //     foregroundColor: Colors.white,
                            //     textStyle: TextStyle(fontSize: size.width * 0.05, fontWeight: FontWeight.w600),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}






class SellerProfile extends StatelessWidget {
  final UserModel userDetails;
  const SellerProfile(this.userDetails);

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text("Seller Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),

          // Seller's Grid (4 items in 2 rows, 2 columns)
          SizedBox(height: 10),
          GifTextGrid(gridItems: [
            {'gif': 'assets/gif_1.gif', 'text': 'Manage Orders'},
            {'gif': 'assets/git_2.gif', 'text': 'Add Product'},
            {'gif': 'assets/gif_3.gif', 'text': 'View Sales'},
            {'gif': 'assets/gif_6.gif', 'text': 'Update Products'},
          ], gridItemCount: 4, userId: userDetails.uid,), // 4 items for the seller

        ],
      ),
    );
  }
}

class BuyerProfile extends StatelessWidget {
  final UserModel userDetails;
  const BuyerProfile(this.userDetails);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text("Buyer Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),

          // Buyer's Grid (2 items in a single row with 2 columns)
          SizedBox(height: 10),
          GifTextGrid(gridItems: [
            {'gif': 'assets/gif_1.gif', 'text': 'Purchased Items'},
            {'gif': 'assets/gif_7.gif', 'text': 'My Review'},
            {'gif': 'assets/gif_5.gif', 'text': 'Orders in Process'},
          ], gridItemCount: 3, userId: userDetails.uid,), // 3 items for the buyer


        ],
      ),
    );
  }
}

// Grid Widget for displaying GIF and Text
class GifTextGrid extends StatelessWidget {
  final List<Map<String, String>> gridItems;
  final int gridItemCount;
  final String userId;
  const GifTextGrid({required this.gridItems, required this.gridItemCount,  required this.userId});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true, // This prevents GridView from taking full height
      physics: NeverScrollableScrollPhysics(), // Prevents scrolling inside the grid
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridItemCount == 4 ? 2 : 2, // Two columns for both Seller and Buyer
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: gridItems.length,
      itemBuilder: (context, index) {
        final item = gridItems[index];

        return GestureDetector(
          onTap: () {
            // Handle tap action for each button
            print("Tapped on ${item['text']}");
            // You can navigate or perform any task based on the grid item tapped.
            if (item['text'] == 'Manage Orders') {
              // Handle Manage Orders functionality
              Get.to(ManageOrdersPage());
            } else if (item['text'] == 'Add Product') {
              Get.to(AddProductPage(sellerId: userId));
            } else if (item['text'] == 'View Sales') {
              // Handle View Sales functionality
              Get.to(ViewSalesPage());
            } else if (item['text'] == 'Update Products') {
              Get.to(UpdateProductsPage(sellerId: userId));
            } else if (item['text'] == 'Purchased Items') {
              // Handle Purchased Items functionality
              Get.to(PurchasedItemsPage());
            } else if (item['text'] == 'My Review') {
              // Handle Wishlist functionality
              Get.to(ViewReviewPage());
            } else if (item['text'] == 'Orders in Process') {
              // Handle Orders in Process functionality
              Get.to(OrderInProcessPage());
            }
          },
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Add GIF image
                Image.asset(item['gif']!, width: 70, height: 110),
                // SizedBox(height: 5),
                // Add Text
                Text(item['text']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }
}



void _showExitConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Exit Confirmation'),
        content: Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              // Exit the application
              // Note: This is not recommended in Flutter for mobile apps,
              // but you can use SystemNavigator.pop() if necessary.
              SystemNavigator.pop(); // Uncomment this line if you want to exit.
            },
          ),
        ],
      );
    },
  );
}

