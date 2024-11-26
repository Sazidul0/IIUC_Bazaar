import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/productModel.dart';

class ProductViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all products
  Future<List<ProductModel>> fetchAllProducts() async {
    try {
      final querySnapshot = await _firestore.collection('products').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ProductModel.fromJson({
          ...data,
          'id': doc.id, // Ensure the Firestore document ID is included
        });
      }).toList();
    } catch (e) {
      print("Error fetching all products: $e");
      return [];
    }
  }

  // Fetch products by seller ID
  Future<List<ProductModel>> fetchAllProductsBySeller(String sellerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ProductModel.fromJson({
          ...data,
          'id': doc.id, // Include Firestore document ID
        });
      }).toList();
    } catch (e) {
      print("Error fetching products for seller $sellerId: $e");
      return [];
    }
  }

  // Add a new product
  Future<String?> addProduct(ProductModel product) async {
    try {
      // Add the product to Firestore
      final docRef = await _firestore.collection('products').add(product.toJson());

      // Get the generated ID and update the document with the 'id' field
      await docRef.update({'id': docRef.id});

      print("Product added successfully with ID: ${docRef.id}");
      return docRef.id; // Returning the ID of the newly created product
    } catch (e) {
      print("Error adding product: $e");
      return null;
    }
  }

  // Fetch a product by its ID
  Future<ProductModel?> fetchProductById(String productId) async {
    try {
      // Query Firestore for a product document with the specified productId
      final docSnapshot = await _firestore.collection('products').doc(productId).get();

      // If the document exists, map it to the ProductModel, otherwise return null
      if (docSnapshot.exists) {
        return ProductModel.fromJson({
          ...docSnapshot.data()!,
          'id': docSnapshot.id, // Include Firestore document ID
        });
      } else {
        print("Product with ID $productId not found.");
        return null; // Return null if the product does not exist
      }
    } catch (e) {
      print("Error fetching product by ID $productId: $e");
      return null; // Return null in case of an error
    }
  }

  // Update an existing product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore.collection('products').doc(product.id).update(product.toJson());
      print("Product updated successfully!");
    } catch (e) {
      print("Error updating product: $e");
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      print("Product deleted successfully!");
    } catch (e) {
      print("Error deleting product: $e");
    }
  }
}
