import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a debt settlement between two users
class SettlementModel {
  final String id;
  final String groupId;
  final String from;
  final String to;
  final double amount;
  final DateTime settledAt;

  SettlementModel({
    required this.id,
    required this.groupId,
    required this.from,
    required this.to,
    required this.amount,
    required this.settledAt,
  });

  factory SettlementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SettlementModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      settledAt:
          (data['settledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'from': from,
      'to': to,
      'amount': amount,
      'settledAt': Timestamp.fromDate(settledAt),
    };
  }
}
