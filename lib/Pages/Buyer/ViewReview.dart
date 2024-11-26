import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  late String currentUserId;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Reviews")),
        body: const Center(
          child: Text("You must be logged in to view your reviews."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Reviews")),
      body: FutureBuilder<List<ProductModel>>(
        future: _fetchProductsWithUserReviews(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No reviews found."));
          } else {
            final products = snapshot.data!;
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final userReview = product.reviews.firstWhere(
                      (review) => review.startsWith("$currentUserId:"),
                  orElse: () => "",
                );
                final rating = userReview.split(":").last;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [

                            const SizedBox(width: 4),
                            Text("Your Rating: $rating", style: const TextStyle(fontSize: 16)),
                            const Icon(Icons.star, color: Colors.yellow,size: 18),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    leading: product.imageBase64.isEmpty
                        ? const CircleAvatar(child: Icon(Icons.image))
                        : CircleAvatar(
                      backgroundImage: MemoryImage(
                        base64Decode(product.imageBase64),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<ProductModel>> _fetchProductsWithUserReviews(String userId) async {
    try {
      final allProducts = await _productViewModel.fetchAllProducts();
      // Filter products where the user has left a review
      return allProducts.where((product) {
        return product.reviews.any((review) => review.startsWith("$userId:"));
      }).toList();
    } catch (e) {
      throw Exception("Error fetching products with user reviews: $e");
    }
  }
}
