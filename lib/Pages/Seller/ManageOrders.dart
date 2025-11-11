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
class SellerOrderDetail {
  final OrderModel order;
  final ProductModel product;

  SellerOrderDetail({required this.order, required this.product});
}

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({Key? key}) : super(key: key);

  @override
  _ManageOrdersPageState createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  final OrderViewModel _orderViewModel = OrderViewModel();
  final ProductViewModel _productViewModel = ProductViewModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String sellerId;

  // A single future to fetch all data at once, preventing UI flickering
  late Future<List<SellerOrderDetail>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    sellerId = _auth.currentUser!.uid;
    _ordersFuture = _fetchOrderDetails();
  }

  // --- NEW EFFICIENT DATA FETCHING METHOD ---
  Future<List<SellerOrderDetail>> _fetchOrderDetails() async {
    // 1. Fetch all seller orders first
    final List<OrderModel> sellerOrders = await _orderViewModel.fetchSellerOrders(sellerId);
    if (sellerOrders.isEmpty) return [];

    // Sort orders to show "Pending" ones first
    sellerOrders.sort((a, b) {
      if (a.status == 'Pending' && b.status != 'Pending') return -1;
      if (a.status != 'Pending' && b.status == 'Pending') return 1;
      return 0; // Keep original order for same statuses
    });

    List<SellerOrderDetail> orderDetails = [];

    // 2. For each order, fetch its product details
    for (var order in sellerOrders) {
      try {
        ProductModel? product = await _productViewModel.fetchProductById(order.productId);
        if (product != null) {
          // 3. Combine them into a single object
          orderDetails.add(SellerOrderDetail(order: order, product: product));
        }
      } catch (e) {
        print("Error fetching product for order ${order.id}: $e");
      }
    }
    return orderDetails;
  }

  // Function to refresh the entire list, passed to the card
  void _refreshOrders() {
    setState(() {
      _ordersFuture = _fetchOrderDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Manage Orders", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
      ),
      body: FutureBuilder<List<SellerOrderDetail>>(
        future: _ordersFuture,
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
              padding: EdgeInsets.all(Get.width * 0.03),
              itemCount: orderDetails.length,
              itemBuilder: (context, index) {
                return ManageOrderCard(
                  orderDetail: orderDetails[index],
                  onOrderUpdated: _refreshOrders, // Pass the refresh function
                );
              },
            );
          }
        },
      ),
    );
  }

  // --- UI Builder Methods ---
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt_rounded, size: Get.width * 0.2, color: Colors.grey[400]),
          SizedBox(height: Get.width * 0.04),
          Text("No Orders Received", style: GoogleFonts.poppins(fontSize: Get.width * 0.05, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          SizedBox(height: Get.width * 0.02),
          Text("New customer orders will appear here.", textAlign: TextAlign.center, style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.04, color: Colors.grey[500])),
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


// --- BEAUTIFUL, DYNAMIC, AND INTERACTIVE ORDER CARD WIDGET ---
class ManageOrderCard extends StatefulWidget {
  final SellerOrderDetail orderDetail;
  final VoidCallback onOrderUpdated;

  const ManageOrderCard({
    Key? key,
    required this.orderDetail,
    required this.onOrderUpdated,
  }) : super(key: key);

  @override
  State<ManageOrderCard> createState() => _ManageOrderCardState();
}

class _ManageOrderCardState extends State<ManageOrderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isUpdating = false;

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

  Future<void> _completeOrder() async {
    setState(() => _isUpdating = true);
    try {
      final OrderViewModel orderViewModel = OrderViewModel();
      await orderViewModel.updateOrderStatus(widget.orderDetail.order.id, 'Completed');
      widget.onOrderUpdated(); // Trigger refresh on the parent page
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update order: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = Get.width;
    final OrderModel order = widget.orderDetail.order;
    final ProductModel product = widget.orderDetail.product;
    final bool isPending = order.status == 'Pending';

    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.04),
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: isPending ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          border: isPending ? Border.all(color: Colors.teal, width: 1.5) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
              child: Image.memory(
                base64Decode(product.imageBase64),
                width: screenWidth * 0.2,
                height: screenWidth * 0.2,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  width: screenWidth * 0.2, height: screenWidth * 0.2,
                  color: Colors.grey[200], child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: screenWidth * 0.042, fontWeight: FontWeight.bold)),
                  SizedBox(height: screenWidth * 0.01),
                  Text('Order Placed: ${timeago.format(order.orderDate)}',
                      style: GoogleFonts.nunitoSans(fontSize: screenWidth * 0.032, color: Colors.grey[600])),
                  SizedBox(height: screenWidth * 0.01),
                  Text('Order ID: ${order.id}',
                      style: GoogleFonts.nunitoSans(fontSize: screenWidth * 0.03, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            isPending
                ? ElevatedButton(
              onPressed: _isUpdating ? null : _completeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
              ),
              child: _isUpdating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text("Complete", style: GoogleFonts.poppins(fontSize: screenWidth * 0.03, fontWeight: FontWeight.bold)),
            )
                : Chip(
              label: Text("Completed", style: GoogleFonts.poppins(color: Colors.green.shade800, fontWeight: FontWeight.w600)),
              backgroundColor: Colors.green.shade100,
              avatar: Icon(Icons.check_circle, color: Colors.green.shade800, size: screenWidth * 0.045),
            ),
          ],
        ),
      ),
    );
  }
}