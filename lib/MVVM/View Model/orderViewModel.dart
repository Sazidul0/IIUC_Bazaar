import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/orderModel.dart';

class OrderViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Place an order in Firestore
  Future<void> placeOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.id).set(order.toMap());
    } catch (e) {
      throw Exception("Error placing order: $e");
    }
  }

  // Create an order, validate and pass it to placeOrder
  Future<void> createOrder({
    required String userId,
    required String productId,
    required int quantity,
    required double totalPrice,
    required String sellerId,
  }) async {
    // Step 1: Validate input data
    if (userId.isEmpty || productId.isEmpty || quantity <= 0 || totalPrice <= 0.0 || sellerId.isEmpty) {
      throw Exception("Invalid order data.");
    }

    // Step 2: Generate a unique ID for the order
    String orderId = _generateOrderId();

    // Step 3: Create an order object
    OrderModel newOrder = OrderModel(
      id: orderId,
      userId: userId,
      productId: productId,
      quantity: quantity,
      totalPrice: totalPrice,
      status: 'Pending', // You can customize the status as needed
      orderDate: DateTime.now(),
      sellerId: sellerId,
    );

    // Step 4: Place the order
    await placeOrder(newOrder);
  }

  // Fetch orders for a user
  Future<List<OrderModel>> fetchUserOrders(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Error fetching user orders: $e");
    }
  }

  // Fetch orders for a seller
  Future<List<OrderModel>> fetchSellerOrders(String sellerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Error fetching seller orders: $e");
    }
  }

  // Search orders by sellerId (for more specific queries, e.g., Pending orders)
  Future<List<OrderModel>> searchOrderBySellerId(String sellerId, {String? status}) async {
    try {
      var query = _firestore.collection('orders').where('sellerId', isEqualTo: sellerId);

      // If a status is provided, filter by status as well
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Error searching orders by sellerId: $e");
    }
  }

  // Search orders by userId
  Future<List<OrderModel>> searchOrderByUserId(String userId, {String? status}) async {
    try {
      var query = _firestore.collection('orders').where('userId', isEqualTo: userId);

      // If a status is provided, filter by status as well
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Error searching orders by userId: $e");
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({'status': status});
    } catch (e) {
      throw Exception("Error updating order status: $e");
    }
  }

  // Add this method in your OrderViewModel class
  Future<List<OrderModel>> fetchCompletedSales(String sellerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .where('status', isEqualTo: 'Completed')
          .get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Error fetching completed sales: $e");
    }
  }



  // Helper method to generate a unique order ID (could be a UUID, timestamp, etc.)
  String _generateOrderId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
