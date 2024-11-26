import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/notificationViewModel.dart';
import 'package:iiuc_bazaar/MVVM/Models/notificationModel.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationViewModel _notificationViewModel = NotificationViewModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: const Center(
          child: Text("You must be logged in to view notifications."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationViewModel.getNotifications(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No notifications yet."),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final notification = snapshot.data![index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: ListTile(
                    title: Text(notification.title ?? "No Title"),
                    subtitle: Column(
                      children: [
                        Text(notification.message ?? "No Message"),
                        Text(
                          notification.timestamp?.toString() ?? "Unknown Time",
                          style: const TextStyle(fontSize: 10),
                        )
                      ],
                    ),
                    // trailing: Text(
                    //   notification.timestamp?.toString() ?? "Unknown Time",
                    //   style: const TextStyle(fontSize: 12),
                    // ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
