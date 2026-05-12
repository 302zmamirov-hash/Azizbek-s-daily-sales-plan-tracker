class BonusTier {
  /// Completion threshold in percent (e.g. 100 means 100%).
  final double thresholdPercent;

  /// Bonus percent of base salary to be paid when this tier is achieved.
  /// Example: 30 means +30% of base salary.
  final double bonusPercent;

  const BonusTier({required this.thresholdPercent, required this.bonusPercent});

  Map<String, dynamic> toJson() => {
    'thresholdPercent': thresholdPercent,
    'bonusPercent': bonusPercent,
  };

  factory BonusTier.fromJson(Map<String, dynamic> json) => BonusTier(
    thresholdPercent: (json['thresholdPercent'] as num?)?.toDouble() ?? 0,
    bonusPercent: (json['bonusPercent'] as num?)?.toDouble() ?? 0,
  );
}

class BonusRules {
  final List<BonusTier> ga;
  final List<BonusTier> hv;
  final List<BonusTier> devices;

  const BonusRules({required this.ga, required this.hv, required this.devices});

  /// Official fixed bonus program.
  ///
  /// IMPORTANT: These tiers are intentionally hardcoded (not user-editable).
  /// - GA: <93% => 0%, 93-99% => 5%, 100-109% => 35%, 110%+ => 45%
  /// - HV: same as GA
  /// - Devices: <100% => 0%, 100-129% => 30%, 130%+ => 35%
  static BonusRules defaults() => const BonusRules(
    ga: [
      BonusTier(thresholdPercent: 93, bonusPercent: 5),
      BonusTier(thresholdPercent: 100, bonusPercent: 35),
      BonusTier(thresholdPercent: 110, bonusPercent: 45),
    ],
    hv: [
      BonusTier(thresholdPercent: 93, bonusPercent: 5),
      BonusTier(thresholdPercent: 100, bonusPercent: 35),
      BonusTier(thresholdPercent: 110, bonusPercent: 45),
    ],
    devices: [
      BonusTier(thresholdPercent: 100, bonusPercent: 30),
      BonusTier(thresholdPercent: 130, bonusPercent: 35),
    ],
  );

  /// Alias that makes the intent explicit at call sites.
  static BonusRules fixedProgram() => defaults();

  Map<String, dynamic> toJson() => {
    'ga': ga.map((e) => e.toJson()).toList(),
    'hv': hv.map((e) => e.toJson()).toList(),
    'devices': devices.map((e) => e.toJson()).toList(),
  };

  factory BonusRules.fromJson(Map<String, dynamic> json) {
    // Security / product requirement: ignore any persisted user-custom tiers.
    // We still keep JSON parsing for backward compatibility, but always return
    // the official fixed program.
    return BonusRules.fixedProgram();
  }

  BonusRules copyWith({List<BonusTier>? ga, List<BonusTier>? hv, List<BonusTier>? devices}) => BonusRules(
    ga: ga ?? this.ga,
    hv: hv ?? this.hv,
    devices: devices ?? this.devices,
  );
}
