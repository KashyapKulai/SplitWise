import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/expense_model.dart';
import '../models/settlement_model.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/empty_state.dart';

/// Activity timeline — chronological feed of all expenses and settlements
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<ExpenseModel>>(
        stream: provider.firestoreService.getAllExpensesStream(),
        builder: (context, expenseSnapshot) {
          return StreamBuilder<List<SettlementModel>>(
            stream: provider.firestoreService.getAllSettlementsStream(),
            builder: (context, settlementSnapshot) {
              final expenses = expenseSnapshot.data ?? [];
              final settlements = settlementSnapshot.data ?? [];

              // Merge into a unified timeline
              final items = <_ActivityItem>[];

              for (final e in expenses) {
                items.add(_ActivityItem(
                  type: _ActivityType.expense,
                  title: e.title,
                  subtitle: 'Paid by ${provider.resolveUserName(e.paidBy)}',
                  amount: e.amount,
                  category: e.category,
                  timestamp: e.createdAt,
                  person: provider.resolveUserName(e.paidBy),
                ));
              }

              for (final s in settlements) {
                final fromName = provider.resolveUserName(s.from);
                final toName = provider.resolveUserName(s.to);
                items.add(_ActivityItem(
                  type: _ActivityType.settlement,
                  title: '$fromName → $toName',
                  subtitle: 'Settlement',
                  amount: s.amount,
                  category: 'Settlement',
                  timestamp: s.settledAt,
                  person: fromName,
                ));
              }

              // Sort by timestamp, newest first
              items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Activity',
                              style:
                                  Theme.of(context).textTheme.displayLarge),
                          const SizedBox(height: 4),
                          Text('${items.length} events',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),

                  if (items.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.timeline_rounded,
                        title: 'No activity yet',
                        subtitle:
                            'Your expenses and settlements will appear here',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            final isLast = index == items.length - 1;
                            return _ActivityTile(
                              item: item,
                              isLast: isLast,
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Activity Item Model
// ─────────────────────────────────────────────
enum _ActivityType { expense, settlement }

class _ActivityItem {
  final _ActivityType type;
  final String title;
  final String subtitle;
  final double amount;
  final String category;
  final DateTime timestamp;
  final String person;

  _ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.category,
    required this.timestamp,
    required this.person,
  });
}

// ─────────────────────────────────────────────
// Activity Tile with timeline line
// ─────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final _ActivityItem item;
  final bool isLast;
  const _ActivityTile({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSettlement = item.type == _ActivityType.settlement;

    final IconData icon;
    final Color color;

    if (isSettlement) {
      icon = Icons.handshake_rounded;
      color = AppTheme.success;
    } else {
      final info = AppConstants.getCategoryInfo(item.category);
      icon = info['icon'] as IconData;
      color = Color(info['color'] as int);
    }

    final dateStr = DateFormat('MMM d, y · h:mm a').format(item.timestamp);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                enableHover: false,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            '${item.subtitle} · $dateStr',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isSettlement ? '' : ''}₹${item.amount.toStringAsFixed(2)}',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSettlement
                                    ? AppTheme.success
                                    : null,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
