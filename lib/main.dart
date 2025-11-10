import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:iiuc_bazaar/Navigation/Buttom_Nav_Bar.dart'; // Import your bottom nav bar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = dotenv.get('Publishable_Key');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Default route
      getPages: [
        GetPage(name: '/', page: () => const MyBottomNavBar(initialIndex: 0)), // Default route
      ],
    );
  }
}
