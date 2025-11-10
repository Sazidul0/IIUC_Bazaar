import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/notificationViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/notificationModel.dart';
// FIX: ADD THE MISSING IMPORT STATEMENT FOR THE TIMEAGO PACKAGE
import 'package:timeago/timeago.dart' as timeago;

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationViewModel _notificationViewModel = NotificationViewModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // A helper function to choose an icon based on the notification title
  IconData _getIconForNotification(String title) {
    title = title.toLowerCase();
    if (title.contains('order')) {
      return Icons.shopping_cart_checkout_rounded;
    } else if (title.contains('message')) {
      return Icons.message_rounded;
    } else if (title.contains('offer') || title.contains('sale')) {
      return Icons.campaign_rounded;
    } else if (title.contains('welcome')) {
      return Icons.waving_hand_rounded;
    } else {
      return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black26,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Notifications",
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.done_all_rounded, color: Colors.black54),
            tooltip: "Mark all as read",
          ),
        ],
      ),
      body: currentUser == null
          ? _buildLoggedOutView()
          : FutureBuilder<List<NotificationModel>>(
        future: _notificationViewModel.getNotifications(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
          } else if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyView();
          } else {
            final notifications = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationTile(
                  icon: _getIconForNotification(notification.title),
                  title: notification.title,
                  message: notification.message,
                  timestamp: notification.timestamp,
                  // This will now work perfectly because 'isRead' is in your model
                  isRead: notification.isRead,
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyView() { /* ... (no changes here) ... */
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No Notifications Yet",
            style: GoogleFonts.nunitoSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            "When something important happens,\nwe'll let you know right here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) { /* ... (no changes here) ... */
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Something went wrong:\n$error",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunitoSans(color: Colors.red[700]),
        ),
      ),
    );
  }

  Widget _buildLoggedOutView() { /* ... (no changes here) ... */
    return Center(
      child: Text(
        "You must be logged in to view notifications.",
        style: GoogleFonts.nunitoSans(fontSize: 16, color: Colors.grey[600]),
      ),
    );
  }
}

// --- CUSTOM NOTIFICATION TILE WIDGET ---
class NotificationTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const NotificationTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  }) : super(key: key);

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> with SingleTickerProviderStateMixin {
  // ... (All the animation and build logic from the previous beautiful UI remains exactly the same) ...
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.isRead ? Colors.grey : Colors.white;
    final Color iconBgColor = widget.isRead ? Colors.grey.shade300 : Colors.redAccent;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isRead ? Colors.white : const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: iconBgColor,
              child: Icon(widget.icon, color: iconColor, size: 24),
            ),
            title: Text(
              widget.title,
              style: GoogleFonts.nunitoSans(
                fontWeight: widget.isRead ? FontWeight.w600 : FontWeight.w800,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  widget.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunitoSans(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  // This will now work because the import was added
                  timeago.format(widget.timestamp),
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            trailing: !widget.isRead
                ? const CircleAvatar(radius: 5, backgroundColor: Colors.redAccent)
                : null,
            onTap: () {},
          ),
        ),
      ),
    );
  }
}