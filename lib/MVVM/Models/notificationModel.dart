// In your notificationModel.dart file

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead; // <-- 1. ADD THIS FIELD

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false, // <-- 2. ADD THIS (default to false)
  });

  // Factory constructor to create a NotificationModel from Firestore
  factory NotificationModel.fromFirestore(Map<String, dynamic> data, String id) {
    // --- This function is now safer and handles the new 'isRead' field ---
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'No Title',
      message: data['message'] ?? 'No Message',
      // Safely handle both Timestamp and String from Firestore
      timestamp: _parseTimestamp(data['timestamp']),
      isRead: data['isRead'] ?? false, // <-- 3. READ THE isRead FIELD
    );
  }

  // Convert NotificationModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead, // <-- 4. ADD THIS FIELD FOR SAVING
    };
  }
}

// Helper function to safely parse different timestamp formats from Firestore
DateTime _parseTimestamp(dynamic timestampData) {
  if (timestampData is Timestamp) {
    return timestampData.toDate(); // Handle Firestore's native Timestamp object
  }
  if (timestampData is String) {
    return DateTime.tryParse(timestampData) ?? DateTime.now(); // Handle ISO8601 String
  }
  return DateTime.now(); // Fallback for null or invalid data
}