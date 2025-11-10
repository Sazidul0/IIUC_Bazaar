import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/cardModel.dart';

class CartViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add or update a cart item in Firestore
  Future<void> addToCart(CartModel cartItem) async {
    try {
      await _firestore
          .collection('carts')
          .doc(cartItem.userId)
          .collection('items')
          .doc(cartItem.productId)
          .set(cartItem.toMap());
    } catch (e) {
      throw Exception("Error adding to cart: $e");
    }
  }

  /// Fetch all cart items for a specific user
  Future<List<CartModel>> fetchCartItems(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();

      return snapshot.docs
          .map((doc) => CartModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Error fetching cart items: $e");
    }
  }

  /// Remove an item from the user's cart
  Future<void> removeFromCart(String userId, String productId) async {
    try {
      await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception("Error removing item from cart: $e");
    }
  }
}
