import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/productViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/productModel.dart';

class ViewReviewPage extends StatefulWidget {
  const ViewReviewPage({Key? key}) : super(key: key);

  @override
  State<ViewReviewPage> createState() => _ViewReviewPageState();
}

class _ViewReviewPageState extends State<ViewReviewPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProductViewModel _productViewModel = ProductViewModel();
  late Future<List<ProductModel>> _reviewedProductsFuture;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _reviewedProductsFuture = _fetchProductsWithUserReviews(user.uid);
    }
  }

  // --- Data Fetching Logic (Preserved) ---
  Future<List<ProductModel>> _fetchProductsWithUserReviews(String userId) async {
    try {
      final allProducts = await _productViewModel.fetchAllProducts();
      return allProducts.where((product) {
        return product.reviews.any((review) => review.startsWith("$userId:"));
      }).toList();
    } catch (e) {
      throw Exception("Error fetching products with user reviews: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("My Reviews", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
      ),
      body: user == null
          ? _buildLoggedOutView()
          : FutureBuilder<List<ProductModel>>(
        future: _reviewedProductsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyView();
          } else {
            final products = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(Get.width * 0.03),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                // Safely extract the rating
                final userReviewString = product.reviews.firstWhere(
                      (review) => review.startsWith("${user.uid}:"),
                  orElse: () => ":0", // Fallback in case of an issue
                );
                final ratingValue = double.tryParse(userReviewString.split(":").last.trim()) ?? 0.0;

                return ReviewCard(
                  product: product,
                  rating: ratingValue,
                );
              },
            );
          }
        },
      ),
    );
  }

  // --- UI Builder Methods ---
  Widget _buildLoggedOutView() {
    return Center(
      child: Text("Please log in to view your reviews.", style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.04)),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: Get.width * 0.2, color: Colors.grey[400]),
          SizedBox(height: Get.width * 0.04),
          Text("No Reviews Yet", style: GoogleFonts.poppins(fontSize: Get.width * 0.05, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          SizedBox(height: Get.width * 0.02),
          Text("Your reviewed items will appear here.", textAlign: TextAlign.center, style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.04, color: Colors.grey[500])),
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


// --- BEAUTIFUL, DYNAMIC, AND REUSABLE REVIEW CARD WIDGET ---
class ReviewCard extends StatefulWidget {
  final ProductModel product;
  final double rating;

  const ReviewCard({
    Key? key,
    required this.product,
    required this.rating,
  }) : super(key: key);

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> with SingleTickerProviderStateMixin {
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
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
              child: Image.memory(
                base64Decode(widget.product.imageBase64),
                width: screenWidth * 0.2,
                height: screenWidth * 0.2,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: screenWidth * 0.2,
                  height: screenWidth * 0.2,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),

            // Product Name and Rating
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  // Beautiful Star Rating Bar
                  RatingBarIndicator(
                    rating: widget.rating,
                    itemBuilder: (context, index) => const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: screenWidth * 0.06,
                    direction: Axis.horizontal,
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