import 'package:flutter/material.dart';

/// App-wide constant values
class AppConstants {
  AppConstants._();

  static const String appName = 'ClearLedger';
  static const String defaultUser = 'You';

  /// Expense categories with icons and colors
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': 0xFFFF6B6B},
    {'name': 'Travel', 'icon': Icons.flight, 'color': 0xFF4ECDC4},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': 0xFFFFE66D},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': 0xFFA855F7},
    {'name': 'Utilities', 'icon': Icons.bolt, 'color': 0xFF3B82F6},
    {'name': 'Rent', 'icon': Icons.home, 'color': 0xFFF97316},
    {'name': 'Health', 'icon': Icons.favorite, 'color': 0xFFEF4444},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': 0xFF6B7280},
  ];

  /// Avatar gradient colors for members
  static const List<List<Color>> avatarGradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)],
    [Color(0xFFf093fb), Color(0xFFf5576c)],
    [Color(0xFF4facfe), Color(0xFF00f2fe)],
    [Color(0xFF43e97b), Color(0xFF38f9d7)],
    [Color(0xFFfa709a), Color(0xFFfee140)],
    [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
    [Color(0xFFfad0c4), Color(0xFFffd1ff)],
    [Color(0xFF89f7fe), Color(0xFF66a6ff)],
  ];

  /// Get avatar gradient by index (wraps around)
  static List<Color> getAvatarGradient(int index) {
    return avatarGradients[index % avatarGradients.length];
  }

  /// Get category info by name
  static Map<String, dynamic> getCategoryInfo(String name) {
    return categories.firstWhere(
      (c) => c['name'] == name,
      orElse: () => categories.last,
    );
  }
}
