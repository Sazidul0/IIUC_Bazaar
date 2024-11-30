import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();

  // Make Payment Method
  Future<void> makePayment(double totalPrice) async {
    try {
      // Create payment intent on the server
      String? paymentIntentClientSecret = await _createPaymentIntent(
        totalPrice,
        "bdt",
      );
      if (paymentIntentClientSecret == null) return;

      // Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: "Sazidul Islam",
        ),
      );

      // Display the payment sheet
      await _processPayment();
    } catch (e) {
      print("Error during payment: $e");
    }
  }

  // Create Payment Intent
  Future<String?> _createPaymentIntent(double amount, String currency) async {
    String secretKey = dotenv.get('SECRET_KEY');
    try {
      final Dio dio = Dio();
      Map<String, dynamic> data = {
        "amount": _calculateAmount(amount), // Ensure amount is an integer
        "currency": currency,
        "payment_method_types[]": "card", // Specify supported payment methods
      };
      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer ${secretKey}", // Replace with your actual secret key
            "Content-Type": 'application/x-www-form-urlencoded',
          },
        ),
      );

      // Check if response contains a client secret
      if (response.data != null && response.data["client_secret"] != null) {
        return response.data["client_secret"];
      } else {
        print("Error: No client_secret found in the response.");
        return null;
      }
    } catch (e) {
      print("Error creating payment intent: $e");
      return null;
    }
  }

  // Process Payment
  Future<void> _processPayment() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      print("Payment successful!");
    } catch (e) {
      print("Error presenting payment sheet: $e");
    }
  }

  // Convert amount to smallest currency unit (e.g., cents for USD)
  String _calculateAmount(double amount) {
    final calculatedAmount = (amount * 100).toInt(); // Convert to integer
    return calculatedAmount.toString();
  }
}
