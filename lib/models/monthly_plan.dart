import 'package:uuid/uuid.dart';
import 'package:daily_sales_plan_tracker/models/bonus_rules.dart';

class MonthlyPlan {
  final String id;
  final int month;
  final int year;
  final int gaPlan;
  final int hvPlan;
  final int devicePlan;
  final int plannedWorkingShifts;
  final int baseSalary;
  final BonusRules bonusRules;
  final DateTime createdAt;
  final bool isArchived;

  MonthlyPlan({
    String? id,
    required this.month,
    required this.year,
    required this.gaPlan,
    required this.hvPlan,
    required this.devicePlan,
    required this.plannedWorkingShifts,
    this.baseSalary = 0,
    BonusRules? bonusRules,
    DateTime? createdAt,
    this.isArchived = false,
  })  : id = id ?? const Uuid().v4(),
        // NOTE: Bonus rules are fixed by product requirements (not user-editable).
        // Even if older saved data contains user-custom tiers, we always force the
        // official program.
        bonusRules = BonusRules.fixedProgram(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'gaPlan': gaPlan,
      'hvPlan': hvPlan,
      'devicePlan': devicePlan,
      'plannedWorkingShifts': plannedWorkingShifts,
      'baseSalary': baseSalary,
      'bonusRules': bonusRules.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'isArchived': isArchived,
    };
  }

  factory MonthlyPlan.fromJson(Map<String, dynamic> json) {
    return MonthlyPlan(
      id: json['id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      gaPlan: json['gaPlan'] as int,
      hvPlan: json['hvPlan'] as int,
      devicePlan: json['devicePlan'] as int,
      plannedWorkingShifts: json['plannedWorkingShifts'] as int,
      baseSalary: (json['baseSalary'] as num?)?.toInt() ?? 0,
      // Ignore persisted custom tiers and always use the fixed program.
      bonusRules: BonusRules.fixedProgram(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  MonthlyPlan copyWith({
    int? gaPlan,
    int? hvPlan,
    int? devicePlan,
    int? plannedWorkingShifts,
    int? baseSalary,
    BonusRules? bonusRules,
    bool? isArchived,
  }) {
    return MonthlyPlan(
      id: id,
      month: month,
      year: year,
      gaPlan: gaPlan ?? this.gaPlan,
      hvPlan: hvPlan ?? this.hvPlan,
      devicePlan: devicePlan ?? this.devicePlan,
      plannedWorkingShifts: plannedWorkingShifts ?? this.plannedWorkingShifts,
      baseSalary: baseSalary ?? this.baseSalary,
      bonusRules: bonusRules ?? this.bonusRules,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
