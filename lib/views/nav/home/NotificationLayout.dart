import 'package:agritechv2/repository/auth_repository.dart';
import 'package:agritechv2/views/nav/home/NotificationTile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/transaction/TransactionDetails.dart';
import '../../../repository/transaction_repository.dart';
import '../../../styles/text_styles.dart';

class NotificationLayout extends StatefulWidget {
  const NotificationLayout({super.key});

  @override
  State<NotificationLayout> createState() => _NotificationLayoutState();
}

class _NotificationLayoutState extends State<NotificationLayout> {
  // This variable will hold the list of notification details
  List<Details> _recentDetails = [];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Notifications",
                style: MyTextStyles.header,
              ),
              TextButton(
                onPressed: () async {
                  // Clear all notifications and save messages to SharedPreferences
                  await clearNotifications(_recentDetails);
                  // Optionally, you can force a rebuild to refresh the notification list
                  setState(() {
                    _recentDetails.clear(); // Clear the local list
                  });
                },
                child: const Text("Clear all"),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Details>>(
              stream: context.read<TransactionRepostory>().getRecentDetails(
                  context.read<AuthRepository>().currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text("Error loading notifications"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No recent notifications"));
                } else {
                  // Store the recent details to the local variable
                  _recentDetails = snapshot.data!;
                  return ListView.builder(
                    itemCount: _recentDetails.length,
                    itemBuilder: (context, index) {
                      final detail = _recentDetails[index];
                      return NotificationTile(details: detail);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> clearNotifications(List<Details> list) async {
    await context.read<TransactionRepostory>().clearNotification(list);
  }
}
