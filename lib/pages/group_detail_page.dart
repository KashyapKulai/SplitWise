import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/group_model.dart';
import '../models/expense_model.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/animated_counter.dart';
import '../widgets/empty_state.dart';
import '../widgets/category_chip.dart';

/// Group detail page showing expenses, balances, and settle actions — all real-time
class GroupDetailPage extends StatelessWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return WillPopScope(
      onWillPop: () async {
        provider.setActiveGroupId(null);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<List<GroupModel>>(
          stream: provider.firestoreService.getGroupsStream(),
          builder: (context, groupSnapshot) {
            final groups = groupSnapshot.data ?? [];
            final group = groups.where((g) => g.id == groupId).firstOrNull;

            if (group == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<List<ExpenseModel>>(
              stream: provider.firestoreService.getExpensesStream(groupId),
              builder: (context, expenseSnapshot) {
                final expenses = expenseSnapshot.data ?? [];

                // Calculate balances from real-time expense data
                final balances = provider.firestoreService.computeNetBalances(
                  expenses,
                );
                final simplified = provider.firestoreService.simplifyDebts(
                  balances,
                );

                return CustomScrollView(
                  slivers: [
                    // ── Header ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 800;
                            return isWide
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      _buildBackButton(context, provider),
                                      const SizedBox(width: 16),
                                      _buildGroupInfo(context, group),
                                      const Spacer(),
                                      _buildActionButtons(
                                        context,
                                        provider,
                                        groupId,
                                        simplified,
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _buildBackButton(context, provider),
                                          const SizedBox(width: 12),
                                          _buildGroupInfo(context, group),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _buildActionButtons(
                                        context,
                                        provider,
                                        groupId,
                                        simplified,
                                      ),
                                    ],
                                  );
                          },
                        ),
                      ),
                    ),

                    // ── Members List (real-time from group stream) ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Members',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPurple.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${group.members.length} people',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.primaryPurple,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: group.members.map((member) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: member == 'You'
                                          ? AppTheme.primaryGradient
                                          : LinearGradient(
                                              colors: [
                                                AppTheme.primaryPurple
                                                    .withValues(alpha: 0.1),
                                                AppTheme.primaryBlue.withValues(
                                                  alpha: 0.05,
                                                ),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: member == 'You'
                                            ? AppTheme.primaryPurple
                                            : AppTheme.glassBorder,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AvatarWidget(name: member, size: 24),
                                        const SizedBox(width: 8),
                                        Text(
                                          member,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: member == 'You'
                                                    ? Colors.white
                                                    : null,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Balance Summary (computed from real-time expenses) ──
                    if (balances.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Member Balances',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                ...group.members.map((member) {
                                  final balance = balances[member] ?? 0;
                                  final isPositive = balance >= 0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        AvatarWidget(name: member, size: 32),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            member,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                        ),
                                        AnimatedCounter(
                                          value: balance.abs(),
                                          prefix: isPositive ? '+₹' : '-₹',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: isPositive
                                                    ? AppTheme.success
                                                    : AppTheme.error,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ── Simplified Debts (computed from real-time expenses) ──
                    if (simplified.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                          child: GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_fix_high_rounded,
                                      color: AppTheme.accentCyan,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Simplified Debts',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...simplified.map((txn) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        AvatarWidget(
                                          name: txn['from'],
                                          size: 30,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          txn['from'],
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  height: 2,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        AppTheme.error
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                        AppTheme.success
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(
                                                      context,
                                                    ).scaffoldBackgroundColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          AppTheme.glassBorder,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '₹${txn['amount']}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelLarge
                                                        ?.copyWith(
                                                          color:
                                                              AppTheme.warning,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          txn['to'],
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                        const SizedBox(width: 8),
                                        AvatarWidget(name: txn['to'], size: 30),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ── Expenses List ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
                        child: Text(
                          'Expenses',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),

                    if (expenses.isEmpty)
                      const SliverFillRemaining(
                        child: EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'No expenses yet',
                          subtitle: 'Add an expense to get started',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return _ExpenseTile(expense: expenses[index]);
                          }, childCount: expenses.length),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        floatingActionButton: _AddExpenseFAB(
          groupId: groupId,
          provider: provider,
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => provider.setActiveGroupId(null),
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Go back',
      ),
    );
  }

  Widget _buildGroupInfo(BuildContext context, GroupModel group) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(group.icon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  group.name,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AvatarStack(names: group.members, size: 26),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AppProvider provider,
    String groupId,
    List<Map<String, dynamic>> simplified,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showInviteDialog(context, provider, groupId),
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('Invite'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: AppTheme.primaryPurple.withValues(alpha: 0.5),
            ),
          ),
        ),
        if (simplified.isNotEmpty)
          FilledButton.icon(
            onPressed: () => _confirmSettle(context, provider),
            icon: const Icon(Icons.handshake_rounded, size: 18),
            label: const Text('Settle Up'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.success),
          ),
      ],
    );
  }

  void _confirmSettle(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle All Debts'),
        content: const Text(
          'This will record settlements and clear all expenses. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.firestoreService.settleDebts(groupId);
              Navigator.pop(ctx);
            },
            child: const Text('Settle'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(
    BuildContext context,
    AppProvider provider,
    String groupId,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Invite Member',
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim, secondAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (context, anim, secondAnim) {
        return _InviteMemberDialog(groupId: groupId, provider: provider);
      },
    );
  }
}

// ─────────────────────────────────────────────
// Invite Member Dialog
// ─────────────────────────────────────────────
class _InviteMemberDialog extends StatefulWidget {
  final String groupId;
  final AppProvider provider;
  const _InviteMemberDialog({required this.groupId, required this.provider});

  @override
  State<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<_InviteMemberDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isInviting = false;
  String? _successMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _inviteMember() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isInviting = true);

    if (email.isNotEmpty) {
      await widget.provider.firestoreService.inviteMemberByEmail(
        widget.groupId,
        name,
        email,
      );
    } else {
      await widget.provider.firestoreService.addMemberToGroup(
        widget.groupId,
        name,
      );
    }

    if (mounted) {
      setState(() {
        _isInviting = false;
        _successMessage = '$name has been added!';
        _nameController.clear();
        _emailController.clear();
      });

      // Auto-clear success message after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _successMessage = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 440,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).dialogTheme.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.glowShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Invite Member',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'e.g. John Doe',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  hintText: 'e.g. john@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'The member will be added to this group immediately.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              if (_successMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _successMessage!,
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isInviting ? null : _inviteMember,
                    icon: _isInviting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Add Member'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Expense Tile
// ─────────────────────────────────────────────
class _ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final info = AppConstants.getCategoryInfo(expense.category);
    final color = Color(info['color'] as int);
    final icon = info['icon'] as IconData;
    final dateStr = DateFormat('MMM d, h:mm a').format(expense.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paid by ${expense.paidBy} · $dateStr',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${expense.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                CategoryChip(category: expense.category),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add Expense FAB + Dialog
// ─────────────────────────────────────────────
class _AddExpenseFAB extends StatelessWidget {
  final String groupId;
  final AppProvider provider;
  const _AddExpenseFAB({required this.groupId, required this.provider});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddExpenseDialog(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Expense'),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Expense',
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim, secondAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (context, anim, secondAnim) {
        return _AddExpenseDialog(groupId: groupId, provider: provider);
      },
    );
  }
}

class _AddExpenseDialog extends StatefulWidget {
  final String groupId;
  final AppProvider provider;
  const _AddExpenseDialog({required this.groupId, required this.provider});

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Other';
  String _splitType = 'equal';
  String? _paidBy;
  List<String> _participants = [];
  List<String> _groupMembers = [];
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    // Use real-time stream to get the latest members
    widget.provider.firestoreService.getGroupsStream().first.then((groups) {
      final group = groups.where((g) => g.id == widget.groupId).firstOrNull;
      if (group != null && mounted) {
        setState(() {
          _groupMembers = group.members;
          _participants = List.from(group.members);
          _paidBy = widget.provider.currentUser;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    final title = _titleController.text.trim();
    final amountStr = _amountController.text.trim();
    if (title.isEmpty ||
        amountStr.isEmpty ||
        _paidBy == null ||
        _participants.isEmpty)
      return;

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _isAdding = true);
    await widget.provider.firestoreService.addExpense(
      groupId: widget.groupId,
      title: title,
      amount: amount,
      paidBy: _paidBy!,
      participants: _participants,
      splitType: _splitType,
      category: _selectedCategory,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 480,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).dialogTheme.backgroundColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.glowShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Expense',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Dinner at restaurant',
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 16),

                Text('Category', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.categories.map((cat) {
                    return CategoryChip(
                      category: cat['name'],
                      selected: _selectedCategory == cat['name'],
                      onTap: () =>
                          setState(() => _selectedCategory = cat['name']),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                if (_groupMembers.isNotEmpty) ...[
                  Text(
                    'Paid by',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _paidBy,
                    items: _groupMembers
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Row(
                              children: [
                                AvatarWidget(name: m, size: 22),
                                const SizedBox(width: 8),
                                Text(m),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _paidBy = v),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  'Split Type',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SplitTypeChip(
                      label: 'Equal',
                      selected: _splitType == 'equal',
                      onTap: () => setState(() => _splitType = 'equal'),
                    ),
                    const SizedBox(width: 8),
                    _SplitTypeChip(
                      label: 'Custom',
                      selected: _splitType == 'custom',
                      onTap: () => setState(() => _splitType = 'custom'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'Participants',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _groupMembers.map((member) {
                    final selected = _participants.contains(member);
                    return FilterChip(
                      avatar: AvatarWidget(name: member, size: 22),
                      label: Text(member),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _participants.add(member);
                          } else {
                            _participants.remove(member);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isAdding ? null : _addExpense,
                      icon: _isAdding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SplitTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryPurple.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primaryPurple : AppTheme.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primaryPurple : null,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
