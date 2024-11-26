class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
  });

  // Factory constructor to create a NotificationModel from Firestore
  factory NotificationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: DateTime.parse(data['timestamp']),
    );
  }

  // Convert NotificationModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
