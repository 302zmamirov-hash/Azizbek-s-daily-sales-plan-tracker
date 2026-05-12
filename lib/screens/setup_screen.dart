import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:daily_sales_plan_tracker/providers/sales_provider.dart';
import 'package:daily_sales_plan_tracker/theme.dart';

class SetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const SetupScreen({super.key, required this.onSetupComplete});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _gaController = TextEditingController();
  final _hvController = TextEditingController();
  final _devicesController = TextEditingController();
  final _shiftsController = TextEditingController();
  final _baseSalaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _gaController.dispose();
    _hvController.dispose();
    _devicesController.dispose();
    _shiftsController.dispose();
    _baseSalaryController.dispose();
    super.dispose();
  }

  void _savePlan() async {
    if (_formKey.currentState!.validate()) {
      final gaPlan = int.tryParse(_gaController.text) ?? 0;
      final hvPlan = int.tryParse(_hvController.text) ?? 0;
      final devicePlan = int.tryParse(_devicesController.text) ?? 0;
      final shifts = int.tryParse(_shiftsController.text) ?? 0;
      final baseSalary = int.tryParse(_baseSalaryController.text) ?? 0;

      await context.read<SalesProvider>().saveMonthlyPlan(
        gaPlan: gaPlan,
        hvPlan: hvPlan,
        devicePlan: devicePlan,
        plannedWorkingShifts: shifts,
        baseSalary: baseSalary,
      );

      widget.onSetupComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'ru').format(now);
    final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flag_circle_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'Новый месяц',
                    style: context.textStyles.headlineMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    capitalizedMonth,
                    style: context.textStyles.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Введите ваш план на месяц, чтобы начать отслеживать ежедневный прогресс.',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Доход и бонусы',
                  style: context.textStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),

                _buildInputField(
                  controller: _baseSalaryController,
                  label: 'Базовый оклад (сум)',
                  icon: Icons.payments_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Процент бонуса считается автоматически по официальной программе.\nПороговые уровни менять нельзя.',
                  style: context.textStyles.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                _buildInputField(
                  controller: _gaController,
                  label: 'План GA (Gross Activations)',
                  icon: Icons.sim_card_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                
                _buildInputField(
                  controller: _hvController,
                  label: 'План HV (High Value)',
                  icon: Icons.star_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                
                _buildInputField(
                  controller: _devicesController,
                  label: 'План по Девайсам',
                  icon: Icons.phone_iphone_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                
                _buildInputField(
                  controller: _shiftsController,
                  label: 'Запланировано смен',
                  icon: Icons.event_available_rounded,
                ),
                
                const SizedBox(height: AppSpacing.xl * 1.5),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _savePlan,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: Text(
                      'Сохранить и начать',
                      style: context.textStyles.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Обязательное поле';
        }
        if (int.tryParse(value) == null) {
          return 'Введите число';
        }
        return null;
      },
    );
  }
}

