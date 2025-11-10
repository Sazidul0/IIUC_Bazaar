import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:iiuc_bazaar/MVVM/Models/cardModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/cardViewModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/productViewModel.dart';
import 'package:iiuc_bazaar/Pages/Buyer/CheckoutPage.dart';
import '../MVVM/Models/productModel.dart';

class Cart extends StatefulWidget {
  const Cart({Key? key}) : super(key: key);

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final CartViewModel _cartViewModel = CartViewModel();
  final ProductViewModel _productViewModel = ProductViewModel();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<CartModel> _cartItems = [];
  Map<String, bool> _selectedItems = {}; // Tracks selected products for checkout
  double _totalPrice = 0.0;
  bool _isLoading = false; // Track loading state

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  /// Fetch cart items for the logged-in user
  Future<void> _loadCartItems() async {
    if (_currentUser == null) return;
    setState(() {
      _isLoading = true; // Set loading to true when fetching data
    });
    try {
      List<CartModel> items =
      await _cartViewModel.fetchCartItems(_currentUser!.uid);
      setState(() {
        _cartItems = items;
        _selectedItems = {
          for (var item in items) item.productId: false, // Initialize selection
        };
        _isLoading = false; // Set loading to false when data is fetched
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Stop loading on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching cart items: $e")),
      );
    }
  }

  /// Fetch the maximum stock available for a product
  Future<int> _fetchProductStock(String productId) async {
    try {
      final products = await _productViewModel.fetchAllProducts();
      final product = products.firstWhere(
            (p) => p.id == productId,
        orElse: () => ProductModel(
          id: '',
          name: '',
          description: '',
          price: 0.0,
          imageBase64: '',
          reviews: [],
          sellerId: '',
          quantity: 0, // Default quantity
        ),
      );
      return product.quantity; // Return the quantity of the found product
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching product stock: $e")),
      );
      return 0;
    }
  }

  /// Update the quantity of an item
  Future<void> _updateQuantity(CartModel item, int change) async {
    if (_currentUser == null) return;
    setState(() {
      _isLoading = true; // Set loading to true during update
    });
    int newQuantity = item.quantity + change;
    if (newQuantity < 1) return;

    // Fetch the maximum stock for the product
    int maxStock = await _fetchProductStock(item.productId);

    if (newQuantity > maxStock) {
      _showPopup("No more product left", "Stock Limit");
      setState(() {
        _isLoading = false; // Stop loading
      });
      return;
    }

    try {
      CartModel updatedItem = CartModel(
        userId: item.userId,
        productId: item.productId,
        name: item.name,
        quantity: newQuantity,
        price: item.price,
        imageBase64: item.imageBase64,
      );

      await _cartViewModel.addToCart(updatedItem); // Update in Firestore
      setState(() {
        _cartItems[_cartItems.indexOf(item)] = updatedItem;
        _isLoading = false; // Stop loading
      });
      _calculateTotalPrice();
    } catch (e) {
      setState(() {
        _isLoading = false; // Stop loading on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating quantity: $e")),
      );
    }
  }

  /// Delete an item from the cart
  Future<void> _deleteItem(CartModel item) async {
    if (_currentUser == null) return;
    setState(() {
      _isLoading = true; // Set loading to true during delete
    });
    try {
      await _cartViewModel.removeFromCart(_currentUser!.uid, item.productId);
      setState(() {
        _cartItems.remove(item);
        _selectedItems.remove(item.productId);
        _isLoading = false; // Stop loading
      });
      _calculateTotalPrice();
    } catch (e) {
      setState(() {
        _isLoading = false; // Stop loading on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting item: $e")),
      );
    }
  }

  /// Calculate total price of selected items
  void _calculateTotalPrice() {
    double total = 0.0;
    for (var item in _cartItems) {
      if (_selectedItems[item.productId] == true) {
        total += item.quantity * item.price;
      }
    }
    setState(() {
      _totalPrice = total;
    });
  }

  /// Show popup
  void _showPopup(String message, String title) {
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

  /// Navigate to payment page with selected items
  void _checkout() {
    List<CartModel> selectedProducts = _cartItems
        .where((item) => _selectedItems[item.productId] == true)
        .toList();

    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No products selected for checkout")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          products: selectedProducts,
          totalPrice: _totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("   Cart", style: GoogleFonts.poppins(fontSize: 20, color: HexColor("#8d8d8d")),)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator while processing
          : _cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                CartModel item = _cartItems[index];
                return Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Card(
                    margin: const EdgeInsets.all(3),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 0, right: 0),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _selectedItems[item.productId],
                              onChanged: (bool? value) {
                                setState(() {
                                  _selectedItems[item.productId] =
                                      value ?? false;
                                  _calculateTotalPrice();
                                });
                              },
                            ),
                            ClipOval(
                              child: Image.memory(
                                base64Decode(item.imageBase64),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name.length > 5
                                  ? '${item.name.substring(0, 5)}...'
                                  : item.name,
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _updateQuantity(item, -1),
                            ),
                            Text(item.quantity.toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _updateQuantity(item, 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(item),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Total Price: \৳${_totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _checkout,
                  child: const Text("Checkout"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}