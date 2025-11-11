import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../MVVM/Models/productModel.dart';
import '../../MVVM/View Model/productViewModel.dart';

class AddProductPage extends StatefulWidget {
  final String sellerId;

  const AddProductPage({Key? key, required this.sellerId}) : super(key: key);

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductViewModel productViewModel = ProductViewModel();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<String> _getImageBase64() async {
    if (_image != null) {
      final bytes = await _image!.readAsBytes();
      return base64Encode(bytes);
    }
    return '';
  }

  // --- CORRECTED SUBMIT LOGIC ---
  Future<void> _submitProduct() async {
    // 1. Validate the form and check for an image
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image for the product")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Prepare all the data
      String imageBase64 = await _getImageBase64();
      final productId = FirebaseFirestore.instance.collection('products').doc().id;

      ProductModel newProduct = ProductModel(
        id: productId,
        name: nameController.text,
        description: descriptionController.text,
        price: double.parse(priceController.text),
        reviews: [],
        imageBase64: imageBase64,
        sellerId: widget.sellerId,
        quantity: int.parse(quantityController.text),
      );

      // 3. Attempt to add the product to the database
      await productViewModel.addProduct(newProduct);

      // 4. --- THIS IS THE CRITICAL FIX ---
      // This success logic ONLY runs if the 'await' above completes without an error.
      if (mounted) {
        _showSuccessDialog();
        // Clear fields only on success
        nameController.clear();
        descriptionController.clear();
        priceController.clear();
        quantityController.clear();
        setState(() => _image = null);
      }

    } catch (e) {
      // 5. If any error happens in the 'try' block, this will be executed instead.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to add product: $e"))
        );
      }
    } finally {
      // 6. This will always run, whether it succeeded or failed.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
          content: Text(
            "Product Added Successfully",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 18),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = HexColor("#44564a");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Add New Product", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: primaryColor, // Using your requested color
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              Text("Product Details", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: nameController,
                label: "Product Name",
                hint: "e.g., Classic Leather Wallet",
                icon: Icons.title,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: descriptionController,
                label: "Description",
                hint: "Describe the product's features...",
                icon: Icons.description,
                maxLines: 3,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: priceController,
                      label: "Price (\৳)",
                      hint: "e.g., 1200",
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter a price';
                        if (double.tryParse(value) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextFormField(
                      controller: quantityController,
                      label: "Quantity",
                      hint: "e.g., 10",
                      icon: Icons.inventory_2,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter a quantity';
                        if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Enter a valid quantity';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSubmitButton(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade400, width: 1.5),
        ),
        child: _image == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.grey[600], size: 50),
            const SizedBox(height: 8),
            Text("Upload Product Image", style: GoogleFonts.poppins(color: Colors.grey[700])),
          ],
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(_image!, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(Color color) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _isLoading ? null : _submitProduct,
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        )
            : Text(
          "Add Product",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType keyboardType;
  final int maxLines;

  const CustomTextFormField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      ),
    );
  }
}