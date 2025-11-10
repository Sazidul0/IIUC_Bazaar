import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iiuc_bazaar/MVVM/Models/productModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/productViewModel.dart';
import 'package:iiuc_bazaar/Pages/Seller/ProductUpdateDialog.dart';

class UpdateProductsPage extends StatefulWidget {
  final String sellerId; // Pass seller ID

  UpdateProductsPage({required this.sellerId});

  @override
  _UpdateProductsPageState createState() => _UpdateProductsPageState();
}

class _UpdateProductsPageState extends State<UpdateProductsPage> {
  final ProductViewModel productViewModel = ProductViewModel();
  late Future<List<ProductModel>> _sellerProducts;

  @override
  void initState() {
    super.initState();
    _loadSellerProducts();
  }

  // Function to load products of the seller
  void _loadSellerProducts() {
    setState(() {
      _sellerProducts = productViewModel.fetchAllProductsBySeller(widget.sellerId);
    });
  }

  // Open popup for product update
  void _showUpdatePopup(ProductModel product) {
    if (product.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Product ID is missing!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ProductUpdateDialog(product: product),
    ).then((success) {
      if (success == true) {
        // Reload the products after the dialog is closed
        _loadSellerProducts();
      }
    });
  }

  // Confirm and delete product
  void _showDeleteConfirmationDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text("Are you sure you want to delete ${product.name}?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await productViewModel.deleteProduct(product.id);
              Navigator.pop(context); // Close the confirmation dialog
              _loadSellerProducts(); // Reload products list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Product deleted successfully")),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Products")),
      body: Padding(
        padding: const EdgeInsets.all(21.0),
        child: FutureBuilder<List<ProductModel>>(
          future: _sellerProducts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No products found"));
            }

            List<ProductModel> products = snapshot.data!;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Card(
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Image.memory(
                            base64Decode(product.imageBase64),
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          Text(
                            "${product.name}(${product.quantity.toString()})",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            "\৳${product.price.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            product.description,
                            style: const TextStyle(fontSize: 8),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showUpdatePopup(product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _showDeleteConfirmationDialog(product),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
