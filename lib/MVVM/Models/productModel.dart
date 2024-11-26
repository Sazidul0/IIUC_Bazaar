class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> reviews; // Assuming reviews are stored as a list of strings
  final String imageBase64; // Base64 string of the image
  final String sellerId;
  int quantity; // Changed from late final to mutable int

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.reviews,
    required this.imageBase64,
    required this.sellerId,
    required this.quantity, // Add quantity to constructor
  });

  /// Converts ProductModel to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'reviews': reviews,
      'imageBase64': imageBase64,
      'sellerId': sellerId,
      'quantity': quantity, // Add quantity to the JSON
    };
  }

  /// Creates a ProductModel from JSON format
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      reviews: List<String>.from(json['reviews'] ?? []),
      imageBase64: json['imageBase64'] ?? '',
      sellerId: json['sellerId'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0, // Safely parse quantity as an integer
    );
  }
}
