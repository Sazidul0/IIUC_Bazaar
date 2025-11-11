import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iiuc_bazaar/MVVM/Models/cardModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/cardViewModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/productViewModel.dart';
import 'package:iiuc_bazaar/Pages/Buyer/CheckoutPage.dart';
import '../MVVM/Models/productModel.dart';

class Cart extends StatefulWidget {
  const Cart({Key? key}) : super(key: key);

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  // --- All your original state and logic is preserved ---
  final CartViewModel _cartViewModel = CartViewModel();
  final ProductViewModel _productViewModel = ProductViewModel();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<CartModel> _cartItems = [];
  Map<String, bool> _selectedItems = {};
  double _totalPrice = 0.0;
  bool _isLoading = true; // Start in loading state

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _loadCartItems();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);
    try {
      List<CartModel> items = await _cartViewModel.fetchCartItems(_currentUser!.uid);
      if (mounted) {
        setState(() {
          _cartItems = items;
          _selectedItems = {for (var item in items) item.productId: true}; // Select all by default
          _calculateTotalPrice();
        });
      }
    } catch (e) {
      if (mounted) Get.snackbar("Error", "Failed to fetch cart items: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<int> _fetchProductStock(String productId) async {
    try {
      ProductModel? product = await _productViewModel.fetchProductById(productId);
      return product?.quantity ?? 0;
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch product stock: $e");
      return 0;
    }
  }

  Future<void> _updateQuantity(CartModel item, int change) async {
    int newQuantity = item.quantity + change;
    if (newQuantity < 1) return;

    int maxStock = await _fetchProductStock(item.productId);
    if (newQuantity > maxStock) {
      Get.snackbar("Stock Limit", "Only $maxStock items are available.", snackPosition: SnackPosition.TOP);
      return;
    }

    try {
      CartModel updatedItem = CartModel(
        userId: item.userId, productId: item.productId, name: item.name,
        quantity: newQuantity, price: item.price, imageBase64: item.imageBase64,
      );
      await _cartViewModel.addToCart(updatedItem);
      if (mounted) {
        setState(() {
          _cartItems[_cartItems.indexOf(item)] = updatedItem;
          _calculateTotalPrice();
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update quantity: $e");
    }
  }

  Future<void> _deleteItem(CartModel item) async {
    try {
      await _cartViewModel.removeFromCart(_currentUser!.uid, item.productId);
      if (mounted) {
        setState(() {
          _cartItems.remove(item);
          _selectedItems.remove(item.productId);
          _calculateTotalPrice();
        });
        Get.snackbar("Success", "'${item.name}' removed from cart.", snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to delete item: $e");
    }
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    for (var item in _cartItems) {
      if (_selectedItems[item.productId] == true) {
        total += item.quantity * item.price;
      }
    }
    if (mounted) setState(() => _totalPrice = total);
  }

  void _checkout() {
    List<CartModel> selectedProducts = _cartItems
        .where((item) => _selectedItems[item.productId] == true)
        .toList();

    if (selectedProducts.isEmpty) {
      Get.snackbar("No Items Selected", "Please select items to checkout.");
      return;
    }

    Get.to(() => CheckoutPage(products: selectedProducts, totalPrice: _totalPrice));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("My Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
      ),
      body: _currentUser == null
          ? _buildLoggedOutView()
          : Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildLoadingShimmer()
                : _cartItems.isEmpty
                ? _buildEmptyCart()
                : ListView.builder(
              padding: EdgeInsets.all(Get.width * 0.03),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                CartModel item = _cartItems[index];
                return CartItemCard(
                  item: item,
                  isSelected: _selectedItems[item.productId] ?? false,
                  onItemSelected: (isSelected) {
                    setState(() {
                      _selectedItems[item.productId] = isSelected;
                      _calculateTotalPrice();
                    });
                  },
                  onQuantityChanged: (change) => _updateQuantity(item, change),
                  onDelete: () => _deleteItem(item),
                );
              },
            ),
          ),
          // --- Beautiful Sticky Checkout Bar ---
          if (!_isLoading && _cartItems.isNotEmpty) _buildCheckoutBar(),
        ],
      ),
    );
  }

  // --- UI Builder Methods ---
  Widget _buildLoggedOutView() => Center(child: Text("Please log in to view your cart.", style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.04)));
  Widget _buildEmptyCart() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shopping_cart_outlined, size: Get.width * 0.25, color: Colors.grey[300]),
        SizedBox(height: Get.width * 0.05),
        Text("Your Cart is Empty", style: GoogleFonts.poppins(fontSize: Get.width * 0.055, fontWeight: FontWeight.w600, color: Colors.black54)),
        SizedBox(height: Get.width * 0.02),
        Text("Add items to get started.", style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.04, color: Colors.grey[500])),
        SizedBox(height: Get.width * 0.08),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal, foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: Get.width * 0.1, vertical: Get.width * 0.03),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: () => Get.back(), // Or navigate to home page
          child: Text("Go Shopping", style: GoogleFonts.poppins(fontSize: Get.width * 0.04, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  Widget _buildCheckoutBar() => Container(
    padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05, vertical: Get.width * 0.04),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
    ),
    child: SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Total Price", style: GoogleFonts.nunitoSans(fontSize: Get.width * 0.035, color: Colors.grey[600])),
              SizedBox(height: Get.width * 0.01),
              Text("\৳${_totalPrice.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: Get.width * 0.055, fontWeight: FontWeight.bold)),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: Get.width * 0.1, vertical: Get.width * 0.035),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: _checkout,
            child: Text("Checkout", style: GoogleFonts.poppins(fontSize: Get.width * 0.04, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
  Widget _buildLoadingShimmer() => ListView.builder(
    padding: EdgeInsets.all(Get.width * 0.03),
    itemCount: 5,
    itemBuilder: (context, index) => Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.only(bottom: Get.width * 0.04),
        height: Get.width * 0.28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Get.width * 0.04),
        ),
      ),
    ),
  );
}

// --- BEAUTIFUL, DYNAMIC, AND REUSABLE CART ITEM CARD ---
class CartItemCard extends StatelessWidget {
  final CartModel item;
  final bool isSelected;
  final ValueChanged<bool> onItemSelected;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onDelete;

  const CartItemCard({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.onItemSelected,
    required this.onQuantityChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = Get.width;

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      padding: EdgeInsets.all(screenWidth * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Row(
        children: [
          Checkbox(value: isSelected, onChanged: (value) => onItemSelected(value ?? false), activeColor: Colors.teal),
          ClipRRect(
            borderRadius: BorderRadius.circular(screenWidth * 0.025),
            child: Image.memory(
              base64Decode(item.imageBase64),
              width: screenWidth * 0.2, height: screenWidth * 0.2, fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(width: screenWidth * 0.2, height: screenWidth * 0.2, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600)),
                SizedBox(height: screenWidth * 0.01),
                Text("\৳${item.price.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
              ],
            ),
          ),
          Column(
            children: [
              _buildQuantityControl(screenWidth),
              IconButton(icon: Icon(Icons.delete_outline, color: Colors.red, size: screenWidth * 0.05), onPressed: onDelete, splashRadius: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.remove, size: screenWidth * 0.04), onPressed: () => onQuantityChanged(-1), splashRadius: 20, constraints: const BoxConstraints()),
          Text(item.quantity.toString(), style: GoogleFonts.poppins(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold)),
          IconButton(icon: Icon(Icons.add, size: screenWidth * 0.04), onPressed: () => onQuantityChanged(1), splashRadius: 20, constraints: const BoxConstraints()),
        ],
      ),
    );
  }
}