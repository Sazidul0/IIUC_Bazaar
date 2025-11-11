import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/orderViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/orderModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/productViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/productModel.dart';

// Helper class to combine Order and Product data for efficient UI building
class PurchaseDetail {
  final OrderModel order;
  final ProductModel product;

  PurchaseDetail({required this.order, required this.product});
}

class PurchasedItemsPage extends StatefulWidget {
  const PurchasedItemsPage({Key? key}) : super(key: key);

  @override
  State<PurchasedItemsPage> createState() => _PurchasedItemsPageState();
}

class _PurchasedItemsPageState extends State<PurchasedItemsPage> {
  final OrderViewModel _orderViewModel = OrderViewModel();
  final ProductViewModel _productViewModel = ProductViewModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // A single future to fetch all data at once, preventing UI flickering
  late Future<List<PurchaseDetail>> _purchasesFuture;

  @override
  void initState() {
    super.initState();
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _purchasesFuture = _fetchPurchaseDetails(currentUser.uid);
    }
  }

  // --- NEW EFFICIENT DATA FETCHING METHOD ---
  Future<List<PurchaseDetail>> _fetchPurchaseDetails(String userId) async {
    final allOrders = await _orderViewModel.fetchUserOrders(userId);
    final completedOrders = allOrders.where((order) => order.status == 'Completed').toList();

    if (completedOrders.isEmpty) return [];

    List<PurchaseDetail> purchaseDetails = [];
    for (var order in completedOrders) {
      try {
        ProductModel? product = await _productViewModel.fetchProductById(order.productId);
        if (product != null) {
          purchaseDetails.add(PurchaseDetail(order: order, product: product));
        }
      } catch (e) {
        print("Error fetching product for order ${order.id}: $e");
      }
    }
    return purchaseDetails;
  }

  // A method to refresh the list after a review is submitted
  void _refreshPurchases() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        _purchasesFuture = _fetchPurchaseDetails(currentUser.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Purchase History", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
      ),
      body: currentUser == null
          ? _buildLoggedOutView()
          : FutureBuilder<List<PurchaseDetail>>(
        future: _purchasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyView();
          } else {
            final purchases = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(Get.width * 0.03),
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                return PurchaseCard(
                  purchaseDetail: purchases[index],
                  onReviewSubmitted: _refreshPurchases, // Pass refresh callback
                );
              },
            );
          }
        },
      ),
    );
  }

  // --- UI Builder Methods ---
  Widget _buildLoggedOutView() => Center(child: Text("Please log in to view your purchases.", style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.04)));
  Widget _buildEmptyView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long_rounded, size: Get.width * 0.2, color: Colors.grey[400]),
        SizedBox(height: Get.width * 0.04),
        Text("No Purchases Yet", style: GoogleFonts.poppins(fontSize: Get.width * 0.05, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        SizedBox(height: Get.width * 0.02),
        Text("Your completed orders will appear here.", textAlign: TextAlign.center, style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.04, color: Colors.grey[500])),
      ],
    ),
  );
  Widget _buildErrorView(String error) => Center(
    child: Padding(
      padding: EdgeInsets.all(Get.width * 0.04),
      child: Text("Something went wrong:\n$error", textAlign: TextAlign.center, style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.04, color: Colors.red[700])),
    ),
  );
}


// --- BEAUTIFUL, DYNAMIC, AND INTERACTIVE PURCHASE CARD WIDGET ---
class PurchaseCard extends StatefulWidget {
  final PurchaseDetail purchaseDetail;
  final VoidCallback onReviewSubmitted;

  const PurchaseCard({
    Key? key,
    required this.purchaseDetail,
    required this.onReviewSubmitted,
  }) : super(key: key);

  @override
  State<PurchaseCard> createState() => _PurchaseCardState();
}

class _PurchaseCardState extends State<PurchaseCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _checkIfReviewed();
  }

  void _checkIfReviewed() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      _hasReviewed = widget.purchaseDetail.product.reviews.any((review) => review.contains(currentUserId));
    }
  }

  void _showReviewDialog() {
    double _rating = 3.0;
    final product = widget.purchaseDetail.product;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Get.width * 0.04)),
        title: Text("Review '${product.name}'", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("How would you rate your purchase?", style: GoogleFonts.nunitoSans()),
            SizedBox(height: Get.width * 0.05),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) => _rating = rating,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _submitReview(product, userId, _rating);
              Get.back(); // Close the dialog
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview(ProductModel product, String userId, double rating) async {
    final reviewEntry = "$userId: $rating";
    product.reviews.add(reviewEntry);

    await ProductViewModel().updateProduct(product);

    setState(() => _hasReviewed = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Thank you for your review!")),
    );
    // widget.onReviewSubmitted(); // Optionally refresh the whole list
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = Get.width;
    final OrderModel order = widget.purchaseDetail.order;
    final ProductModel product = widget.purchaseDetail.product;

    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.04),
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  child: Image.memory(
                    base64Decode(product.imageBase64),
                    width: screenWidth * 0.18, height: screenWidth * 0.18, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(width: screenWidth * 0.18, height: screenWidth * 0.18, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: screenWidth * 0.042, fontWeight: FontWeight.bold)),
                      SizedBox(height: screenWidth * 0.01),
                      Text('Purchased on ${order.orderDate.toString().split(' ')[0]}', style: GoogleFonts.nunitoSans(fontSize: screenWidth * 0.032, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Text("\৳${order.totalPrice.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              ],
            ),
            const Divider(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _hasReviewed
                  ? Row(
                key: const ValueKey('reviewed'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: screenWidth * 0.05),
                  SizedBox(width: screenWidth * 0.02),
                  Text("You've reviewed this item", style: GoogleFonts.nunitoSans(fontSize: screenWidth * 0.035, color: Colors.green)),
                ],
              )
                  : SizedBox(
                key: const ValueKey('not_reviewed'),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showReviewDialog,
                  icon: Icon(Icons.rate_review_outlined, size: screenWidth * 0.045),
                  label: Text("Give Review", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade50,
                    foregroundColor: Colors.teal.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.02)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}