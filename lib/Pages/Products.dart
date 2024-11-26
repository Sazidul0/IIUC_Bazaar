import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:iiuc_bazaar/MVVM/Models/productModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/cardModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/productViewModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/cardViewModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Products extends StatefulWidget {
  final String? filterKeyword; // Accept a filter keyword for filtering
  const Products({Key? key, this.filterKeyword}) : super(key: key);

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  final ProductViewModel productViewModel = ProductViewModel();
  final CartViewModel cartViewModel = CartViewModel();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  String _searchQuery = "";
  String _selectedSortOption = "Default";
  bool _isLoading = false;
  String _userType = ''; // To track the user's type (buyer or seller)

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _fetchUserType();
  }

  /// Load products and apply filtering if a keyword is provided
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<ProductModel> products = await productViewModel.fetchAllProducts();

      // Apply filter if a keyword is provided
      if (widget.filterKeyword != null) {
        products = products.where((product) {
          final keyword = widget.filterKeyword!.toLowerCase();
          return product.name.toLowerCase().contains(keyword) ||
              product.description.toLowerCase().contains(keyword);
        }).toList();
      }

      setState(() {
        _products = products;
        _filteredProducts = products;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching products: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetch the user type (buyer or seller) from Firestore
  Future<void> _fetchUserType() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userType = userDoc['userType']; // Assume 'userType' field contains 'buyer' or 'seller'
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user type: $e")),
      );
    }
  }

  /// Calculate the average review rating for a product
  double _calculateAverageRating(List<String> reviews) {
    if (reviews.isEmpty) return 0.0;

    double totalRating = 0.0;
    int count = 0;

    for (String review in reviews) {
      final parts = review.split(":");
      if (parts.length == 2) {
        final rating = double.tryParse(parts[1]);
        if (rating != null) {
          totalRating += rating;
          count++;
        }
      }
    }

    return count > 0 ? totalRating / count : 0.0;
  }

  /// Search products
  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  /// Sort products
  void _sortProducts(String option) {
    setState(() {
      _selectedSortOption = option;
      if (option == "Price: High to Low") {
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
      } else if (option == "Price: Low to High") {
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
      } else {
        _filteredProducts = List.from(_products); // Default order
      }
    });
  }

  /// Show pop-up messages
  void _showPopup(BuildContext context, String message, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title:  Text("   Products", style: GoogleFonts.poppins(fontSize: 20, color: HexColor("#8d8d8d")),),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final selectedOption = await showModalBottomSheet<String>(
                context: context,
                builder: (context) {
                  return ListView(
                    children: [
                      ListTile(
                        title: const Text("Default"),
                        onTap: () => Navigator.pop(context, "Default"),
                      ),
                      ListTile(
                        title: const Text("Price: Low to High"),
                        onTap: () => Navigator.pop(context, "Price: Low to High"),
                      ),
                      ListTile(
                        title: const Text("Price: High to Low"),
                        onTap: () => Navigator.pop(context, "Price: High to Low"),
                      ),
                    ],
                  );
                },
              );
              if (selectedOption != null) _sortProducts(selectedOption);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(17.0),
          child: Column(
            children: [
              // Search bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: _searchProducts,
                      decoration: InputDecoration(
                        hintText: "Search products",
                        fillColor: HexColor("#f0f3f1"),
                        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        hintStyle: GoogleFonts.poppins(fontSize: 15, color: HexColor("#8d8d8d")),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        prefixIcon: Icon(Icons.search, color: HexColor("#4f4f4f")),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Product list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredProducts.isEmpty
                    ? const Center(child: Text("No products found"))
                    : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    final averageRating = _calculateAverageRating(product.reviews);

                    return Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Card(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 90,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(product.imageBase64),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${product.name} (${product.quantity})",
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              "\৳${product.price}",
                              style: const TextStyle(fontSize: 12, color: Colors.red),
                            ),

                            Text(
                              product.description,
                              style: const TextStyle(fontSize: 10),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star, color: Colors.yellow, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      averageRating.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_shopping_cart),
                                  onPressed: () async {
                                    if (_userType == 'Seller') {
                                      _showPopup(context,
                                          "Sellers cannot add products to the cart.", "Access Denied");
                                      return;
                                    }

                                    if (product.quantity == 0) {
                                      _showPopup(context, "No more product left", "Stock Limit");
                                      return;
                                    }

                                    try {
                                      CartModel cartItem = CartModel(
                                        userId: user!.uid,
                                        productId: product.id,
                                        name: product.name,
                                        quantity: 1,
                                        price: product.price,
                                        imageBase64: product.imageBase64,
                                      );
                                      await cartViewModel.addToCart(cartItem);
                                      _showPopup(context,
                                          "Product added to cart successfully.", "Success");
                                    } catch (e) {
                                      _showPopup(context,
                                          "Error adding product to cart: $e", "Error");
                                    }
                                  },
                                ),
                              ],
                            )

                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
