import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iiuc_bazaar/MVVM/Models/orderModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/cardModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/orderViewModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/productViewModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/cardViewModel.dart';
import 'package:iiuc_bazaar/MVVM/View Model/notificationViewModel.dart';
import 'package:iiuc_bazaar/Navigation/Buttom_Nav_Bar.dart';
import '../Payment/StripeService.dart';
import '../../MVVM/Models/productModel.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartModel> products;
  final double totalPrice;

  const CheckoutPage({
    required this.products,
    required this.totalPrice,
    Key? key,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final OrderViewModel _orderViewModel = OrderViewModel();
  final ProductViewModel _productViewModel = ProductViewModel();
  final CartViewModel _cartViewModel = CartViewModel();
  final NotificationViewModel _notificationViewModel = NotificationViewModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isProcessing = false;
  String? _selectedLocation;
  final List<String> _locations = ['FAZ', 'C Building', 'CX Building', 'CXB Building'];

  Future<void> _initiatePayment() async {
    if (_auth.currentUser == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a delivery location before proceeding.")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await StripeService.instance.makePayment(widget.totalPrice);

      await _handleOrderCreation("Payment Successful");

      await _notificationViewModel.addNotification(
        userId: _auth.currentUser!.uid,
        title: "Payment Successful",
        message: "Your payment of \৳${widget.totalPrice.toStringAsFixed(2)} was successful.\nDelivery Location: $_selectedLocation",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Successful")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyBottomNavBar(initialIndex: 0),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing payment: $e")),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleCashOnDelivery() async {
    if (_auth.currentUser == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a delivery location before proceeding.")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _handleOrderCreation("Cash on Delivery");

      await _notificationViewModel.addNotification(
        userId: _auth.currentUser!.uid,
        title: "Order Placed",
        message: "Order placed successfully with Cash on Delivery.\nDelivery Location: $_selectedLocation. Pending payment \৳${widget.totalPrice.toStringAsFixed(2)}",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed with Cash on Delivery")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyBottomNavBar(initialIndex: 0),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing order: $e")),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleOrderCreation(String paymentType) async {
    try {
      for (var product in widget.products) {
        await _createOrder(product, paymentType);
        await _updateProductStock(product);
        await _cartViewModel.removeFromCart(
          _auth.currentUser!.uid,
          product.productId,
        );
      }
    } catch (e) {
      throw Exception("Error handling order creation: $e");
    }
  }

  Future<void> _createOrder(CartModel product, String paymentType) async {
    ProductModel? productModel = await _productViewModel.fetchProductById(product.productId);

    if (productModel == null) {
      throw Exception("Product not found");
    }

    String orderId = DateTime.now().millisecondsSinceEpoch.toString();
    OrderModel order = OrderModel(
      id: orderId,
      userId: _auth.currentUser!.uid,
      productId: product.productId,
      quantity: product.quantity,
      totalPrice: product.quantity * product.price,
      status: 'Pending',
      orderDate: DateTime.now(),
      sellerId: productModel.sellerId,
    );

    await _orderViewModel.placeOrder(order);

    String notificationMessage =
    paymentType == "Cash on Delivery"
        ? "New Cash on Delivery order for ${product.name}.\nDelivery Location: $_selectedLocation. Will pay on hand \৳${widget.totalPrice.toStringAsFixed(2)}"
        : "You have received a new order for ${product.name}.\nDelivery Location: $_selectedLocation. Paid \৳${widget.totalPrice.toStringAsFixed(2)}";

    await _notificationViewModel.addNotification(
      userId: productModel.sellerId,
      title: paymentType == "Cash on Delivery" ? "New Cash on Delivery Order" : "New Order Received",
      message: notificationMessage,
    );
  }

  Future<void> _updateProductStock(CartModel product) async {
    try {
      ProductModel? productModel = await _productViewModel.fetchProductById(product.productId);
      if (productModel != null) {
        productModel.quantity -= product.quantity;
        await _productViewModel.updateProduct(productModel);
      }
    } catch (e) {
      throw Exception("Error updating product stock: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Summary",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Column(
              children: widget.products.map((product) {
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text("Quantity: ${product.quantity}"),
                  trailing: Text(
                    "\৳${(product.quantity * product.price).toStringAsFixed(2)}",
                  ),
                );
              }).toList(),
            ),
            const Divider(),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              hint: const Text("Select Delivery Location"),
              isExpanded: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                icon: Icon(Icons.location_on, color: Colors.blue),
              ),
              items: _locations.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value;
                });
              },
            ),
            const Divider(),
            Text(
              "Total: \৳${widget.totalPrice.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _initiatePayment,
                    child: const SizedBox(
                      width: 150,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card_outlined),
                          SizedBox(width: 8),
                          Text("Pay Now"),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _handleCashOnDelivery,
                    child: const SizedBox(
                      width: 150,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping),
                          SizedBox(width: 8),
                          Text("Cash on Delivery"),
                        ],
                      ),
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
