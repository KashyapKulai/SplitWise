import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a group of people sharing expenses
class GroupModel {
  final String id;
  final String name;
  final List<String> members;
  final DateTime createdAt;
  final String icon;

  GroupModel({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
    this.icon = '👥',
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      icon: data['icon'] ?? '👥',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'icon': icon,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    List<String>? members,
    DateTime? createdAt,
    String? icon,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
    );
  }
}
