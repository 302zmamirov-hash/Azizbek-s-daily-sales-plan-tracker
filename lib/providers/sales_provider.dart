import 'package:flutter/material.dart';
import 'package:daily_sales_plan_tracker/models/daily_result.dart';
import 'package:daily_sales_plan_tracker/models/bonus_rules.dart';
import 'package:daily_sales_plan_tracker/models/monthly_plan.dart';
import 'package:daily_sales_plan_tracker/services/storage_service.dart';

class YearMonth {
  final int year;
  final int month;
  const YearMonth(this.year, this.month);

  @override
  bool operator ==(Object other) => other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

enum MetricType { ga, hv, devices }

class BonusMetricSnapshot {
  final MetricType metric;
  final double forecastCompletionPercent;
  final double achievedBonusPercent;
  final int projectedBonusAmount;
  final BonusTier? achievedTier;
  final BonusTier? nextTier;

  const BonusMetricSnapshot({
    required this.metric,
    required this.forecastCompletionPercent,
    required this.achievedBonusPercent,
    required this.projectedBonusAmount,
    required this.achievedTier,
    required this.nextTier,
  });
}

class BonusOpportunity {
  final MetricType metric;
  final BonusTier nextTier;
  final int remainingShifts;
  final int additionalFactNeeded;
  final int additionalPerShift;
  final int extraIncomeUnlocked;

  const BonusOpportunity({
    required this.metric,
    required this.nextTier,
    required this.remainingShifts,
    required this.additionalFactNeeded,
    required this.additionalPerShift,
    required this.extraIncomeUnlocked,
  });
}

class MetricStats {
  final int plan;
  final int fact;
  final int remainingPlan;
  final int workedShifts;
  final int remainingShifts;
  final double averagePerShift;
  final int forecast;
  final double completionPercentage;
  final int nextShiftTarget;

  MetricStats({
    required this.plan,
    required this.fact,
    required this.remainingPlan,
    required this.workedShifts,
    required this.remainingShifts,
    required this.averagePerShift,
    required this.forecast,
    required this.completionPercentage,
    required this.nextShiftTarget,
  });
}

class SalesProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<MonthlyPlan> _plans = [];
  List<DailyResult> _results = [];
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<MonthlyPlan> get plans => _plans;
  List<DailyResult> get results => _results;

  MonthlyPlan? get currentPlan {
    final now = DateTime.now();
    try {
      return _plans.firstWhere((p) => p.month == now.month && p.year == now.year);
    } catch (e) {
      return null;
    }
  }

  MonthlyPlan? getPlanForMonth(int year, int month) {
    try {
      return _plans.firstWhere((p) => p.month == month && p.year == year);
    } catch (_) {
      return null;
    }
  }

  List<DailyResult> getResultsForMonth(int year, int month) => _results.where((r) => r.month == month && r.year == year).toList();

  List<DailyResult> get currentMonthResults {
    final plan = currentPlan;
    if (plan == null) return [];
    return _results.where((r) => r.month == plan.month && r.year == plan.year).toList();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _plans = await _storageService.getPlans();
      _results = await _storageService.getResults();

      // Check if we need to start a new month
      final now = DateTime.now();
      if (_plans.isNotEmpty) {
        final hasCurrentMonth = _plans.any((p) => p.month == now.month && p.year == now.year);
        if (!hasCurrentMonth) {
          // Archive all existing plans (they are all past months now).
          _plans = _plans.map((p) => p.copyWith(isArchived: true)).toList();
          await _storageService.savePlans(_plans);
        } else {
          // Ensure only past months are marked archived.
          bool changed = false;
          _plans = _plans.map((p) {
            final shouldBeArchived = !(p.month == now.month && p.year == now.year);
            if (p.isArchived != shouldBeArchived) changed = true;
            return p.copyWith(isArchived: shouldBeArchived);
          }).toList();
          if (changed) await _storageService.savePlans(_plans);
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String buildCurrentMonthReportCsv() {
    final plan = currentPlan;
    if (plan == null) return '';
    final results = currentMonthResults.toList()..sort((a, b) => a.date.compareTo(b.date));

    String esc(String s) => '"${s.replaceAll('"', '""')}"';
    final buffer = StringBuffer();
    buffer.writeln('Month,Year,PlannedShifts,GA Plan,HV Plan,Devices Plan');
    buffer.writeln('${plan.month},${plan.year},${plan.plannedWorkingShifts},${plan.gaPlan},${plan.hvPlan},${plan.devicePlan}');
    buffer.writeln('');
    buffer.writeln('Date,GA,HV,Devices,WorkingDay');
    for (final r in results) {
      final date = '${r.date.year.toString().padLeft(4, '0')}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
      buffer.writeln('${esc(date)},${r.gaFact},${r.hvFact},${r.deviceFact},${r.isWorkingDay ? 1 : 0}');
    }
    return buffer.toString();
  }

  Future<void> saveMonthlyPlan({
    required int gaPlan,
    required int hvPlan,
    required int devicePlan,
    required int plannedWorkingShifts,
    required int baseSalary,
    BonusRules? bonusRules,
  }) async {
    final now = DateTime.now();
    final newPlan = MonthlyPlan(
      month: now.month,
      year: now.year,
      gaPlan: gaPlan,
      hvPlan: hvPlan,
      devicePlan: devicePlan,
      plannedWorkingShifts: plannedWorkingShifts,
      baseSalary: baseSalary,
      // Fixed official program; ignore any caller-provided tiers.
      bonusRules: BonusRules.fixedProgram(),
    );

    // Remove existing for this month if any
    _plans.removeWhere((p) => p.month == now.month && p.year == now.year);
    _plans.add(newPlan);
    
    await _storageService.savePlans(_plans);
    notifyListeners();
  }

  Future<void> updateMonthlyPlan({
    required int gaPlan,
    required int hvPlan,
    required int devicePlan,
    required int plannedWorkingShifts,
    int? baseSalary,
    BonusRules? bonusRules,
  }) async {
    final plan = currentPlan;
    if (plan == null) return;

    final updatedPlan = plan.copyWith(
      gaPlan: gaPlan,
      hvPlan: hvPlan,
      devicePlan: devicePlan,
      plannedWorkingShifts: plannedWorkingShifts,
      baseSalary: baseSalary,
      // Fixed official program; ignore any caller-provided tiers.
      bonusRules: BonusRules.fixedProgram(),
    );

    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _plans[index] = updatedPlan;
      await _storageService.savePlans(_plans);
      notifyListeners();
    }
  }

  Future<void> saveDailyResult({
    required DateTime date,
    required int gaFact,
    required int hvFact,
    required int deviceFact,
  }) async {
    final bool isWorkingDay = gaFact > 0 || hvFact > 0 || deviceFact > 0;
    
    final existingIndex = _results.indexWhere(
      (r) => r.date.year == date.year && 
             r.date.month == date.month && 
             r.date.day == date.day
    );

    if (existingIndex != -1) {
      _results[existingIndex] = _results[existingIndex].copyWith(
        gaFact: gaFact,
        hvFact: hvFact,
        deviceFact: deviceFact,
        isWorkingDay: isWorkingDay,
      );
    } else {
      _results.add(DailyResult(
        date: date,
        month: date.month,
        year: date.year,
        gaFact: gaFact,
        hvFact: hvFact,
        deviceFact: deviceFact,
        isWorkingDay: isWorkingDay,
      ));
    }

    await _storageService.saveResults(_results);
    notifyListeners();
  }

  DailyResult? getResultForDate(DateTime date) {
    try {
      return _results.firstWhere(
        (r) => r.date.year == date.year && 
               r.date.month == date.month && 
               r.date.day == date.day
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> resetCurrentMonth() async {
    final plan = currentPlan;
    if (plan == null) return;

    _plans.removeWhere((p) => p.id == plan.id);
    _results.removeWhere((r) => r.month == plan.month && r.year == plan.year);

    await _storageService.savePlans(_plans);
    await _storageService.saveResults(_results);
    notifyListeners();
  }

  MetricStats calculateStats(MetricType type, {MonthlyPlan? specificPlan, List<DailyResult>? specificResults}) {
    final plan = specificPlan ?? currentPlan;
    if (plan == null) {
      return MetricStats(
        plan: 0, fact: 0, remainingPlan: 0, workedShifts: 0, remainingShifts: 0,
        averagePerShift: 0, forecast: 0, completionPercentage: 0, nextShiftTarget: 0,
      );
    }

    final resultsToUse = specificResults ?? currentMonthResults;
    
    int targetPlan = 0;
    int fact = 0;

    switch (type) {
      case MetricType.ga:
        targetPlan = plan.gaPlan;
        fact = resultsToUse.fold(0, (sum, r) => sum + r.gaFact);
        break;
      case MetricType.hv:
        targetPlan = plan.hvPlan;
        fact = resultsToUse.fold(0, (sum, r) => sum + r.hvFact);
        break;
      case MetricType.devices:
        targetPlan = plan.devicePlan;
        fact = resultsToUse.fold(0, (sum, r) => sum + r.deviceFact);
        break;
    }

    final workedShifts = resultsToUse.where((r) => r.isWorkingDay).length;
    final remainingShifts = (plan.plannedWorkingShifts - workedShifts) < 0 ? 0 : (plan.plannedWorkingShifts - workedShifts);
    
    final remainingPlan = (targetPlan - fact) < 0 ? 0 : (targetPlan - fact);
    
    final averagePerShift = workedShifts > 0 ? fact / workedShifts : 0.0;
    final forecast = (averagePerShift * plan.plannedWorkingShifts).round();
    
    final completionPercentage = targetPlan > 0 ? (fact / targetPlan) * 100 : 0.0;
    
    int nextShiftTarget = 0;
    if (remainingShifts > 0) {
      nextShiftTarget = (remainingPlan / remainingShifts).ceil();
    }

    return MetricStats(
      plan: targetPlan,
      fact: fact,
      remainingPlan: remainingPlan,
      workedShifts: workedShifts,
      remainingShifts: remainingShifts,
      averagePerShift: averagePerShift,
      forecast: forecast,
      completionPercentage: completionPercentage,
      nextShiftTarget: nextShiftTarget,
    );
  }

  List<BonusTier> _tiersFor(MetricType type, MonthlyPlan plan) {
    final tiers = switch (type) {
      MetricType.ga => plan.bonusRules.ga,
      MetricType.hv => plan.bonusRules.hv,
      MetricType.devices => plan.bonusRules.devices,
    };
    final sorted = [...tiers]..sort((a, b) => a.thresholdPercent.compareTo(b.thresholdPercent));
    return sorted;
  }

  BonusMetricSnapshot calculateBonusSnapshot(MetricType type, {MonthlyPlan? specificPlan, List<DailyResult>? specificResults}) {
    final plan = specificPlan ?? currentPlan;
    if (plan == null) {
      return const BonusMetricSnapshot(
        metric: MetricType.ga,
        forecastCompletionPercent: 0,
        achievedBonusPercent: 0,
        projectedBonusAmount: 0,
        achievedTier: null,
        nextTier: null,
      );
    }

    final stats = calculateStats(type, specificPlan: plan, specificResults: specificResults);
    final tiers = _tiersFor(type, plan);

    final forecastCompletionPercent = stats.plan > 0 ? (stats.forecast / stats.plan) * 100 : 0.0;

    BonusTier? achieved;
    for (final tier in tiers) {
      if (forecastCompletionPercent + 1e-9 >= tier.thresholdPercent) achieved = tier;
    }

    BonusTier? next;
    for (final tier in tiers) {
      if (forecastCompletionPercent + 1e-9 < tier.thresholdPercent) {
        next = tier;
        break;
      }
    }

    final achievedBonusPercent = achieved?.bonusPercent ?? 0.0;
    final projectedBonusAmount = ((plan.baseSalary * achievedBonusPercent) / 100).round();

    return BonusMetricSnapshot(
      metric: type,
      forecastCompletionPercent: forecastCompletionPercent,
      achievedBonusPercent: achievedBonusPercent,
      projectedBonusAmount: projectedBonusAmount,
      achievedTier: achieved,
      nextTier: next,
    );
  }

  BonusOpportunity? calculateNextOpportunity(MetricType type, {MonthlyPlan? specificPlan, List<DailyResult>? specificResults}) {
    final plan = specificPlan ?? currentPlan;
    if (plan == null) return null;

    final stats = calculateStats(type, specificPlan: plan, specificResults: specificResults);
    if (stats.plan <= 0) return null;

    final snapshot = calculateBonusSnapshot(type, specificPlan: plan, specificResults: specificResults);
    final nextTier = snapshot.nextTier;
    if (nextTier == null) return null;

    final remainingShifts = stats.remainingShifts;
    if (remainingShifts <= 0) return null;

    final targetForecastFact = ((stats.plan * nextTier.thresholdPercent) / 100).ceil();
    final additionalFactNeeded = (targetForecastFact - stats.forecast) < 0 ? 0 : (targetForecastFact - stats.forecast);
    if (additionalFactNeeded <= 0) return null;

    final additionalPerShift = (additionalFactNeeded / remainingShifts).ceil();
    final nextBonusAmount = ((plan.baseSalary * nextTier.bonusPercent) / 100).round();
    final extraIncomeUnlocked = (nextBonusAmount - snapshot.projectedBonusAmount) < 0 ? 0 : (nextBonusAmount - snapshot.projectedBonusAmount);

    return BonusOpportunity(
      metric: type,
      nextTier: nextTier,
      remainingShifts: remainingShifts,
      additionalFactNeeded: additionalFactNeeded,
      additionalPerShift: additionalPerShift,
      extraIncomeUnlocked: extraIncomeUnlocked,
    );
  }

  /// Returns the most motivating next opportunity (highest extra unlocked income).
  BonusOpportunity? calculateBestNextOpportunity({MonthlyPlan? specificPlan, List<DailyResult>? specificResults}) {
    final plan = specificPlan ?? currentPlan;
    if (plan == null) return null;

    final opportunities = <BonusOpportunity>[];
    for (final metric in MetricType.values) {
      final opp = calculateNextOpportunity(metric, specificPlan: plan, specificResults: specificResults);
      if (opp != null) opportunities.add(opp);
    }

    if (opportunities.isEmpty) return null;
    opportunities.sort((a, b) => b.extraIncomeUnlocked.compareTo(a.extraIncomeUnlocked));
    return opportunities.first;
  }
}
