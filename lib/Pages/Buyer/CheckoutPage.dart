import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iiuc_bazaar/MVVM/Models/orderModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/cardModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/orderViewModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/productViewModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/cardViewModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/notificationViewModel.dart';
import 'package:iiuc_bazaar/Navigation/Buttom_Nav_Bar.dart';
import '../Payment/StripeService.dart';
import '../../MVVM/Models/productModel.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartModel> products;
  final double totalPrice;

  const CheckoutPage({
    required this.products,
    required this.totalPrice,
    Key? key,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // --- All your original state and logic is preserved ---
  final OrderViewModel _orderViewModel = OrderViewModel();
  final ProductViewModel _productViewModel = ProductViewModel();
  final CartViewModel _cartViewModel = CartViewModel();
  final NotificationViewModel _notificationViewModel = NotificationViewModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isProcessing = false;
  String? _selectedLocation;
  final List<String> _locations = ['FAZ', 'C Building', 'CX Building', 'CXB Building'];

  // --- All your logic methods are preserved with minor GetX integration for snackbars ---
  Future<void> _initiatePayment() async {
    if (_validateLocation() == false) return;
    setState(() => _isProcessing = true);
    try {
      bool paymentSuccess = await StripeService.instance.makePayment(widget.totalPrice);
      if (!paymentSuccess) {
        Get.snackbar("Payment Failed", "Payment was canceled or failed.");
        return;
      }
      await _handleOrderCreation("Payment Successful");
      await _notificationViewModel.addNotification(
        userId: _auth.currentUser!.uid,
        title: "Payment Successful",
        message: "Your payment of \৳${widget.totalPrice.toStringAsFixed(2)} was successful.\nDelivery Location: $_selectedLocation",
      );
      Get.snackbar("Success", "Payment was successful!");
      Get.offAll(() => MyBottomNavBar(initialIndex: 0));
    } catch (e) {
      Get.snackbar("Error", "Error processing payment: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCashOnDelivery() async {
    if (_validateLocation() == false) return;
    setState(() => _isProcessing = true);
    try {
      await _handleOrderCreation("Cash on Delivery");
      await _notificationViewModel.addNotification(
        userId: _auth.currentUser!.uid,
        title: "Order Placed",
        message: "Order placed successfully with Cash on Delivery.\nDelivery Location: $_selectedLocation. Pending payment \৳${widget.totalPrice.toStringAsFixed(2)}",
      );
      Get.snackbar("Success", "Order placed with Cash on Delivery!");
      Get.offAll(() => MyBottomNavBar(initialIndex: 0));
    } catch (e) {
      Get.snackbar("Error", "Error processing order: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  bool _validateLocation() {
    if (_auth.currentUser == null) return false;
    if (_selectedLocation == null) {
      Get.snackbar("Missing Information", "Please select a delivery location.",
        backgroundColor: Colors.orange.shade800, colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  Future<void> _handleOrderCreation(String paymentType) async {
    // This logic remains unchanged
    for (var product in widget.products) {
      await _createOrder(product, paymentType);
      await _updateProductStock(product);
      await _cartViewModel.removeFromCart(_auth.currentUser!.uid, product.productId);
    }
  }

  Future<void> _createOrder(CartModel product, String paymentType) async {
    // This logic remains unchanged
    ProductModel? productModel = await _productViewModel.fetchProductById(product.productId);
    if (productModel == null) throw Exception("Product not found");

    OrderModel order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _auth.currentUser!.uid,
      productId: product.productId,
      quantity: product.quantity,
      totalPrice: product.quantity * product.price,
      status: 'Pending',
      orderDate: DateTime.now(),
      sellerId: productModel.sellerId,
    );
    await _orderViewModel.placeOrder(order);

    String notificationMessage = paymentType == "Cash on Delivery"
        ? "New COD order for ${product.name}.\nLocation: $_selectedLocation. Amount: \৳${order.totalPrice.toStringAsFixed(2)}"
        : "New paid order for ${product.name}.\nLocation: $_selectedLocation. Amount: \৳${order.totalPrice.toStringAsFixed(2)}";

    await _notificationViewModel.addNotification(
      userId: productModel.sellerId,
      title: paymentType == "Cash on Delivery" ? "New Cash on Delivery Order" : "New Order Received",
      message: notificationMessage,
    );
  }

  Future<void> _updateProductStock(CartModel product) async {
    // This logic remains unchanged
    ProductModel? productModel = await _productViewModel.fetchProductById(product.productId);
    if (productModel != null) {
      productModel.quantity -= product.quantity;
      await _productViewModel.updateProduct(productModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = Get.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Confirm Your Order", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Order Summary", screenWidth),
                _buildOrderSummary(screenWidth),

                SizedBox(height: screenWidth * 0.06),

                _buildSectionTitle("Delivery Information", screenWidth),
                _buildLocationDropdown(screenWidth),

                SizedBox(height: screenWidth * 0.06),

                _buildSectionTitle("Payment Method", screenWidth),
                _buildPaymentOption(
                  title: "Pay Now with Card",
                  subtitle: "Secure payment via Stripe",
                  icon: Icons.credit_card_rounded,
                  onTap: _initiatePayment,
                  screenWidth: screenWidth,
                ),
                SizedBox(height: screenWidth * 0.04),
                _buildPaymentOption(
                  title: "Cash on Delivery",
                  subtitle: "Pay with cash upon arrival",
                  icon: Icons.local_shipping_rounded,
                  onTap: _handleCashOnDelivery,
                  screenWidth: screenWidth,
                ),
              ],
            ),
          ),
          // --- Beautiful Loading Overlay ---
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: screenWidth * 0.05),
                    Text(
                      "Processing your order...",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: screenWidth * 0.045),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- UI Builder Methods ---
  Widget _buildSectionTitle(String title, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOrderSummary(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Column(
        children: [
          ...widget.products.map((product) {
            return Padding(
              padding: EdgeInsets.only(bottom: screenWidth * 0.03),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    child: Image.memory(base64Decode(product.imageBase64), width: screenWidth * 0.12, height: screenWidth * 0.12, fit: BoxFit.cover),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Text("${product.name} (x${product.quantity})", style: GoogleFonts.nunitoSans(fontSize: screenWidth * 0.04)),
                  ),
                  Text("\৳${(product.quantity * product.price).toStringAsFixed(2)}", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
          const Divider(),
          Padding(
            padding: EdgeInsets.only(top: screenWidth * 0.02),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Amount", style: GoogleFonts.poppins(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold)),
                Text("\৳${widget.totalPrice.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDropdown(double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.01),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedLocation,
        hint: const Text("Select Delivery Location"),
        isExpanded: true,
        decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.location_on_rounded, color: Colors.teal)),
        items: _locations.map((location) => DropdownMenuItem<String>(value: location, child: Text(location, style: GoogleFonts.nunitoSans()))).toList(),
        onChanged: (value) => setState(() => _selectedLocation = value),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(screenWidth * 0.03),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: screenWidth * 0.08, color: Colors.teal.shade600),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: screenWidth * 0.042, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: GoogleFonts.nunitoSans(fontSize: screenWidth * 0.035, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}