class CartModel {
  final String userId;
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String imageBase64;

  CartModel({
    required this.userId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageBase64': imageBase64,
    };
  }

  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      userId: map['userId'],
      productId: map['productId'],
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'],
      imageBase64: map['imageBase64'],
    );
  }

  CartModel copyWith({
    String? userId,
    String? productId,
    String? name,
    int? quantity,
    double? price,
    String? imageBase64,
  }) {
    return CartModel(
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}
