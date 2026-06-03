import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/billing_provider.dart';
import 'package:mudra_manager/core/entitlement/billing_service.dart';
import 'package:mudra_manager/core/entitlement/entitlement_products.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  String _selectedPlan = EntitlementProducts.yearlyPlan;
  bool _purchasing = false;
  late final BillingService _billing;
  final _confettiController =
      ConfettiController(duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _billing = ref.read(billingServiceProvider);
    _billing.onPurchaseUpdate = _onPurchaseUpdate;
  }

  @override
  void dispose() {
    _billing.onPurchaseUpdate = null;
    _confettiController.dispose();
    super.dispose();
  }

  void _onPurchaseUpdate(PurchaseStatus status, String? error) {
    if (!mounted) return;
    setState(() => _purchasing = false);

    switch (status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        invalidateEntitlements(ref);
        _confettiController.play();
        _showSuccessSheet();
        break;
      case PurchaseStatus.error:
        SnackbarService.error(
          error ?? AppLocalizations.of(context)!.upgrade_purchaseFailed,
        );
        break;
      case PurchaseStatus.canceled:
        break;
      case PurchaseStatus.pending:
        SnackbarService.info(
          AppLocalizations.of(context)!.upgrade_purchasePending,
        );
        break;
    }
  }

  void _showSuccessSheet() {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.primary.withValues(alpha: 0.15),
                    color.tertiary.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Icon(LucideIcons.crown, size: 48, color: color.primary),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.upgrade_welcomePro,
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.upgrade_allFeaturesUnlocked,
              style:
                  textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ctx.pop();
                  context.pop(); // close upgrade screen
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.upgrade_startExploring,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProAsync = ref.watch(isProProvider);
    final billing = ref.watch(billingServiceProvider);

    return ScreenShell(
      config: const ScreenShellConfig(
        appBarMode: AppBarMode.minimal,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      leading: IconButton(
        icon: const Icon(LucideIcons.x),
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.pop();
        },
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            children: [
              _buildHero(color, textTheme, isDark),
              SizedBox(height: spacing.sectionGap),
              ...isProAsync.when(
                data: (isPro) => isPro
                    ? _buildProStatusContent(color, textTheme, spacing)
                    : _buildFreeUserContent(color, textTheme, spacing, billing),
                loading: () => [const DashboardCardSkeleton()],
                error: (_, __) =>
                    _buildFreeUserContent(color, textTheme, spacing, billing),
              ),
              const SizedBox(height: 80),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              gravity: 0.2,
              colors: [
                color.primary,
                color.tertiary,
                color.tertiary,
                color.primary,
                color.error,
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProStatusContent(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final planAsync = ref.watch(proPlanInfoProvider);
    const gold = Color(0xFFD4AF37);

    return [
      // Status card
      planAsync.when(
        data: (info) => Container(
          padding: EdgeInsets.all(spacing.cardInner),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(spacing.radiusMedium),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gold.withValues(alpha: 0.12),
                gold.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.crown, color: gold, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              info.label,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: textTheme.labelSmall?.copyWith(
                                  color: color.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _proStatusSubtitle(info),
                          style: textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      const SizedBox(height: 28),

      // Features list (still show — reinforces value)
      _buildSectionLabel(
        AppLocalizations.of(context)!.upgrade_yourProFeatures,
        color,
        textTheme,
      ),
      const SizedBox(height: 12),
      _buildFeaturesList(color, textTheme, spacing),
      const SizedBox(height: 28),

      // Manage subscription hint
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          color: color.primary.withValues(alpha: 0.06),
          border: Border.all(
            color: color.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.info, color: color.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.upgrade_manageSubscription,
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildFreeUserContent(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    BillingService billing,
  ) {
    return [
      const SizedBox(height: 8),
      _buildSectionLabel(
        AppLocalizations.of(context)!.upgrade_everythingInPro,
        color,
        textTheme,
      ),
      const SizedBox(height: 12),
      _buildFeaturesList(color, textTheme, spacing),
      const SizedBox(height: 28),

      _buildSectionLabel(
        AppLocalizations.of(context)!.upgrade_chooseYourPlan,
        color,
        textTheme,
      ),
      const SizedBox(height: 12),
      _buildPlanCard(
        id: EntitlementProducts.yearlyPlan,
        label: AppLocalizations.of(context)!.upgrade_yearly,
        fallbackPrice: '\u20b9199/year',
        savings: AppLocalizations.of(context)!.upgrade_save43,
        perMonth: '\u20b916.6/mo',
        billing: billing,
        color: color,
        textTheme: textTheme,
        spacing: spacing,
      ),
      const SizedBox(height: 10),
      _buildPlanCard(
        id: EntitlementProducts.monthlyPlan,
        label: AppLocalizations.of(context)!.upgrade_monthly,
        fallbackPrice: '\u20b929/month',
        billing: billing,
        color: color,
        textTheme: textTheme,
        spacing: spacing,
      ),

      const SizedBox(height: 28),

      // CTA
      SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: _purchasing ? null : _handlePurchase,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.radiusLarge),
            ),
          ),
          child: _purchasing
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: color.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.sparkles, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.upgrade_continue,
                      style: textTheme.titleMedium?.copyWith(
                        color: color.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
      const SizedBox(height: 12),

      // Restore
      Center(
        child: TextButton(
          onPressed: _purchasing ? null : _handleRestore,
          child: Text(
            AppLocalizations.of(context)!.upgrade_restorePurchases,
            style: textTheme.bodyMedium?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),

      // Legal
      Text(
        'Payment is charged to your Google Play account. '
        'Subscriptions auto-renew unless cancelled at least '
        '24 hours before the end of the current period.',
        style: textTheme.bodySmall?.copyWith(
          color: color.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 11,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }

  String _proStatusSubtitle(ProPlanInfo info) {
    if (info.expiresAt != null) {
      final days = info.expiresAt!.difference(DateTime.now()).inDays;
      if (days < 0) return 'Expired — tap to renew';
      if (days == 0) return 'Renews today';
      if (days == 1) return 'Renews tomorrow';
      return 'Renews in $days days';
    }
    return 'Active subscription';
  }

  // ── HERO ──
  Widget _buildHero(ColorScheme color, TextTheme textTheme, bool isDark) {
    return Container(
      decoration: const BoxDecoration(),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.primary.withValues(alpha: 0.25),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.primary.withValues(
                      alpha: isDark ? 0.15 : 0.1,
                    ),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.primary.withValues(alpha: isDark ? 0.2 : 0.14),
                      color.tertiary.withValues(alpha: isDark ? 0.08 : 0.05),
                    ],
                  ),
                ),
                child: Icon(
                  LucideIcons.crown,
                  size: 48,
                  color: color.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.upgrade_mudraManagerPro,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.upgrade_unlockFullPower,
              style: textTheme.bodyLarge?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            // After the existing subtitle Text widget:
            Consumer(
              builder: (context, ref, _) {
                final planAsync = ref.watch(proPlanInfoProvider);
                return planAsync.maybeWhen(
                  data: (info) =>
                      info.isTrial && (info.trialDaysRemaining ?? 0) > 0
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '🎁 ${info.trialDaysRemaining} days of full access remaining',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: color.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
    String text,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: color.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFeaturesList(
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    const features = [
      (LucideIcons.wallet, 'Unlimited accounts, budgets & goals'),
      (LucideIcons.plane, 'Unlimited active trips'),
      (LucideIcons.chartBar, 'Advanced analytics & financial health'),
      (LucideIcons.brain, 'Spending personality insights'),
      (LucideIcons.trendingUp, 'Net worth tracking'),
      (LucideIcons.fileText, 'Monthly recap reports'),
      (LucideIcons.layoutDashboard, 'Dashboard customization'),
      (LucideIcons.cloudUpload, 'Cloud backup & restore'),
      (LucideIcons.puzzle, 'Premium plugins & category packs'),
      (LucideIcons.palette, 'All themes & personalization'),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        side: BorderSide(
          color: color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.cardInner),
        child: Column(
          children: features.asMap().entries.map((entry) {
            final (icon, label) = entry.value;
            final isLast = entry.key == features.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: color.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(LucideIcons.check, size: 16, color: color.primary),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: color.outlineVariant.withValues(alpha: 0.3),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── PLAN CARD (uses real prices when available) ──
  Widget _buildPlanCard({
    required String id,
    required String label,
    required String fallbackPrice,
    String? savings,
    String? perMonth,
    required BillingService billing,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    final isSelected = _selectedPlan == id;
    // Use Google Play price if loaded, otherwise fallback
    final playPrice = billing.getPrice(id);
    final displayPrice = playPrice ?? fallbackPrice;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedPlan = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          color: isSelected
              ? color.primaryContainer.withValues(alpha: 0.4)
              : color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          border: Border.all(
            color: isSelected
                ? color.primary
                : color.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color.primary : color.outlineVariant,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(LucideIcons.check, size: 14, color: color.onPrimary)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayPrice,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  if (perMonth != null)
                    Text(
                      perMonth,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            if (savings != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.primary, color.tertiary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  savings,
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── ACTIONS ──
  Future<void> _handlePurchase() async {
    HapticFeedback.mediumImpact();
    final billing = ref.read(billingServiceProvider);

    if (!billing.isAvailable) {
      SnackbarService.error(BuddyMessages.playNotAvailable);
      return;
    }

    setState(() => _purchasing = true);
    billing.setSelectedBasePlan(_selectedPlan);

    final started = await billing.buy(EntitlementProducts.subscription);
    if (!started && mounted) {
      setState(() => _purchasing = false);
      SnackbarService.error(BuddyMessages.purchaseFailed);
    }
  }

  Future<void> _handleRestore() async {
    HapticFeedback.mediumImpact();
    final billing = ref.read(billingServiceProvider);

    if (!billing.isAvailable) {
      SnackbarService.error(BuddyMessages.playNotAvailable);
      return;
    }

    setState(() => _purchasing = true);
    await billing.restorePurchases();
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _purchasing = false);
      invalidateEntitlements(ref);
      final isPro = await ref.read(isProProvider.future);
      if (isPro) {
        _confettiController.play();
        _showSuccessSheet();
      } else {
        SnackbarService.info(BuddyMessages.genericError);
      }
    }
  }
}
