import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiuc_bazaar/MVVM/Models/productModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/cardModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/productViewModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/cardViewModel.dart';

class Products extends StatefulWidget {
  final String? filterKeyword;
  const Products({Key? key, this.filterKeyword}) : super(key: key);

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  // --- All your original state and logic is preserved ---
  final ProductViewModel productViewModel = ProductViewModel();
  final CartViewModel cartViewModel = CartViewModel();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  String _searchQuery = "";
  String _selectedSortOption = "Default";
  bool _isLoading = true; // Start with loading true
  String _userType = '';

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _fetchUserType();
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      List<ProductModel> products = await productViewModel.fetchAllProducts();
      if (widget.filterKeyword != null && widget.filterKeyword!.isNotEmpty) {
        final keyword = widget.filterKeyword!.toLowerCase();
        products = products.where((p) =>
        p.name.toLowerCase().contains(keyword) ||
            p.description.toLowerCase().contains(keyword)).toList();
      }
      setState(() {
        _products = products;
        _applyFiltersAndSort(); // Apply current search/sort to the new list
      });
    } catch (e) {
      if (mounted) Get.snackbar("Error", "Failed to fetch products: $e", snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserType() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        if (mounted) setState(() => _userType = userDoc['userType']);
      }
    } catch (e) {
      if (mounted) Get.snackbar("Error", "Could not fetch user type: $e", snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _applyFiltersAndSort() {
    List<ProductModel> tempProducts = List.from(_products);

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      tempProducts = tempProducts.where((p) =>
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Apply sorting
    if (_selectedSortOption == "Price: High to Low") {
      tempProducts.sort((a, b) => b.price.compareTo(a.price));
    } else if (_selectedSortOption == "Price: Low to High") {
      tempProducts.sort((a, b) => a.price.compareTo(b.price));
    }

    setState(() => _filteredProducts = tempProducts);
  }

  void _searchProducts(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
  }

  void _sortProducts(String option) {
    _selectedSortOption = option;
    _applyFiltersAndSort();
  }

  double _calculateAverageRating(List<String> reviews) {
    if (reviews.isEmpty) return 0.0;
    double total = 0.0;
    int count = 0;
    for (String review in reviews) {
      final rating = double.tryParse(review.split(":").last.trim());
      if (rating != null) {
        total += rating;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  void _showPopup(String message, String title) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: "OK",
      onConfirm: () => Get.back(),
    );
  }

  void _showSortOptions() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.sort),
              title: Text('Default', style: GoogleFonts.poppins()),
              onTap: () {
                _sortProducts('Default');
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: Text('Price: Low to High', style: GoogleFonts.poppins()),
              onTap: () {
                _sortProducts('Price: Low to High');
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: Text('Price: High to Low', style: GoogleFonts.poppins()),
              onTap: () {
                _sortProducts('Price: High to Low');
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = Get.width;
    final User? user = FirebaseAuth.instance.currentUser;

    // --- DYNAMIC GRIDVIEW SIZING ---
    final double itemWidth = (screenWidth - (screenWidth * 0.08) - (screenWidth * 0.04)) / 2;
    final double itemHeight = screenWidth * 0.6; // Slightly taller card for better look
    final double childAspectRatio = itemWidth / itemHeight;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Products", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.teal.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: Colors.teal.shade800),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Column(
          children: [
            SizedBox(height: screenWidth * 0.04),
            // --- Beautiful Search Bar ---
            TextField(
              onChanged: _searchProducts,
              decoration: InputDecoration(
                hintText: "Search products...",
                hintStyle: GoogleFonts.nunitoSans(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            // --- Product Grid ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : _filteredProducts.isEmpty
                  ? _buildEmptyView(screenWidth)
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: screenWidth * 0.04,
                  mainAxisSpacing: screenWidth * 0.04,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  final averageRating = _calculateAverageRating(product.reviews);

                  return ProductCard(
                    product: product,
                    averageRating: averageRating,
                    onAddToCart: () async {
                      if (user == null) {
                        _showPopup("You need to be logged in to shop.", "Authentication Required");
                        return;
                      }
                      if (_userType == 'Seller') {
                        _showPopup("Sellers cannot add products to the cart.", "Access Denied");
                        return;
                      }
                      if (product.quantity == 0) {
                        _showPopup("This product is out of stock.", "Out of Stock");
                        return;
                      }
                      try {
                        CartModel cartItem = CartModel(
                          userId: user.uid, productId: product.id, name: product.name,
                          quantity: 1, price: product.price, imageBase64: product.imageBase64,
                        );
                        await cartViewModel.addToCart(cartItem);
                        Get.snackbar(
                          "Success", "${product.name} added to cart!",
                          snackPosition: SnackPosition.TOP, backgroundColor: Colors.teal, colorText: Colors.white,
                        );
                      } catch (e) {
                        _showPopup("Error adding product to cart: $e", "Error");
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: screenWidth * 0.2, color: Colors.grey[400]),
          SizedBox(height: screenWidth * 0.04),
          Text(
            "No Products Found",
            style: GoogleFonts.poppins(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            "Try adjusting your search or filter.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(fontSize: screenWidth * 0.04, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// --- FULLY DYNAMIC AND RESPONSIVE PRODUCT CARD WIDGET ---
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double averageRating;
  final VoidCallback onAddToCart;

  const ProductCard({
    Key? key,
    required this.product,
    required this.averageRating,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = Get.width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    base64Decode(product.imageBase64),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                  if (product.quantity > 0)
                    Positioned(
                      top: screenWidth * 0.02,
                      left: screenWidth * 0.02,
                      child: Chip(
                        label: Text("Qty: ${product.quantity}", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.03)),
                        backgroundColor: Colors.black.withOpacity(0.5),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (product.quantity == 0)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Text("Out of Stock", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.025),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text("\৳${product.price.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenWidth * 0.01),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: screenWidth * 0.05),
                      SizedBox(width: screenWidth * 0.01),
                      Text(averageRating.toStringAsFixed(1), style: GoogleFonts.poppins(fontSize: screenWidth * 0.035, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  InkWell(
                    onTap: onAddToCart,
                    borderRadius: BorderRadius.circular(50),
                    child: CircleAvatar(
                      radius: screenWidth * 0.05,
                      backgroundColor: Colors.teal.shade50,
                      child: Icon(Icons.add_shopping_cart, color: Colors.teal.shade700, size: screenWidth * 0.05),
                    ),
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