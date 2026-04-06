import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/expense_model.dart';
import '../providers/app_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_counter.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/category_chip.dart';

/// Dashboard page with balance summary, recent transactions, and spending chart
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<ExpenseModel>>(
        stream: provider.firestoreService.getAllExpensesStream(),
        builder: (context, snapshot) {
          final expenses = snapshot.data ?? [];
          final currentUid = provider.currentUid;

          // Calculate balances using UID
          double youOwe = 0;
          double youAreOwed = 0;

          for (final expense in expenses) {
            if (expense.paidBy == currentUid) {
              // You paid, others owe you
              expense.splits.forEach((uid, amount) {
                if (uid != currentUid) {
                  youAreOwed += amount;
                }
              });
            } else if (expense.splits.containsKey(currentUid)) {
              // Someone else paid, you owe them
              youOwe += expense.splits[currentUid] ?? 0;
            }
          }

          return CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome back, ${provider.currentUser}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Balance Cards ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      return isWide
                          ? Row(
                              children: [
                                Expanded(
                                  child: _BalanceCard(
                                    title: 'You Owe',
                                    amount: youOwe,
                                    color: AppTheme.error,
                                    icon: Icons.arrow_upward_rounded,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _BalanceCard(
                                    title: 'You Are Owed',
                                    amount: youAreOwed,
                                    color: AppTheme.success,
                                    icon: Icons.arrow_downward_rounded,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _BalanceCard(
                                    title: 'Net Balance',
                                    amount: youAreOwed - youOwe,
                                    color: (youAreOwed - youOwe) >= 0
                                        ? AppTheme.success
                                        : AppTheme.error,
                                    icon: Icons.account_balance_rounded,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _BalanceCard(
                                  title: 'You Owe',
                                  amount: youOwe,
                                  color: AppTheme.error,
                                  icon: Icons.arrow_upward_rounded,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 12),
                                _BalanceCard(
                                  title: 'You Are Owed',
                                  amount: youAreOwed,
                                  color: AppTheme.success,
                                  icon: Icons.arrow_downward_rounded,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 12),
                                _BalanceCard(
                                  title: 'Net Balance',
                                  amount: youAreOwed - youOwe,
                                  color: (youAreOwed - youOwe) >= 0
                                      ? AppTheme.success
                                      : AppTheme.error,
                                  icon: Icons.account_balance_rounded,
                                  isDark: isDark,
                                ),
                              ],
                            );
                    },
                  ),
                ),
              ),

              // ── Spending Chart + Recent Transactions ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _SpendingChart(
                                expenses: expenses,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _RecentTransactions(
                                expenses: expenses,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _SpendingChart(expenses: expenses, isDark: isDark),
                          const SizedBox(height: 16),
                          _RecentTransactions(expenses: expenses, isDark: isDark),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Balance Card
// ─────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedCounter(
            value: amount.abs(),
            prefix: '₹',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Spending Pie Chart by Category
// ─────────────────────────────────────────────
class _SpendingChart extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final bool isDark;

  const _SpendingChart({required this.expenses, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Aggregate spending by category
    final categoryTotals = <String, double>{};
    for (final e in expenses) {
      categoryTotals[e.category] =
          (categoryTotals[e.category] ?? 0) + e.amount;
    }

    if (categoryTotals.isEmpty) {
      return GlassCard(
        child: SizedBox(
          height: 250,
          child: EmptyState(
            icon: Icons.pie_chart_rounded,
            title: 'No spending data',
            subtitle: 'Add expenses to see your chart',
          ),
        ),
      );
    }

    final sections = categoryTotals.entries.map((entry) {
      final info = AppConstants.getCategoryInfo(entry.key);
      return PieChartSectionData(
        value: entry.value,
        title: '',
        color: Color(info['color'] as int),
        radius: 40,
      );
    }).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 50,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryTotals.entries.map((entry) {
              return CategoryChip(category: entry.key, selected: true);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Recent Transactions
// ─────────────────────────────────────────────
class _RecentTransactions extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final bool isDark;

  const _RecentTransactions({required this.expenses, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final recent = expenses.take(10).toList();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            const SizedBox(
              height: 150,
              child: EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No transactions yet',
                subtitle: 'Your expenses will appear here',
              ),
            )
          else
            ...recent.map((expense) => _TransactionTile(expense: expense)),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final ExpenseModel expense;

  const _TransactionTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final info = AppConstants.getCategoryInfo(expense.category);
    final color = Color(info['color'] as int);
    final icon = info['icon'] as IconData;
    final dateStr = DateFormat('MMM d, h:mm a').format(expense.createdAt);
    final paidByName = provider.resolveUserName(expense.paidBy);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Paid by $paidByName · $dateStr',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '₹${expense.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
