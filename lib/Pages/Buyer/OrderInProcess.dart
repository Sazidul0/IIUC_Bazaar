import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/orderViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/orderModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/productViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/productModel.dart';

class OrderInProcessPage extends StatefulWidget {
  const OrderInProcessPage({Key? key}) : super(key: key);

  @override
  State<OrderInProcessPage> createState() => _OrderInProcessPageState();
}

class _OrderInProcessPageState extends State<OrderInProcessPage> {
  final OrderViewModel _orderViewModel = OrderViewModel();
  final ProductViewModel _productViewModel = ProductViewModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Map to store product details by productId
  Map<String, ProductModel?> _productCache = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Orders in Process")),
        body: const Center(
          child: Text("You must be logged in to view your orders."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Orders in Process")),
      body: FutureBuilder<List<OrderModel>>(
        future: _fetchPendingOrders(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No pending orders."));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final order = snapshot.data![index];

                // Fetch product details by productId
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

  // Fetch orders only for the current user and filter by "Pending" status
  Future<List<OrderModel>> _fetchPendingOrders(String userId) async {
    try {
      final allOrders = await _orderViewModel.fetchUserOrders(userId);
      // Filter the orders to return only those with status "Pending"
      return allOrders.where((order) => order.status == 'Pending').toList();
    } catch (e) {
      throw Exception("Error fetching pending orders: $e");
    }
  }

  // Fetch product details by productId
  Future<ProductModel?> _getProductDetails(String productId) async {
    if (_productCache.containsKey(productId)) {
      return _productCache[productId]; // Return from cache if already fetched
    }

    try {
      ProductModel? product = await _productViewModel.fetchProductById(productId);
      setState(() {
        _productCache[productId] = product; // Cache the product details
      });
      return product;
    } catch (e) {
      print("Error fetching product details: $e");
      return null;
    }
  }
}
