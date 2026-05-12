import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:daily_sales_plan_tracker/models/monthly_plan.dart';
import 'package:daily_sales_plan_tracker/providers/sales_provider.dart';
import 'package:daily_sales_plan_tracker/theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final archivedPlans = provider.plans.where((p) => p.isArchived).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'История',
                style: context.textStyles.headlineLarge,
              ),
            ),
            if (archivedPlans.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет архивных месяцев',
                        style: context.textStyles.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: archivedPlans.length,
                  itemBuilder: (context, index) {
                    final plan = archivedPlans[index];
                    return _buildMonthCard(context, plan, provider);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(BuildContext context, MonthlyPlan plan, SalesProvider provider) {
    final date = DateTime(plan.year, plan.month);
    final monthName = DateFormat('MMMM yyyy', 'ru').format(date);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final results = provider.results.where((r) => r.month == plan.month && r.year == plan.year).toList();
    
    final gaStats = provider.calculateStats(MetricType.ga, specificPlan: plan, specificResults: results);
    final hvStats = provider.calculateStats(MetricType.hv, specificPlan: plan, specificResults: results);
    final deviceStats = provider.calculateStats(MetricType.devices, specificPlan: plan, specificResults: results);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/history/${plan.year}/${plan.month}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                capitalizedMonth,
                style: context.textStyles.titleLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${gaStats.workedShifts} смен',
                  style: context.textStyles.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMetricRow(context, 'GA', gaStats, Icons.sim_card_rounded, Theme.of(context).colorScheme.primary),
          const Divider(height: 24),
          _buildMetricRow(context, 'HV', hvStats, Icons.star_rounded, Colors.orange),
          const Divider(height: 24),
          _buildMetricRow(context, 'Девайсы', deviceStats, Icons.phone_iphone_rounded, Colors.purple),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Открыть детали',
                style: context.textStyles.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, String name, MetricStats stats, IconData icon, Color color) {
    final percent = stats.completionPercentage.clamp(0.0, 100.0);
    final isCompleted = stats.fact >= stats.plan;

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: context.textStyles.titleMedium),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${stats.fact} ',
                    style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '/ ${stats.plan}',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: context.textStyles.titleMedium?.copyWith(
                  color: isCompleted ? LightModeColors.statusGreen : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isCompleted)
                Icon(Icons.check_circle_rounded, color: LightModeColors.statusGreen, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}
