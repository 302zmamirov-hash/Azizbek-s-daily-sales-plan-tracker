import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:daily_sales_plan_tracker/providers/sales_provider.dart';
import 'package:daily_sales_plan_tracker/theme.dart';

class BonusScreen extends StatelessWidget {
  const BonusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final plan = provider.currentPlan;

    final missingInputs = plan == null || plan.baseSalary <= 0 || plan.plannedWorkingShifts <= 0 || (plan.gaPlan <= 0 && plan.hvPlan <= 0 && plan.devicePlan <= 0);

    if (missingInputs) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Text(
                'Введите оклад и месячный план в настройках, чтобы рассчитать бонус.',
                style: context.textStyles.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final ga = provider.calculateBonusSnapshot(MetricType.ga);
    final hv = provider.calculateBonusSnapshot(MetricType.hv);
    final devices = provider.calculateBonusSnapshot(MetricType.devices);
    final totalBonus = (ga.projectedBonusAmount + hv.projectedBonusAmount + devices.projectedBonusAmount).clamp(0, 1 << 31);
    final totalIncome = (plan.baseSalary + totalBonus).clamp(0, 1 << 31);

    final money = NumberFormat.decimalPattern('ru');
    String fmtMoney(int v) => money.format(v);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Бонус', style: context.textStyles.headlineLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Прогноз и мотивация рассчитываются автоматически по официальной программе.',
                style: context.textStyles.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.xl),

              _SummaryCard(
                title: 'Базовый оклад',
                valueText: fmtMoney(plan.baseSalary),
                icon: Icons.payments_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              _SummaryCard(
                title: 'Прогноз бонуса',
                valueText: fmtMoney(totalBonus),
                icon: Icons.emoji_events_rounded,
                accent: Theme.of(context).colorScheme.primary,
                zeroHint: totalBonus == 0 ? 'Для выхода на бонус нужно увеличить средний результат.' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              _SummaryCard(
                title: 'Прогноз дохода (оклад + бонус)',
                valueText: fmtMoney(totalIncome),
                icon: Icons.auto_graph_rounded,
                accent: Theme.of(context).colorScheme.tertiary,
              ),

              const SizedBox(height: AppSpacing.xl),
              Text('Детализация по KPI', style: context.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.md),

              _MetricBonusCard(metric: MetricType.ga, title: 'GA / Quality B2C', icon: Icons.sim_card_rounded, snapshot: ga, fmtMoney: fmtMoney),
              const SizedBox(height: AppSpacing.md),
              _MetricBonusCard(metric: MetricType.hv, title: 'HV', icon: Icons.star_rounded, snapshot: hv, fmtMoney: fmtMoney),
              const SizedBox(height: AppSpacing.md),
              _MetricBonusCard(metric: MetricType.devices, title: 'Девайсы', icon: Icons.phone_iphone_rounded, snapshot: devices, fmtMoney: fmtMoney),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String valueText;
  final IconData icon;
  final Color? accent;
  final String? zeroHint;

  const _SummaryCard({required this.title, required this.valueText, required this.icon, this.accent, this.zeroHint});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = accent ?? cs.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.surface, a.withValues(alpha: 0.10)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: a.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: a),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: context.textStyles.titleSmall?.copyWith(color: cs.onSurfaceVariant))),
            ],
          ),
          const SizedBox(height: 10),
          Text(valueText, style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurface)),
          if (zeroHint != null) ...[
            const SizedBox(height: 8),
            Text(zeroHint!, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
          ],
        ],
      ),
    );
  }
}

class _MetricBonusCard extends StatelessWidget {
  final MetricType metric;
  final String title;
  final IconData icon;
  final BonusMetricSnapshot snapshot;
  final String Function(int) fmtMoney;

  const _MetricBonusCard({required this.metric, required this.title, required this.icon, required this.snapshot, required this.fmtMoney});

  String _metricUnit() => switch (metric) {
    MetricType.ga => 'GA',
    MetricType.hv => 'HV',
    MetricType.devices => 'девайсов',
  };

  Color _accent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (metric) {
      MetricType.ga => cs.primary,
      MetricType.hv => cs.secondary,
      MetricType.devices => cs.tertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final cs = Theme.of(context).colorScheme;
    final accent = _accent(context);
    final percent = snapshot.forecastCompletionPercent.isFinite ? snapshot.forecastCompletionPercent : 0.0;
    final currentTierPercent = snapshot.achievedBonusPercent.round();
    final nextTier = snapshot.nextTier;
    final opp = provider.calculateNextOpportunity(metric);

    final hasBonus = snapshot.projectedBonusAmount > 0;
    final motivational = 'Для выхода на бонус нужно увеличить средний результат.';

    String nextLine;
    if (nextTier == null) {
      nextLine = 'Вы уже на максимальном уровне по этому KPI. Супер!';
    } else if (opp == null) {
      nextLine = 'Следующий уровень: ${nextTier.thresholdPercent.toStringAsFixed(0)}% (+${nextTier.bonusPercent.toStringAsFixed(0)}% к окладу).';
    } else {
      final unit = _metricUnit();
      final nextPct = nextTier.thresholdPercent.toStringAsFixed(0);
      final addFact = opp.additionalFactNeeded;
      final perShift = opp.additionalPerShift;
      nextLine = 'До следующего уровня $nextPct% осталось $addFact $unit.\n'
          'Это всего +$perShift $unit за оставшуюся смену.\n'
          'Можно открыть дополнительный бонус.';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              _PercentPill(text: '${percent.round()}%', accent: accent),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          _KeyValueLine(label: 'Текущий уровень', value: '$currentTierPercent% от оклада'),
          const SizedBox(height: 10),
          _KeyValueLine(
            label: 'Прогноз бонуса',
            value: hasBonus ? '+${fmtMoney(snapshot.projectedBonusAmount)}' : '0',
            valueColor: hasBonus ? accent : cs.onSurface,
            emphasized: true,
          ),
          if (!hasBonus) ...[
            const SizedBox(height: 8),
            Text(motivational, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
          ],

          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: accent.withValues(alpha: 0.16)),
            ),
            child: Text(nextLine, style: context.textStyles.bodyMedium?.copyWith(height: 1.45)),
          ),
        ],
      ),
    );
  }
}

class _PercentPill extends StatelessWidget {
  final String text;
  final Color accent;
  const _PercentPill({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(text, style: context.textStyles.labelLarge?.copyWith(color: accent, fontWeight: FontWeight.w800)),
    );
  }
}

class _KeyValueLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;
  const _KeyValueLine({required this.label, required this.value, this.valueColor, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vColor = valueColor ?? cs.onSurface;
    final vStyle = emphasized
        ? context.textStyles.titleLarge?.copyWith(color: vColor, fontWeight: FontWeight.w900)
        : context.textStyles.titleMedium?.copyWith(color: vColor, fontWeight: FontWeight.w800);

    return Row(
      children: [
        Expanded(child: Text(label, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
        const SizedBox(width: 10),
        Text(value, style: vStyle),
      ],
    );
  }
}
