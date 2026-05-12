import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:daily_sales_plan_tracker/providers/sales_provider.dart';
import 'package:daily_sales_plan_tracker/theme.dart';
import 'package:daily_sales_plan_tracker/screens/setup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  MetricType _selectedMetric = MetricType.ga;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.currentPlan == null) {
      return SetupScreen(
        onSetupComplete: () {
          setState(() {});
        },
      );
    }

    final stats = provider.calculateStats(_selectedMetric);
    final now = DateTime.now();
    final dateString = DateFormat('d MMMM yyyy', 'ru').format(now);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateString,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Дашборд',
                        style: context.textStyles.headlineLarge,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Смены',
                          style: context.textStyles.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '${stats.workedShifts}/${stats.workedShifts + stats.remainingShifts}',
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Motivational Text
              _buildMotivationalBanner(context, stats),
              const SizedBox(height: AppSpacing.xl),

              // Metric Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    _buildTab(context, 'GA', MetricType.ga),
                    _buildTab(context, 'HV', MetricType.hv),
                    _buildTab(context, 'Девайсы', MetricType.devices),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Target for Next Day Card (Most Important)
              _buildNextDayTargetCard(context, stats),
              const SizedBox(height: AppSpacing.lg),

              // Status Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'План',
                      value: stats.plan.toString(),
                      icon: Icons.flag_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Факт',
                      value: stats.fact.toString(),
                      icon: Icons.check_circle_rounded,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Остаток',
                      value: stats.remainingPlan.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildForecastCard(context, stats),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Progress Bar
              _buildProgressCard(context, stats),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationalBanner(BuildContext context, MetricStats stats) {
    String message;
    IconData icon;
    Color color;

    if (stats.fact >= stats.plan && stats.plan > 0) {
      message = 'План выполнен! Отличная работа!';
      icon = Icons.emoji_events_rounded;
      color = LightModeColors.statusGreen;
    } else if (stats.forecast >= stats.plan) {
      message = 'Отличный темп, вы в графике!';
      icon = Icons.thumb_up_rounded;
      color = LightModeColors.statusGreen;
    } else if (stats.forecast >= stats.plan * 0.9) {
      message = 'Немного отстаем, нужно поднажать.';
      icon = Icons.directions_run_rounded;
      color = LightModeColors.statusYellow;
    } else {
      message = 'Внимание! Нужно увеличить ежедневный результат.';
      icon = Icons.warning_rounded;
      color = LightModeColors.statusRed;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerColor = isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: context.textStyles.bodyMedium?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, MetricType type) {
    final isSelected = _selectedMetric == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMetric = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: context.textStyles.titleSmall?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextDayTargetCard(BuildContext context, MetricStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            stats.remainingShifts == 0 ? 'Месяц завершен' : 'Цель на следующую смену',
            style: context.textStyles.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stats.remainingShifts == 0 
                ? '-' 
                : (stats.remainingPlan == 0 ? '0' : stats.nextShiftTarget.toString()),
            style: context.textStyles.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (stats.remainingPlan == 0 && stats.plan > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'План выполнен!',
                style: context.textStyles.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: context.textStyles.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: context.textStyles.headlineMedium?.copyWith(
              color: color == LightModeColors.statusRed || color == LightModeColors.statusGreen || color == LightModeColors.statusYellow
                  ? color
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(BuildContext context, MetricStats stats) {
    final forecastColor = _getForecastColor(context, stats.forecast, stats.plan);
    final percent = stats.plan == 0 ? 0 : ((stats.forecast / stats.plan) * 100).round();
    final subduedPercentColor = forecastColor.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
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
            children: [
              Icon(Icons.trending_up_rounded, size: 20, color: forecastColor),
              const SizedBox(width: 8),
              Text(
                'Прогноз',
                style: context.textStyles.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Forecast based on average result per worked shift.',
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                stats.forecast.toString(),
                style: context.textStyles.headlineMedium?.copyWith(color: forecastColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '($percent%)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(color: subduedPercentColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, MetricStats stats) {
    final percent = stats.completionPercentage.clamp(0.0, 100.0) / 100.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Прогресс выполнения',
                style: context.textStyles.titleSmall,
              ),
              Text(
                '${stats.completionPercentage.toStringAsFixed(1)}%',
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getForecastColor(context, stats.forecast, stats.plan),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getForecastColor(BuildContext context, int forecast, int plan) {
    if (plan == 0) return Theme.of(context).colorScheme.primary;
    if (forecast >= plan) return LightModeColors.statusGreen;
    if (forecast >= plan * 0.8) return LightModeColors.statusYellow;
    return LightModeColors.statusRed;
  }
}
