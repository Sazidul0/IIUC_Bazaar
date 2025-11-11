import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/orderViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/orderModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/productViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/productModel.dart';
import 'package:timeago/timeago.dart' as timeago;

// A helper class to hold the combined data for a sale
class SaleDetail {
  final OrderModel order;
  final ProductModel product;

  SaleDetail({required this.order, required this.product});
}

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

  late Future<List<SaleDetail>> _salesFuture;

  @override
  void initState() {
    super.initState();
    sellerId = _auth.currentUser!.uid;
    _salesFuture = _fetchSalesAndProducts();
  }

  // Efficiently fetches all sales and their related product data at once
  Future<List<SaleDetail>> _fetchSalesAndProducts() async {
    List<OrderModel> orders = await _orderViewModel.fetchCompletedSales(sellerId);
    if (orders.isEmpty) {
      return [];
    }

    List<SaleDetail> saleDetails = [];

    for (var order in orders) {
      try {
        ProductModel? product = await _productViewModel.fetchProductById(order.productId);
        if (product != null) {
          saleDetails.add(SaleDetail(order: order, product: product));
        }
      } catch (e) {
        print("Error fetching product for order ${order.id}: $e");
      }
    }
    return saleDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Completed Sales", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal.shade600,
        centerTitle: true,
      ),
      body: FutureBuilder<List<SaleDetail>>(
        future: _salesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyView();
          } else {
            final sales = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final saleDetail = sales[index];
                return SaleCard(saleDetail: saleDetail);
              },
            );
          }
        },
      ),
    );
  }

  // --- UI BUILDER WIDGETS ---

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No Sales Yet",
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            "Completed sales will appear here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Something went wrong:\n$error",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunitoSans(color: Colors.red[700]),
        ),
      ),
    );
  }
}


// --- DYNAMIC & OVERFLOW-PROOF SALE CARD WIDGET ---

class SaleCard extends StatefulWidget {
  final SaleDetail saleDetail;

  const SaleCard({Key? key, required this.saleDetail}) : super(key: key);

  @override
  State<SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<SaleCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.saleDetail.order;
    final product = widget.saleDetail.product;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: product.imageBase64.isEmpty
                      ? Container(
                    width: 80, height: 80, color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                  )
                      : Image.memory(
                    base64Decode(product.imageBase64),
                    width: 80, height: 80, fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                // Product and Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order ID: ${order.id}',
                        style: GoogleFonts.nunitoSans(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      // This Row is now robust against overflow
                      Row(
                        children: [
                          // This Flexible widget prevents the date text from causing an overflow
                          Flexible(
                            child: Text(
                              'Sold ${timeago.format(order.orderDate)}', // <-- Remember to use your correct date field
                              overflow: TextOverflow.ellipsis, // Ensures it ends with ... if still too long
                              style: GoogleFonts.nunitoSans(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              order.status,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                            backgroundColor: Colors.teal.shade400,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Total Price
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    "\৳${order.totalPrice}",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}