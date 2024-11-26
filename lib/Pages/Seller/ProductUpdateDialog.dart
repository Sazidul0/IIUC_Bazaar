import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../MVVM/Models/productModel.dart';
import '../../MVVM/View Model/productViewModel.dart';

class ProductUpdateDialog extends StatefulWidget {
  final ProductModel product;

  const ProductUpdateDialog({required this.product, Key? key}) : super(key: key);

  @override
  _ProductUpdateDialogState createState() => _ProductUpdateDialogState();
}

class _ProductUpdateDialogState extends State<ProductUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  final ProductViewModel productViewModel = ProductViewModel();

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController quantityController;  // New controller for quantity

  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;  // To handle the loading state

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    descriptionController = TextEditingController(text: widget.product.description);
    priceController = TextEditingController(text: widget.product.price.toString());
    quantityController = TextEditingController(text: widget.product.quantity.toString());  // Initialize quantity controller
  }

  /// Pick an image from the gallery.
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  /// Update the product in Firestore.
  Future<void> _updateProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;  // Show loading indicator
      });

      if (widget.product.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Product ID is missing!")),
        );
        return;
      }

      try {
        String imageBase64 = _image != null
            ? base64Encode(await _image!.readAsBytes())
            : widget.product.imageBase64;

        // Create updated product with quantity
        ProductModel updatedProduct = ProductModel(
          id: widget.product.id,
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          price: double.parse(priceController.text.trim()),
          reviews: widget.product.reviews,
          imageBase64: imageBase64,
          sellerId: widget.product.sellerId,
          quantity: int.parse(quantityController.text.trim()),  // Added quantity to update
        );

        await productViewModel.updateProduct(updatedProduct);

        // Show success message after update
        Navigator.pop(context, true); // Return true to signal success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        setState(() {
          isLoading = false;  // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Update Product"),
      content: isLoading
          ? const Center(child: CircularProgressIndicator())  // Show loading spinner while updating
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Product Name"),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter the product name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter the description'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the price';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the quantity';
                  }
                  if (int.tryParse(value.trim()) == null || int.parse(value.trim()) <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _image == null
                      ? widget.product.imageBase64.isEmpty
                      ? const Center(child: Text("Tap to pick an image"))
                      : Image.memory(
                    base64Decode(widget.product.imageBase64),
                    fit: BoxFit.cover,
                  )
                      : Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _updateProduct, // Disable the button while updating
          child: const Text("Update"),
        ),
      ],
    );
  }
}
