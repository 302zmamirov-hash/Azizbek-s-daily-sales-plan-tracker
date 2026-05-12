import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:daily_sales_plan_tracker/providers/sales_provider.dart';
import 'package:daily_sales_plan_tracker/theme.dart';

class DailyEntryScreen extends StatefulWidget {
  const DailyEntryScreen({super.key});

  @override
  State<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends State<DailyEntryScreen> {
  DateTime _selectedDate = DateTime.now();
  
  final _formKey = GlobalKey<FormState>();
  final _gaController = TextEditingController();
  final _hvController = TextEditingController();
  final _devicesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForDate();
    });
  }

  void _loadDataForDate() {
    final provider = context.read<SalesProvider>();
    final result = provider.getResultForDate(_selectedDate);
    
    if (result != null) {
      _gaController.text = result.gaFact.toString();
      _hvController.text = result.hvFact.toString();
      _devicesController.text = result.deviceFact.toString();
    } else {
      _gaController.text = '';
      _hvController.text = '';
      _devicesController.text = '';
    }
  }

  @override
  void dispose() {
    _gaController.dispose();
    _hvController.dispose();
    _devicesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year, DateTime.now().month, 1), // Only current month
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDataForDate();
    }
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      final gaFact = int.tryParse(_gaController.text) ?? 0;
      final hvFact = int.tryParse(_hvController.text) ?? 0;
      final deviceFact = int.tryParse(_devicesController.text) ?? 0;

      await context.read<SalesProvider>().saveDailyResult(
        date: _selectedDate,
        gaFact: gaFact,
        hvFact: hvFact,
        deviceFact: deviceFact,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Результаты успешно сохранены'),
            backgroundColor: LightModeColors.statusGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    if (provider.currentPlan == null) {
      return const Scaffold(
        body: Center(child: Text('Сначала создайте план на месяц на дашборде.')),
      );
    }

    final dateString = DateFormat('d MMMM yyyy', 'ru').format(_selectedDate);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Запись результатов',
                  style: context.textStyles.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Date Selector
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              dateString,
                              style: context.textStyles.titleMedium,
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Оставьте поля пустыми (или 0), если это выходной день.',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Inputs
                _buildInputCard(
                  title: 'GA (Gross Activations)',
                  controller: _gaController,
                  icon: Icons.sim_card_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                
                _buildInputCard(
                  title: 'HV (High Value)',
                  controller: _hvController,
                  icon: Icons.star_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(height: AppSpacing.md),
                
                _buildInputCard(
                  title: 'Девайсы',
                  controller: _devicesController,
                  icon: Icons.phone_iphone_rounded,
                  color: Colors.purple,
                ),
                const SizedBox(height: AppSpacing.xl * 1.5),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _saveData,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: Text(
                      'Сохранить результаты',
                      style: context.textStyles.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: context.textStyles.headlineSmall,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                return 'Введите число';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
