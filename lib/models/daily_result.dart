import 'package:uuid/uuid.dart';

class DailyResult {
  final String id;
  final DateTime date;
  final int month;
  final int year;
  final int gaFact;
  final int hvFact;
  final int deviceFact;
  final bool isWorkingDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyResult({
    String? id,
    required this.date,
    required this.month,
    required this.year,
    required this.gaFact,
    required this.hvFact,
    required this.deviceFact,
    required this.isWorkingDay,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'month': month,
      'year': year,
      'gaFact': gaFact,
      'hvFact': hvFact,
      'deviceFact': deviceFact,
      'isWorkingDay': isWorkingDay,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyResult.fromJson(Map<String, dynamic> json) {
    return DailyResult(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      month: json['month'] as int,
      year: json['year'] as int,
      gaFact: json['gaFact'] as int,
      hvFact: json['hvFact'] as int,
      deviceFact: json['deviceFact'] as int,
      isWorkingDay: json['isWorkingDay'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  DailyResult copyWith({
    int? gaFact,
    int? hvFact,
    int? deviceFact,
    bool? isWorkingDay,
  }) {
    return DailyResult(
      id: id,
      date: date,
      month: month,
      year: year,
      gaFact: gaFact ?? this.gaFact,
      hvFact: hvFact ?? this.hvFact,
      deviceFact: deviceFact ?? this.deviceFact,
      isWorkingDay: isWorkingDay ?? this.isWorkingDay,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
