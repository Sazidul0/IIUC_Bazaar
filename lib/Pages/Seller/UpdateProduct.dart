import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import GetX for screen size
import 'package:google_fonts/google_fonts.dart';
import 'package:iiuc_bazaar/MVVM/Models/productModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/productViewModel.dart';
import 'package:iiuc_bazaar/Pages/Seller/ProductUpdateDialog.dart';

class UpdateProductsPage extends StatefulWidget {
  final String sellerId;

  const UpdateProductsPage({Key? key, required this.sellerId}) : super(key: key);

  @override
  _UpdateProductsPageState createState() => _UpdateProductsPageState();
}

class _UpdateProductsPageState extends State<UpdateProductsPage> {
  // --- All your existing logic is preserved ---
  final ProductViewModel productViewModel = ProductViewModel();
  late Future<List<ProductModel>> _sellerProducts;

  @override
  void initState() {
    super.initState();
    _loadSellerProducts();
  }

  void _loadSellerProducts() {
    setState(() {
      _sellerProducts = productViewModel.fetchAllProductsBySeller(widget.sellerId);
    });
  }

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
      if (success == true) _loadSellerProducts();
    });
  }

  void _showDeleteConfirmationDialog(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete '${product.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              try {
                await productViewModel.deleteProduct(product.id);
                if (!mounted) return;
                Navigator.pop(context);
                _loadSellerProducts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Product deleted successfully")),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to delete product: $e")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- DYNAMIC SIZING BASED ON SCREEN WIDTH ---
    final double screenWidth = Get.width;

    // Calculate a dynamic aspect ratio.
    // We aim for a ratio of about 0.75 on a standard ~400px wide phone.
    // The calculation here ensures the card height is roughly 55-60% of the screen width.
    final double itemWidth = (screenWidth - (screenWidth * 0.08) - (screenWidth * 0.04)) / 2;
    final double itemHeight = screenWidth * 0.58;
    final double childAspectRatio = itemWidth / itemHeight;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Manage Your Products", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _sellerProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString(), screenWidth);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyView(screenWidth);
          }

          List<ProductModel> products = snapshot.data!;
          return GridView.builder(
            // Use proportional padding and spacing
            padding: EdgeInsets.all(screenWidth * 0.04), // e.g., 16 on a 400px screen
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: screenWidth * 0.04,
              mainAxisSpacing: screenWidth * 0.04,
              childAspectRatio: childAspectRatio, // Use the fully dynamic aspect ratio
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductGridCard(
                product: product,
                onEdit: () => _showUpdatePopup(product),
                onDelete: () => _showDeleteConfirmationDialog(product),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyView(double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: screenWidth * 0.2, color: Colors.grey[400]),
          SizedBox(height: screenWidth * 0.04),
          Text(
            "No Products Found",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.05, // Proportional font size
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            "Add your first product to see it here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(fontSize: screenWidth * 0.04, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error, double screenWidth) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Text(
          "Something went wrong:\n$error",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunitoSans(fontSize: screenWidth * 0.04, color: Colors.red[700]),
        ),
      ),
    );
  }
}

// --- FULLY DYNAMIC AND RESPONSIVE PRODUCT CARD WIDGET ---
class ProductGridCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductGridCard({
    Key? key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<ProductGridCard> createState() => _ProductGridCardState();
}

class _ProductGridCardState extends State<ProductGridCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width once for all calculations in this widget
    final double screenWidth = Get.width;

    return FadeTransition(
      opacity: _animation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04), // Proportional radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.04)),
                    child: Image.memory(
                      base64Decode(widget.product.imageBase64),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    top: screenWidth * 0.02,
                    right: screenWidth * 0.02,
                    child: Chip(
                      label: Text(
                        "Qty: ${widget.product.quantity}",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.03), // Proportional font
                      ),
                      backgroundColor: Colors.black.withOpacity(0.5),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.025), // Proportional padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04, // Proportional font
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "\৳${widget.product.price.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035, // Proportional font
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: widget.onEdit,
                  icon: Icon(Icons.edit_outlined, size: screenWidth * 0.045, color: Colors.blue.shade700), // Proportional icon
                  label: Text("Edit", style: GoogleFonts.poppins(fontSize: screenWidth * 0.035, color: Colors.blue.shade700)), // Proportional font
                ),
                TextButton.icon(
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete_outline, size: screenWidth * 0.045, color: Colors.red.shade700), // Proportional icon
                  label: Text("Del", style: GoogleFonts.poppins(fontSize: screenWidth * 0.035, color: Colors.red.shade700)), // Proportional font
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}