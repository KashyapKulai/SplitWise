import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

/// App-level state: theme toggle, navigation, current user, search
class AppProvider extends ChangeNotifier {
  final FirestoreService firestoreService = FirestoreService();

  // ── Theme ──
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // ── Navigation ──
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // ── Current User ──
  String _currentUser = 'You';
  String get currentUser => _currentUser;

  void setCurrentUser(String name) {
    _currentUser = name;
    notifyListeners();
  }

  // ── Search ──
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Active Group (for group detail page) ──
  String? _activeGroupId;
  String? get activeGroupId => _activeGroupId;

  void setActiveGroupId(String? id) {
    _activeGroupId = id;
    notifyListeners();
  }
}
