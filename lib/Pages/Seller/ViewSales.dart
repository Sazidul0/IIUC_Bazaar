import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/orderViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/orderModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/productViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/productModel.dart';

class ViewSalesPage extends StatefulWidget {
  const ViewSalesPage({Key? key}) : super(key: key);

  @override
  _ViewSalesPageState createState() => _ViewSalesPageState();
}

class _ViewSalesPageState extends State<ViewSalesPage> {
  final OrderViewModel _orderViewModel = OrderViewModel();
  final ProductViewModel _productViewModel = ProductViewModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String sellerId;

  // Map to store product details by productId
  Map<String, ProductModel?> _productCache = {};

  @override
  void initState() {
    super.initState();
    sellerId = _auth.currentUser!.uid; // Get the seller's UID
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("View Completed Sales")),
      body: FutureBuilder<List<OrderModel>>(
        future: _orderViewModel.fetchCompletedSales(sellerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No completed sales."));
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
                          trailing: Text("Total: \৳${order.totalPrice}"),
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
}
