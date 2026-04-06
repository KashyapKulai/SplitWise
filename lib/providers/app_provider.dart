import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// App-level state: auth, theme toggle, navigation, user cache, search
class AppProvider extends ChangeNotifier {
  final FirestoreService firestoreService = FirestoreService();
  final AuthService authService = AuthService();

  // ── User Cache (UID → UserModel) ──
  final Map<String, UserModel> _userCache = {};

  /// Resolve a UID to a display name (returns UID if not cached)
  String resolveUserName(String uid) {
    if (uid == authService.uid) return authService.displayName;
    return _userCache[uid]?.displayName ?? uid;
  }

  /// Resolve a UID to a UserModel
  UserModel? resolveUser(String uid) => _userCache[uid];

  /// Load users into cache by their UIDs
  Future<void> cacheUsers(List<String> uids) async {
    final uncached = uids.where((uid) => !_userCache.containsKey(uid) && uid != authService.uid).toList();
    if (uncached.isEmpty) return;
    final users = await firestoreService.getUsersByIds(uncached);
    _userCache.addAll(users);
    notifyListeners();
  }

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

  // ── Current User (from Firebase Auth) ──
  String get currentUser => authService.displayName;
  String get currentUid => authService.uid;

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

  // ── Auth Operations ──
  Future<void> signOut() async {
    await authService.signOut();
    _selectedIndex = 0;
    _activeGroupId = null;
    _searchQuery = '';
    _userCache.clear();
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    await authService.updateDisplayName(name);
    notifyListeners();
  }
}
