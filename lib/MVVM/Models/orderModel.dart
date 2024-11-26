class OrderModel {
  String id;
  String userId;
  String productId;
  int quantity;
  double totalPrice;
  String status; // "Pending", "Completed"
  DateTime orderDate;
  String sellerId; // Added Seller ID

  OrderModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.orderDate,
    required this.sellerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'status': status,
      'orderDate': orderDate.toIso8601String(),
      'sellerId': sellerId,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'],
      userId: map['userId'],
      productId: map['productId'],
      quantity: map['quantity'],
      totalPrice: map['totalPrice'],
      status: map['status'],
      orderDate: DateTime.parse(map['orderDate']),
      sellerId: map['sellerId'],
    );
  }
}
