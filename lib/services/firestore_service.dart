import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import '../models/expense_model.dart';
import '../models/settlement_model.dart';
import '../models/user_model.dart';

/// Central Firestore service handling all database operations
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  // ══════════════════════════════════════════════
  // USER OPERATIONS
  // ══════════════════════════════════════════════

  /// Search for a registered user by email (exact match)
  Future<UserModel?> searchUserByEmail(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase().trim())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  /// Get multiple users by their UIDs
  Future<Map<String, UserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return {};

    final result = <String, UserModel>{};

    // Firestore whereIn supports max 30 items at a time
    for (var i = 0; i < uids.length; i += 30) {
      final batch = uids.sublist(
        i,
        i + 30 > uids.length ? uids.length : i + 30,
      );
      final query = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in query.docs) {
        result[doc.id] = UserModel.fromFirestore(doc);
      }
    }

    return result;
  }

  /// Get a single user by UID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ══════════════════════════════════════════════
  // GROUP OPERATIONS
  // ══════════════════════════════════════════════

  /// Create a new expense-sharing group (members are UIDs)
  Future<String> createGroup({
    required String name,
    required List<String> memberUids,
    String icon = '👥',
  }) async {
    final docRef = _db.collection('groups').doc();
    final group = GroupModel(
      id: docRef.id,
      name: name,
      members: memberUids,
      createdAt: DateTime.now(),
      icon: icon,
    );
    await docRef.set(group.toMap());
    return docRef.id;
  }

  /// Real-time stream of all groups, ordered by creation date
  Stream<List<GroupModel>> getGroupsStream() {
    return _db
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList());
  }

  /// Real-time stream of groups the user belongs to
  /// NOTE: No orderBy here — arrayContains + orderBy requires a composite index.
  /// We sort client-side instead.
  Stream<List<GroupModel>> getMyGroupsStream(String uid) {
    return _db
        .collection('groups')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final groups =
          snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
      groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return groups;
    });
  }

  /// Real-time stream of a single group by ID
  Stream<GroupModel?> getGroupStream(String groupId) {
    return _db.collection('groups').doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GroupModel.fromFirestore(doc);
    });
  }

  /// Delete a group and all its associated expenses and settlements
  Future<void> deleteGroup(String groupId) async {
    final batch = _db.batch();
    // Delete expenses
    final expenses = await _db
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();
    for (final doc in expenses.docs) {
      batch.delete(doc.reference);
    }
    // Delete settlements
    final settlements = await _db
        .collection('settlements')
        .where('groupId', isEqualTo: groupId)
        .get();
    for (final doc in settlements.docs) {
      batch.delete(doc.reference);
    }
    // Delete the group itself
    batch.delete(_db.collection('groups').doc(groupId));
    await batch.commit();
  }

  // ══════════════════════════════════════════════
  // EXPENSE OPERATIONS
  // ══════════════════════════════════════════════

  /// Add a new expense to a group (paidBy and participants are UIDs)
  Future<void> addExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidByUid,
    required List<String> participantUids,
    String splitType = 'equal',
    Map<String, double>? customSplits,
    String category = 'Other',
  }) async {
    // Calculate splits based on split type
    Map<String, double> splits;
    if (splitType == 'custom' && customSplits != null) {
      splits = customSplits;
    } else {
      // Equal split among all participants
      final perPerson = amount / participantUids.length;
      splits = {for (var uid in participantUids) uid: perPerson};
    }

    final expense = ExpenseModel(
      id: _uuid.v4(),
      groupId: groupId,
      title: title,
      amount: amount,
      paidBy: paidByUid,
      participants: participantUids,
      splitType: splitType,
      splits: splits,
      category: category,
      createdAt: DateTime.now(),
    );

    await _db.collection('expenses').add(expense.toMap());
  }

  /// Real-time stream of expenses for a specific group
  Stream<List<ExpenseModel>> getExpensesStream(String groupId) {
    return _db
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      final expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
      expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return expenses;
    });
  }

  /// Real-time stream of ALL expenses (for dashboard)
  Stream<List<ExpenseModel>> getAllExpensesStream() {
    return _db
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList());
  }

  /// Delete a single expense
  Future<void> deleteExpense(String expenseId) async {
    final query = await _db
        .collection('expenses')
        .where(FieldPath.documentId, isEqualTo: expenseId)
        .get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }
  }

  // ══════════════════════════════════════════════
  // BALANCE & DEBT CALCULATIONS
  // ══════════════════════════════════════════════

  /// Calculate net balances for all members in a group (one-shot).
  Future<Map<String, double>> calculateBalances(String groupId) async {
    final snapshot = await _db
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();

    final expenses =
        snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();

    return _computeNetBalances(expenses);
  }

  /// Real-time stream of net balances for a group.
  Stream<Map<String, double>> calculateBalancesStream(String groupId) {
    return _db
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      final expenses =
          snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
      return _computeNetBalances(expenses);
    });
  }

  /// Core balance computation (pure function, no Firestore dependency)
  Map<String, double> computeNetBalances(List<ExpenseModel> expenses) {
    return _computeNetBalances(expenses);
  }

  Map<String, double> _computeNetBalances(List<ExpenseModel> expenses) {
    final balances = <String, double>{};

    for (final expense in expenses) {
      // The payer paid the full amount, so they are owed that much
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amount;

      // Each participant owes their split
      expense.splits.forEach((person, share) {
        balances[person] = (balances[person] ?? 0) - share;
      });
    }

    return balances;
  }

  // ══════════════════════════════════════════════
  // MEMBER OPERATIONS
  // ══════════════════════════════════════════════

  /// Add a member (by UID) to an existing group
  Future<void> addMemberToGroup(String groupId, String memberUid) async {
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([memberUid]),
    });
  }

  /// Debt Simplification Algorithm (Greedy approach)
  List<Map<String, dynamic>> simplifyDebts(Map<String, double> balances) {
    // Filter out zero balances (tolerance for floating-point)
    final creditors = <MapEntry<String, double>>[]; // positive balance
    final debtors = <MapEntry<String, double>>[]; // negative balance

    balances.forEach((person, balance) {
      if (balance > 0.01) {
        creditors.add(MapEntry(person, balance));
      } else if (balance < -0.01) {
        debtors.add(MapEntry(person, -balance)); // store as positive
      }
    });

    // Sort descending by amount
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final transactions = <Map<String, dynamic>>[];
    int ci = 0, di = 0;
    final cAmounts = creditors.map((e) => e.value).toList();
    final dAmounts = debtors.map((e) => e.value).toList();

    while (ci < creditors.length && di < debtors.length) {
      final settleAmount =
          cAmounts[ci] < dAmounts[di] ? cAmounts[ci] : dAmounts[di];

      transactions.add({
        'from': debtors[di].key,
        'to': creditors[ci].key,
        'amount': double.parse(settleAmount.toStringAsFixed(2)),
      });

      cAmounts[ci] -= settleAmount;
      dAmounts[di] -= settleAmount;

      if (cAmounts[ci] < 0.01) ci++;
      if (dAmounts[di] < 0.01) di++;
    }

    return transactions;
  }

  // ══════════════════════════════════════════════
  // SETTLEMENT OPERATIONS
  // ══════════════════════════════════════════════

  /// Settle all debts in a group
  Future<void> settleDebts(String groupId) async {
    final balances = await calculateBalances(groupId);
    final transactions = simplifyDebts(balances);

    final batch = _db.batch();
    for (final txn in transactions) {
      final docRef = _db.collection('settlements').doc();
      final settlement = SettlementModel(
        id: docRef.id,
        groupId: groupId,
        from: txn['from'],
        to: txn['to'],
        amount: txn['amount'],
        settledAt: DateTime.now(),
      );
      batch.set(docRef, settlement.toMap());
    }

    // Delete all expenses in this group (they've been settled)
    final expenses = await _db
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();
    for (final doc in expenses.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Real-time stream of settlements for a group
  Stream<List<SettlementModel>> getSettlementsStream(String groupId) {
    return _db
        .collection('settlements')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      final settlements = snapshot.docs
          .map((doc) => SettlementModel.fromFirestore(doc))
          .toList();
      settlements.sort((a, b) => b.settledAt.compareTo(a.settledAt));
      return settlements;
    });
  }

  /// Real-time stream of ALL settlements (for activity feed)
  Stream<List<SettlementModel>> getAllSettlementsStream() {
    return _db
        .collection('settlements')
        .orderBy('settledAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SettlementModel.fromFirestore(doc))
            .toList());
  }
}
