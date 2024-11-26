import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/orderViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/orderModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/productViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/productModel.dart';

class PurchasedItemsPage extends StatefulWidget {
  const PurchasedItemsPage({Key? key}) : super(key: key);

  @override
  State<PurchasedItemsPage> createState() => _PurchasedItemsPageState();
}

class _PurchasedItemsPageState extends State<PurchasedItemsPage> {
  final OrderViewModel _orderViewModel = OrderViewModel();
  final ProductViewModel _productViewModel = ProductViewModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for product details by productId
  Map<String, ProductModel?> _productCache = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Purchased Items")),
        body: const Center(
          child: Text("You must be logged in to view your purchased items."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Purchased Items")),
      body: FutureBuilder<List<OrderModel>>(
        future: _fetchCompletedOrders(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No completed orders."));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final order = snapshot.data![index];

                return FutureBuilder<ProductModel?>(
                  future: _getProductDetails(order.productId),
                  builder: (context, productSnapshot) {
                    if (productSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (productSnapshot.hasError) {
                      return Center(child: Text("Error: ${productSnapshot.error}"));
                    } else if (!productSnapshot.hasData || productSnapshot.data == null) {
                      return const Center(child: Text("Product not found"));
                    } else {
                      final product = productSnapshot.data!;
                      final currentUserId = currentUser.uid;

                      final hasReviewed = product.reviews.any((review) {
                        return review.contains(currentUserId); // Check if user already reviewed
                      });

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: ListTile(
                          title: Text("Order ID: ${order.id}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Product: ${product.name}"),
                              Text("Quantity: ${order.quantity}"),
                              Text("Total Price: \৳${order.totalPrice}"),
                              Text("Status: ${order.status}"),
                              if (!hasReviewed)
                                ElevatedButton(
                                  onPressed: () => _showReviewDialog(product, currentUserId),
                                  child: const Text("Give Review"),
                                )
                              else
                                const Text(
                                  "You have already reviewed this product.",
                                  style: TextStyle(color: Colors.green),
                                ),
                            ],
                          ),
                          leading: product.imageBase64.isEmpty
                              ? const CircleAvatar(child: Icon(Icons.image))
                              : CircleAvatar(
                            backgroundImage: MemoryImage(
                              base64Decode(product.imageBase64),
                            ),
                          ),
                          trailing: Text(
                            order.orderDate.toString().split(' ')[0],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<OrderModel>> _fetchCompletedOrders(String userId) async {
    try {
      final allOrders = await _orderViewModel.fetchUserOrders(userId);
      return allOrders.where((order) => order.status == 'Completed').toList();
    } catch (e) {
      throw Exception("Error fetching completed orders: $e");
    }
  }

  Future<ProductModel?> _getProductDetails(String productId) async {
    if (_productCache.containsKey(productId)) {
      return _productCache[productId];
    }

    try {
      ProductModel? product = await _productViewModel.fetchProductById(productId);
      setState(() {
        _productCache[productId] = product;
      });
      return product;
    } catch (e) {
      print("Error fetching product details: $e");
      return null;
    }
  }

  void _showReviewDialog(ProductModel product, String userId) {
    double _rating = 3.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Give Review"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Rate the product from 1 to 5"),
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _rating.toString(),
                    onChanged: (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _submitReview(product, userId, _rating.toInt());
                    Navigator.pop(context);
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview(ProductModel product, String userId, int rating) async {
    final reviewEntry = "$userId: $rating";
    product.reviews.add(reviewEntry);

    await _productViewModel.updateProduct(product);

    setState(() {
      _productCache[product.id] = product;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review submitted successfully!")),
    );
  }
}
