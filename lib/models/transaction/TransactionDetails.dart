import 'package:agritechv2/models/transaction/TransactionStatus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Details {
  String id;
  String transactionID;
  String updatedBy;
  String message;
  TransactionStatus status;
  DateTime updatedAt;
  bool seen; // Add seen property

  Details({
    required this.id,
    required this.transactionID,
    required this.updatedBy,
    required this.message,
    required this.status,
    required this.updatedAt,
    this.seen = false, // Default value for seen
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionID': transactionID,
      'updatedBy': updatedBy,
      'message': message,
      'status': status.toString().split('.').last, // Convert enum to string
      'updatedAt': Timestamp.fromDate(updatedAt),
      'seen': seen, // Include seen in JSON
    };
  }

  factory Details.fromJson(Map<String, dynamic> json) {
    return Details(
      id: json['id'],
      transactionID: json['transactionID'],
      updatedBy: json['updatedBy'],
      message: json['message'],
      status: TransactionStatus.values.firstWhere((e) =>
          e.toString().split('.').last ==
          json['status']), // Convert string to enum
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      seen: json['seen'] ??
          false, // Read seen property, default to false if not present
    );
  }
}
