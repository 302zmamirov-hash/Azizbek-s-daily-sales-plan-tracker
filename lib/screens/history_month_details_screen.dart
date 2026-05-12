import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:daily_sales_plan_tracker/models/daily_result.dart';
import 'package:daily_sales_plan_tracker/models/monthly_plan.dart';
import 'package:daily_sales_plan_tracker/providers/sales_provider.dart';
import 'package:daily_sales_plan_tracker/theme.dart';

class HistoryMonthDetailsScreen extends StatelessWidget {
  final int year;
  final int month;

  const HistoryMonthDetailsScreen({super.key, required this.year, required this.month});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final plan = provider.getPlanForMonth(year, month);
    final results = provider.getResultsForMonth(year, month)..sort((a, b) => a.date.compareTo(b.date));

    final title = DateFormat('MMMM yyyy', 'ru').format(DateTime(year, month));
    final capitalizedTitle = title.isEmpty ? title : title[0].toUpperCase() + title.substring(1);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(capitalizedTitle, style: context.textStyles.headlineSmall)),
                ],
              ),
            ),
            if (plan == null)
              Expanded(
                child: Center(
                  child: Text(
                    'План за этот месяц не найден.',
                    style: context.textStyles.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                  children: [
                    _SummaryHeader(plan: plan, results: results),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Дни', style: context.textStyles.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    if (results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Center(
                          child: Text(
                            'Нет записей за этот месяц.',
                            style: context.textStyles.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      ...results.map((r) => _DailyResultTile(result: r)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final MonthlyPlan plan;
  final List<DailyResult> results;

  const _SummaryHeader({required this.plan, required this.results});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SalesProvider>();
    final ga = provider.calculateStats(MetricType.ga, specificPlan: plan, specificResults: results);
    final hv = provider.calculateStats(MetricType.hv, specificPlan: plan, specificResults: results);
    final dev = provider.calculateStats(MetricType.devices, specificPlan: plan, specificResults: results);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Text('Смены: ${ga.workedShifts}/${plan.plannedWorkingShifts}', style: context.textStyles.titleSmall),
            ],
          ),
          const SizedBox(height: 14),
          _MiniMetricLine(name: 'GA', fact: ga.fact, planValue: ga.plan, percent: ga.completionPercentage),
          const SizedBox(height: 8),
          _MiniMetricLine(name: 'HV', fact: hv.fact, planValue: hv.plan, percent: hv.completionPercentage),
          const SizedBox(height: 8),
          _MiniMetricLine(name: 'Девайсы', fact: dev.fact, planValue: dev.plan, percent: dev.completionPercentage),
        ],
      ),
    );
  }
}

class _MiniMetricLine extends StatelessWidget {
  final String name;
  final int fact;
  final int planValue;
  final double percent;

  const _MiniMetricLine({required this.name, required this.fact, required this.planValue, required this.percent});

  @override
  Widget build(BuildContext context) {
    final p = percent.isFinite ? percent : 0.0;
    return Row(
      children: [
        Expanded(child: Text(name, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        Text('$fact / $planValue', style: context.textStyles.bodyMedium),
        const SizedBox(width: 12),
        Text('${p.clamp(0.0, 999.0).toStringAsFixed(0)}%', style: context.textStyles.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _DailyResultTile extends StatelessWidget {
  final DailyResult result;

  const _DailyResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM, EEE', 'ru').format(result.date);
    final isOff = !result.isWorkingDay;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 42,
            decoration: BoxDecoration(
              color: isOff ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.25) : Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateLabel, style: context.textStyles.titleSmall),
                const SizedBox(height: 6),
                Text(
                  isOff ? 'Выходной' : 'GA ${result.gaFact} • HV ${result.hvFact} • Девайсы ${result.deviceFact}',
                  style: context.textStyles.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
