import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_sales_plan_tracker/models/daily_result.dart';
import 'package:daily_sales_plan_tracker/models/monthly_plan.dart';

class StorageService {
  static const String _keyPlans = 'monthly_plans';
  static const String _keyResults = 'daily_results';

  Future<SharedPreferences?> _prefsSafe() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('StorageService: failed to init SharedPreferences: $e');
      return null;
    }
  }

  Future<void> savePlans(List<MonthlyPlan> plans) async {
    final prefs = await _prefsSafe();
    if (prefs == null) return;
    try {
      final String data = jsonEncode(plans.map((e) => e.toJson()).toList());
      await prefs.setString(_keyPlans, data);
    } catch (e) {
      debugPrint('StorageService: failed to save plans: $e');
    }
  }

  Future<List<MonthlyPlan>> getPlans() async {
    final prefs = await _prefsSafe();
    if (prefs == null) return [];
    final String? data = prefs.getString(_keyPlans);
    if (data == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      final plans = <MonthlyPlan>[];
      bool hadInvalid = false;
      for (final e in jsonList) {
        try {
          if (e is Map<String, dynamic>) {
            plans.add(MonthlyPlan.fromJson(e));
          } else {
            hadInvalid = true;
          }
        } catch (_) {
          hadInvalid = true;
        }
      }

      if (hadInvalid) {
        // Auto-sanitize so future loads won't keep failing.
        await savePlans(plans);
      }

      return plans;
    } catch (e) {
      debugPrint('StorageService: failed to decode plans: $e');
      return [];
    }
  }

  Future<void> saveResults(List<DailyResult> results) async {
    final prefs = await _prefsSafe();
    if (prefs == null) return;
    try {
      final String data = jsonEncode(results.map((e) => e.toJson()).toList());
      await prefs.setString(_keyResults, data);
    } catch (e) {
      debugPrint('StorageService: failed to save results: $e');
    }
  }

  Future<List<DailyResult>> getResults() async {
    final prefs = await _prefsSafe();
    if (prefs == null) return [];
    final String? data = prefs.getString(_keyResults);
    if (data == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data);
      final results = <DailyResult>[];
      bool hadInvalid = false;
      for (final e in jsonList) {
        try {
          if (e is Map<String, dynamic>) {
            results.add(DailyResult.fromJson(e));
          } else {
            hadInvalid = true;
          }
        } catch (_) {
          hadInvalid = true;
        }
      }

      if (hadInvalid) {
        await saveResults(results);
      }

      return results;
    } catch (e) {
      debugPrint('StorageService: failed to decode results: $e');
      return [];
    }
  }

  Future<void> clearAll() async {
    final prefs = await _prefsSafe();
    if (prefs == null) return;
    try {
      await prefs.clear();
    } catch (e) {
      debugPrint('StorageService: failed to clear: $e');
    }
  }
}
