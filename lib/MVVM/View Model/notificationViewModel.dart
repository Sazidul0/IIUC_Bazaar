import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/notificationModel.dart';

class NotificationViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a notification
  Future<void> addNotification(
      {required String userId,
        required String title,
        required String message}) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        message: message,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toFirestore());
    } catch (e) {
      throw Exception("Error adding notification: $e");
    }
  }

  // Fetch notifications for a specific user
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return NotificationModel.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception("Error fetching notifications: $e");
    }
  }
}
