import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/group_model.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) provider.setActiveGroupId(null);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<GroupModel?>(
          stream: provider.firestoreService.getGroupStream(groupId),
          builder: (context, groupSnapshot) {
            final group = groupSnapshot.data;

            if (group == null) {
              if (groupSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return const Center(child: Text('Group not found'));
            }

            // Cache member user data
            provider.cacheUsers(group.members);

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
                                      _buildGroupInfo(context, group, provider),
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
                                          _buildGroupInfo(context, group, provider),
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

                    // ── Members List ──
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
                                children: group.members.map((uid) {
                                  final name = provider.resolveUserName(uid);
                                  final isMe = uid == provider.currentUid;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isMe
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
                                        color: isMe
                                            ? AppTheme.primaryPurple
                                            : AppTheme.glassBorder,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AvatarWidget(name: name, size: 24),
                                        const SizedBox(width: 8),
                                        Text(
                                          isMe ? '$name (You)' : name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: isMe
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

                    // ── Balance Summary ──
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
                                ...group.members.map((uid) {
                                  final name = provider.resolveUserName(uid);
                                  final balance = balances[uid] ?? 0;
                                  final isPositive = balance >= 0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        AvatarWidget(name: name, size: 32),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            uid == provider.currentUid
                                                ? '$name (You)'
                                                : name,
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

                    // ── Simplified Debts ──
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
                                  final fromName =
                                      provider.resolveUserName(txn['from']);
                                  final toName =
                                      provider.resolveUserName(txn['to']);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        AvatarWidget(
                                          name: fromName,
                                          size: 30,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          fromName,
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
                                          toName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                        const SizedBox(width: 8),
                                        AvatarWidget(name: toName, size: 30),
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
                            return _ExpenseTile(
                              expense: expenses[index],
                              provider: provider,
                            );
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

  Widget _buildGroupInfo(BuildContext context, GroupModel group, AppProvider provider) {
    final memberNames = group.members
        .map((uid) => provider.resolveUserName(uid))
        .toList();
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
          AvatarStack(names: memberNames, size: 26),
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
// Invite Member Dialog — email search only
// ─────────────────────────────────────────────
class _InviteMemberDialog extends StatefulWidget {
  final String groupId;
  final AppProvider provider;
  const _InviteMemberDialog({required this.groupId, required this.provider});

  @override
  State<_InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<_InviteMemberDialog> {
  final _emailController = TextEditingController();
  bool _isSearching = false;
  String? _error;
  UserModel? _searchResult;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _searchAndInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _searchResult = null;
      _successMessage = null;
    });

    final user =
        await widget.provider.firestoreService.searchUserByEmail(email);

    if (user == null) {
      setState(() {
        _isSearching = false;
        _error = 'No account found with this email';
      });
    } else {
      setState(() {
        _isSearching = false;
        _searchResult = user;
      });
    }
  }

  Future<void> _addMember(UserModel user) async {
    await widget.provider.firestoreService
        .addMemberToGroup(widget.groupId, user.uid);
    await widget.provider.cacheUsers([user.uid]);

    if (mounted) {
      setState(() {
        _successMessage = '${user.displayName} has been added!';
        _searchResult = null;
        _emailController.clear();
      });
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _searchAndInvite(),
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  hintText: 'friend@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Search for a registered user by email to add them.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Search result
              if (_searchResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      AvatarWidget(
                          name: _searchResult!.displayName, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_searchResult!.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(_searchResult!.email,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _addMember(_searchResult!),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Success message
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
                    onPressed: _isSearching ? null : _searchAndInvite,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Search'),
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
// Expense Tile (resolves UIDs to names)
// ─────────────────────────────────────────────
class _ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final AppProvider provider;
  const _ExpenseTile({required this.expense, required this.provider});

  @override
  Widget build(BuildContext context) {
    final info = AppConstants.getCategoryInfo(expense.category);
    final color = Color(info['color'] as int);
    final icon = info['icon'] as IconData;
    final dateStr = DateFormat('MMM d, h:mm a').format(expense.createdAt);
    final paidByName = provider.resolveUserName(expense.paidBy);

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
                    'Paid by $paidByName · $dateStr',
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
// Add Expense FAB + Dialog (UID-based)
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
  String? _paidByUid;
  List<String> _participantUids = [];
  List<String> _groupMemberUids = [];
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    widget.provider.firestoreService
        .getMyGroupsStream(widget.provider.currentUid)
        .first
        .then((groups) {
      final group = groups.where((g) => g.id == widget.groupId).firstOrNull;
      if (group != null && mounted) {
        setState(() {
          _groupMemberUids = group.members;
          _participantUids = List.from(group.members);
          _paidByUid = widget.provider.currentUid;
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
        _paidByUid == null ||
        _participantUids.isEmpty) return;

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _isAdding = true);
    await widget.provider.firestoreService.addExpense(
      groupId: widget.groupId,
      title: title,
      amount: amount,
      paidByUid: _paidByUid!,
      participantUids: _participantUids,
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

                Text('Category',
                    style: Theme.of(context).textTheme.labelLarge),
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

                if (_groupMemberUids.isNotEmpty) ...[
                  Text('Paid by',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _paidByUid,
                    items: _groupMemberUids
                        .map(
                          (uid) => DropdownMenuItem(
                            value: uid,
                            child: Row(
                              children: [
                                AvatarWidget(
                                    name: widget.provider
                                        .resolveUserName(uid),
                                    size: 22),
                                const SizedBox(width: 8),
                                Text(widget.provider.resolveUserName(uid)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _paidByUid = v),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text('Split Type',
                    style: Theme.of(context).textTheme.labelLarge),
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

                Text('Participants',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _groupMemberUids.map((uid) {
                    final name = widget.provider.resolveUserName(uid);
                    final selected = _participantUids.contains(uid);
                    return FilterChip(
                      avatar: AvatarWidget(name: name, size: 22),
                      label: Text(name),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _participantUids.add(uid);
                          } else {
                            _participantUids.remove(uid);
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
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
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
