import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../MVVM/Models/productModel.dart';
import '../../MVVM/View Model/productViewModel.dart';

class AddProductPage extends StatefulWidget {
  final String sellerId; // Seller ID passed to this page

  AddProductPage({required this.sellerId});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>(); // GlobalKey for form validation
  final ProductViewModel productViewModel = ProductViewModel();

  // Controllers for input fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();  // Controller for quantity

  // For Image
  File? _image;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false; // Loading indicator state

  /// Pick an image from the gallery.
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// Convert image to base64 string.
  Future<String> _getImageBase64() async {
    if (_image != null) {
      final bytes = await _image!.readAsBytes();
      return base64Encode(bytes);
    }
    return ''; // Return empty string if no image is selected
  }

  /// Handle form submission.
  Future<void> _submitProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select an image for the product")),
        );
        return;
      }

      if (quantityController.text.isEmpty || int.tryParse(quantityController.text) == null || int.parse(quantityController.text) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter a valid quantity")),
        );
        return;
      }

      setState(() {
        _isLoading = true; // Show loading indicator
      });

      String imageBase64 = await _getImageBase64();

      try {
        // Generate a new product ID
        final productId = FirebaseFirestore.instance.collection('products').doc().id;

        // Create the product model
        ProductModel newProduct = ProductModel(
          id: productId, // Assign the generated ID
          name: nameController.text,
          description: descriptionController.text,
          price: double.parse(priceController.text),
          reviews: [], // Empty list for reviews
          imageBase64: imageBase64,
          sellerId: widget.sellerId,
          quantity: int.parse(quantityController.text),  // Add quantity to the product model
        );

        await productViewModel.addProduct(newProduct); // Add the product via the view model

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              contentPadding: EdgeInsets.all(20),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 40), // Icon
                  SizedBox(width: 10), // Space between icon and text
                  Expanded(
                    child: Text(
                      "Product added successfully",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            );
          },
        );

        // Clear the input fields and image
        nameController.clear();
        descriptionController.clear();
        priceController.clear();
        quantityController.clear();  // Clear the quantity input
        setState(() {
          _image = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add New Product")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Product Name Text Field
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Product Name"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product name';
                      }
                      return null;
                    },
                  ),

                  // Description Text Field
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: "Product Description"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product description';
                      }
                      return null;
                    },
                  ),

                  // Price Text Field
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Product Price"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),

                  // Quantity Text Field
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Product Quantity"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product quantity';
                      }
                      if (int.tryParse(value) == null || int.parse(value) <= 0) {
                        return 'Please enter a valid quantity';
                      }
                      return null;
                    },
                  ),

                  // Image Picker
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _image == null
                            ? Center(child: Text("Tap to pick an image"))
                            : Image.file(_image!, fit: BoxFit.cover),
                      ),
                    ),
                  ),

                  // Submit Button
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _submitProduct,
                    child: Text("Add Product"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
