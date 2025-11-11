import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/orderViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/orderModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/productViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/productModel.dart';
import 'package:timeago/timeago.dart' as timeago;

// Helper class to combine Order and Product data for efficient UI building
class OrderDetail {
  final OrderModel order;
  final ProductModel product;

  OrderDetail({required this.order, required this.product});
}

class OrderInProcessPage extends StatefulWidget {
  const OrderInProcessPage({Key? key}) : super(key: key);

  @override
  State<OrderInProcessPage> createState() => _OrderInProcessPageState();
}

class _OrderInProcessPageState extends State<OrderInProcessPage> {
  final OrderViewModel _orderViewModel = OrderViewModel();
  final ProductViewModel _productViewModel = ProductViewModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // A single future to fetch all data at once, preventing UI flickering
  late Future<List<OrderDetail>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _ordersFuture = _fetchOrderDetails(currentUser.uid);
    }
  }

  // --- NEW EFFICIENT DATA FETCHING METHOD ---
  Future<List<OrderDetail>> _fetchOrderDetails(String userId) async {
    // 1. Fetch all user orders first and filter for "Pending" status
    final allOrders = await _orderViewModel.fetchUserOrders(userId);
    final pendingOrders = allOrders.where((order) => order.status == 'Pending').toList();

    if (pendingOrders.isEmpty) {
      return []; // Return early if no pending orders
    }

    List<OrderDetail> orderDetails = [];

    // 2. For each pending order, fetch its product details
    for (var order in pendingOrders) {
      try {
        ProductModel? product = await _productViewModel.fetchProductById(order.productId);
        if (product != null) {
          // 3. Combine them into a single OrderDetail object
          orderDetails.add(OrderDetail(order: order, product: product));
        }
      } catch (e) {
        print("Error fetching product for order ${order.id}: $e");
      }
    }
    return orderDetails;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Orders in Process", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
      ),
      body: currentUser == null
          ? _buildLoggedOutView()
          : FutureBuilder<List<OrderDetail>>(
        future: _ordersFuture, // Use the single, efficient future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyView();
          } else {
            final orderDetails = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(Get.width * 0.03), // Dynamic padding
              itemCount: orderDetails.length,
              itemBuilder: (context, index) {
                return OrderCard(orderDetail: orderDetails[index]);
              },
            );
          }
        },
      ),
    );
  }

  // --- UI Builder Methods ---
  Widget _buildLoggedOutView() {
    return Center(child: Text("Please log in to view your orders.", style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.04)));
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty_rounded, size: Get.width * 0.2, color: Colors.grey[400]),
          SizedBox(height: Get.width * 0.04),
          Text("No Pending Orders", style: GoogleFonts.poppins(fontSize: Get.width * 0.05, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          SizedBox(height: Get.width * 0.02),
          Text("Your active orders will appear here.", textAlign: TextAlign.center, style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.04, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Get.width * 0.04),
        child: Text("Something went wrong:\n$error", textAlign: TextAlign.center, style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.04, color: Colors.red[700])),
      ),
    );
  }
}


// --- BEAUTIFUL, DYNAMIC, AND REUSABLE ORDER CARD WIDGET ---
class OrderCard extends StatefulWidget {
  final OrderDetail orderDetail;

  const OrderCard({Key? key, required this.orderDetail}) : super(key: key);

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = Get.width;
    final OrderModel order = widget.orderDetail.order;
    final ProductModel product = widget.orderDetail.product;

    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.04),
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
              child: Image.memory(
                base64Decode(product.imageBase64),
                width: screenWidth * 0.22,
                height: screenWidth * 0.22,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: screenWidth * 0.22, height: screenWidth * 0.22,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.042,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    'Ordered ${timeago.format(order.orderDate)}',
                    style: GoogleFonts.nunitoSans(
                      fontSize: screenWidth * 0.032,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\৳${order.totalPrice.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      Chip(
                        label: Text(
                          order.status,
                          style: GoogleFonts.poppins(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                        backgroundColor: Colors.orange.shade100,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}