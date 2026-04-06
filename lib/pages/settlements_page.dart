import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/group_model.dart';
import '../models/expense_model.dart';
import '../models/settlement_model.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/empty_state.dart';

/// Settlements page — all real-time using StreamBuilder
class SettlementsPage extends StatelessWidget {
  const SettlementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<GroupModel>>(
        stream: provider.firestoreService.getMyGroupsStream(provider.currentUid),
        builder: (context, groupSnapshot) {
          final groups = groupSnapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settlements',
                          style: Theme.of(context).textTheme.displayLarge),
                      const SizedBox(height: 4),
                      Text('Settle debts and view history',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),

              if (groups.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'No groups yet',
                    subtitle: 'Create groups and add expenses first',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _GroupSettlementCard(
                          group: groups[index],
                          provider: provider,
                        );
                      },
                      childCount: groups.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Group Settlement Card — FULLY real-time
// ─────────────────────────────────────────────
class _GroupSettlementCard extends StatelessWidget {
  final GroupModel group;
  final AppProvider provider;
  const _GroupSettlementCard({required this.group, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child:
                        Text(group.icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(group.name,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                FilledButton.tonal(
                  onPressed: () => _settleGroup(context),
                  child: const Text('Settle Up'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active debts — NOW uses StreamBuilder for real-time updates!
            StreamBuilder<Map<String, double>>(
              stream:
                  provider.firestoreService.calculateBalancesStream(group.id),
              builder: (context, balanceSnapshot) {
                if (balanceSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 40,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final balances = balanceSnapshot.data ?? {};
                final simplified =
                    provider.firestoreService.simplifyDebts(balances);

                if (simplified.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppTheme.success, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'All settled up! 🎉',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: simplified.map((txn) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DebtArrow(
                        from: provider.resolveUserName(txn['from']),
                        to: provider.resolveUserName(txn['to']),
                        amount: txn['amount'],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Settlement history — already real-time via StreamBuilder
            Text('Settlement History',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            StreamBuilder<List<SettlementModel>>(
              stream:
                  provider.firestoreService.getSettlementsStream(group.id),
              builder: (context, settlementSnapshot) {
                final settlements = settlementSnapshot.data ?? [];
                if (settlements.isEmpty) {
                  return Text('No settlements yet',
                      style: Theme.of(context).textTheme.bodySmall);
                }
                return Column(
                  children: settlements.take(5).map((s) {
                    final dateStr =
                        DateFormat('MMM d, y').format(s.settledAt);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 16, color: AppTheme.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${provider.resolveUserName(s.from)} paid ${provider.resolveUserName(s.to)} ₹${s.amount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(dateStr,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _settleGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle All Debts'),
        content: Text(
            'Settle all debts in "${group.name}"? This will clear all expenses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.firestoreService.settleDebts(group.id);
              Navigator.pop(ctx);
            },
            child: const Text('Settle'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Debt Arrow
// ─────────────────────────────────────────────
class _DebtArrow extends StatelessWidget {
  final String from;
  final String to;
  final double amount;
  const _DebtArrow({
    required this.from,
    required this.to,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          AvatarWidget(name: from, size: 30),
          const SizedBox(width: 8),
          Text(from, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.error.withValues(alpha: 0.6),
                          AppTheme.warning,
                          AppTheme.success.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    color: AppTheme.warning, size: 16),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: AppTheme.warning,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(to, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: 8),
          AvatarWidget(name: to, size: 30),
        ],
      ),
    );
  }
}
