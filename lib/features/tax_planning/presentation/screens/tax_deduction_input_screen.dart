import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/db/models/tax_deduction_profile.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/features/tax_planning/data/tax_deduction_provider.dart';
import 'package:mudra_manager/features/tax_planning/data/tax_estimation_service.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class TaxDeductionInputScreen extends ConsumerStatefulWidget {
  const TaxDeductionInputScreen({super.key});

  @override
  ConsumerState<TaxDeductionInputScreen> createState() =>
      _TaxDeductionInputScreenState();
}

class _TaxDeductionInputScreenState
    extends ConsumerState<TaxDeductionInputScreen> {
  final _formKey = GlobalKey<FormState>();

  final _section80cController = TextEditingController();
  final _npsController = TextEditingController();
  final _employerNpsController = TextEditingController();
  final _hraController = TextEditingController();
  final _rentController = TextEditingController();
  final _homeLoanController = TextEditingController();
  final _medicalController = TextEditingController();

  bool _isLoading = true;
  TaxDeductionProfile? _existing;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final service = ref.read(taxDeductionServiceProvider);
    final fy = TaxEstimationService.currentFYStartYear();
    final profile = await service.getForFY(fy);

    if (profile != null) {
      _existing = profile;
      _section80cController.text = _formatValue(profile.section80cAmount);
      _npsController.text = _formatValue(profile.npsContribution);
      _employerNpsController.text = _formatValue(profile.employerNps);
      _hraController.text = _formatValue(profile.hraMonthly);
      _rentController.text = _formatValue(profile.rentPaid);
      _homeLoanController.text = _formatValue(profile.homeLoanInterest);
      _medicalController.text = _formatValue(profile.medicalPremium);
    }

    setState(() => _isLoading = false);
  }

  String _formatValue(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  void dispose() {
    _section80cController.dispose();
    _npsController.dispose();
    _employerNpsController.dispose();
    _hraController.dispose();
    _rentController.dispose();
    _homeLoanController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctxt = AppLocalizations.of(context)!;
    final spacing = ref.watch(spacingProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.tax_deductionProfile,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'save_deductions',
            label: ctxt.common_save,
            icon: LucideIcons.check,
            onTap: _save,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(spacing.cardInner),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: EdgeInsets.all(spacing.elementGap),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.06),
                        borderRadius: spacing.borderRadiusMedium,
                        border: Border.all(
                          color: color.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: spacing.iconSM,
                            color: color.primary,
                          ),
                          SizedBox(width: spacing.elementGap),
                          Expanded(
                            child: Text(
                              ctxt.tax_deductionInfo,
                              style: textTheme.bodySmall?.copyWith(
                                color: color.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.sectionGap),

                    // Section 80C
                    _buildField(
                      controller: _section80cController,
                      label: ctxt.tax_opp80c,
                      hint: ctxt.tax_deductionHintAnnual,
                      maxSanity: 1500000,
                      spacing: spacing,
                    ),

                    // NPS
                    _buildField(
                      controller: _npsController,
                      label: ctxt.tax_oppNps,
                      hint: ctxt.tax_deductionHintAnnual,
                      maxSanity: 500000,
                      spacing: spacing,
                    ),

                    // Employer NPS
                    _buildField(
                      controller: _employerNpsController,
                      label: ctxt.tax_deductionEmployerNps,
                      hint: ctxt.tax_deductionHintAnnual,
                      maxSanity: 1000000,
                      spacing: spacing,
                    ),

                    // HRA Monthly
                    _buildField(
                      controller: _hraController,
                      label: ctxt.tax_oppHra,
                      hint: ctxt.tax_deductionHintMonthly,
                      maxSanity: 500000,
                      spacing: spacing,
                    ),

                    // Rent Monthly
                    _buildField(
                      controller: _rentController,
                      label: ctxt.tax_deductionRent,
                      hint: ctxt.tax_deductionHintMonthly,
                      maxSanity: 500000,
                      spacing: spacing,
                    ),

                    // Home Loan Interest
                    _buildField(
                      controller: _homeLoanController,
                      label: ctxt.tax_oppHomeLoan,
                      hint: ctxt.tax_deductionHintAnnual,
                      maxSanity: 2000000,
                      spacing: spacing,
                    ),

                    // Medical Insurance
                    _buildField(
                      controller: _medicalController,
                      label: ctxt.tax_oppMedical,
                      hint: ctxt.tax_deductionHintAnnual,
                      maxSanity: 100000,
                      spacing: spacing,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required double maxSanity,
    required AppSpacing spacing,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sectionGap),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          prefixText: '₹ ',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return null; // optional
          final parsed = double.tryParse(value);
          if (parsed == null) return 'Invalid number';
          if (parsed < 0) return 'Cannot be negative';
          if (parsed > maxSanity) return 'Value seems too high';
          return null;
        },
      ),
    );
  }

  double? _parseField(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = _existing ?? TaxDeductionProfile();
    profile
      ..financialYear = TaxEstimationService.currentFYStartYear()
      ..section80cAmount = _parseField(_section80cController)
      ..npsContribution = _parseField(_npsController)
      ..employerNps = _parseField(_employerNpsController)
      ..hraMonthly = _parseField(_hraController)
      ..rentPaid = _parseField(_rentController)
      ..homeLoanInterest = _parseField(_homeLoanController)
      ..medicalPremium = _parseField(_medicalController);

    final service = ref.read(taxDeductionServiceProvider);
    await service.save(profile);

    if (mounted) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    }
  }
}
