import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an expense within a group
class ExpenseModel {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String paidBy;
  final List<String> participants;
  final String splitType; // 'equal' or 'custom'
  final Map<String, double> splits; // user -> amount owed
  final String category;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.participants,
    this.splitType = 'equal',
    required this.splits,
    this.category = 'Other',
    required this.createdAt,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paidBy: data['paidBy'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      splitType: data['splitType'] ?? 'equal',
      splits: Map<String, double>.from(
        (data['splits'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ) ??
            {},
      ),
      category: data['category'] ?? 'Other',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'participants': participants,
      'splitType': splitType,
      'splits': splits,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
