import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:daily_sales_plan_tracker/providers/sales_provider.dart';
import 'package:daily_sales_plan_tracker/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gaController = TextEditingController();
  final _hvController = TextEditingController();
  final _devicesController = TextEditingController();
  final _shiftsController = TextEditingController();
  final _baseSalaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentPlan();
    });
  }

  void _loadCurrentPlan() {
    final plan = context.read<SalesProvider>().currentPlan;
    // Important: Settings must not crash when plan is missing.
    // If there is no plan yet, keep fields empty.
    if (plan == null) return;
    _gaController.text = plan.gaPlan.toString();
    _hvController.text = plan.hvPlan.toString();
    _devicesController.text = plan.devicePlan.toString();
    _shiftsController.text = plan.plannedWorkingShifts.toString();
    _baseSalaryController.text = plan.baseSalary.toString();
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

  void _updatePlan() async {
    if (_formKey.currentState!.validate()) {
      final gaPlan = int.tryParse(_gaController.text) ?? 0;
      final hvPlan = int.tryParse(_hvController.text) ?? 0;
      final devicePlan = int.tryParse(_devicesController.text) ?? 0;
      final shifts = int.tryParse(_shiftsController.text) ?? 0;
      final baseSalary = int.tryParse(_baseSalaryController.text) ?? 0;

      final provider = context.read<SalesProvider>();
      if (provider.currentPlan == null) {
        await provider.saveMonthlyPlan(
          gaPlan: gaPlan,
          hvPlan: hvPlan,
          devicePlan: devicePlan,
          plannedWorkingShifts: shifts,
          baseSalary: baseSalary,
        );
      } else {
        await provider.updateMonthlyPlan(
          gaPlan: gaPlan,
          hvPlan: hvPlan,
          devicePlan: devicePlan,
          plannedWorkingShifts: shifts,
          baseSalary: baseSalary,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('План успешно обновлен'),
            backgroundColor: LightModeColors.statusGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _resetMonth() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Сбросить текущий месяц?', style: context.textStyles.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Это удалит текущий план и все записи за этот месяц. Действие нельзя отменить.',
                style: context.textStyles.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => sheetContext.pop(),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        sheetContext.pop();
                        await context.read<SalesProvider>().resetCurrentMonth();
                      },
                      style: FilledButton.styleFrom(backgroundColor: LightModeColors.statusRed),
                      child: const Text('Сбросить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportReport() {
    final csv = context.read<SalesProvider>().buildCurrentMonthReportCsv();
    if (csv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Нет данных для экспорта'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Экспорт отчёта (CSV)', style: context.textStyles.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Скопируйте текст и отправьте в чат/почту, либо вставьте в Excel.',
                style: context.textStyles.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 240),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(csv, style: context.textStyles.bodySmall?.copyWith(height: 1.4)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: csv));
                    if (sheetContext.mounted) sheetContext.pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Отчёт скопирован в буфер обмена'),
                          backgroundColor: LightModeColors.statusGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_all_rounded, color: Colors.white),
                  label: Text(
                    'Скопировать',
                    style: context.textStyles.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Настройки',
                style: context.textStyles.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                provider.currentPlan == null ? 'Заполните план на текущий месяц' : 'Изменить план на текущий месяц',
                style: context.textStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInputField(
                      controller: _baseSalaryController,
                      label: 'Оклад (сум)',
                      icon: Icons.payments_rounded,
                      requiredField: false,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInputField(
                      controller: _gaController,
                      label: 'План GA',
                      icon: Icons.sim_card_rounded,
                      requiredField: false,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInputField(
                      controller: _hvController,
                      label: 'План HV',
                      icon: Icons.star_rounded,
                      requiredField: false,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInputField(
                      controller: _devicesController,
                      label: 'План по Девайсам',
                      icon: Icons.phone_iphone_rounded,
                      requiredField: false,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInputField(
                      controller: _shiftsController,
                      label: 'Запланировано смен',
                      icon: Icons.event_available_rounded,
                      requiredField: false,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _updatePlan,
                        child: Text(provider.currentPlan == null ? 'Сохранить план' : 'Обновить план'),
                      ),
                    ),
                  ],
                ),
              ),

              if (provider.currentPlan != null) ...[
                const SizedBox(height: AppSpacing.xl * 1.5),
                const Divider(),
                const SizedBox(height: AppSpacing.xl),
                Text('Отчёты', style: context.textStyles.titleMedium),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.ios_share_rounded, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Экспорт отчёта (CSV)'),
                  subtitle: const Text('Скопировать данные текущего месяца'),
                  onTap: _exportReport,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Опасная зона',
                  style: context.textStyles.titleMedium?.copyWith(color: LightModeColors.statusRed),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever_rounded, color: LightModeColors.statusRed),
                  title: const Text('Сбросить текущий месяц'),
                  subtitle: const Text('Удалить план и результаты за текущий месяц'),
                  onTap: _resetMonth,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: (value) {
        if (!requiredField && (value == null || value.isEmpty)) return null;
        if (value == null || value.isEmpty) return 'Обязательное поле';
        if (int.tryParse(value) == null) return 'Введите число';
        return null;
      },
    );
  }
}
