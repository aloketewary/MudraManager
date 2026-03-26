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

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  String _selectedPlan = EntitlementProducts.yearlyPlan;
  bool _purchasing = false;
  late final BillingService _billing;

  @override
  void initState() {
    super.initState();
    _billing = ref.read(billingServiceProvider);
    _billing.onPurchaseUpdate = _onPurchaseUpdate;
  }

  @override
  void dispose() {
    _billing.onPurchaseUpdate = null;
    super.dispose();
  }

  void _onPurchaseUpdate(PurchaseStatus status, String? error) {
    if (!mounted) return;

    setState(() => _purchasing = false);

    switch (status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Invalidate pro status so all watchers refresh
        ref.invalidate(isProProvider);
        SnackbarService.success('Welcome to Mudra Manager Pro! 🎉');
        if (mounted) context.pop();
        break;
      case PurchaseStatus.error:
        SnackbarService.error(error ?? 'Purchase failed. Please try again.');
        break;
      case PurchaseStatus.canceled:
        // Silent — user cancelled intentionally
        break;
      case PurchaseStatus.pending:
        SnackbarService.info(
          'Purchase pending. Pro will activate once payment completes.',
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProAsync = ref.watch(isProProvider);
    final billing = ref.watch(billingServiceProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.pop();
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHero(color, textTheme, isDark),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.cardHorizontal,
              vertical: spacing.cardVertical,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...isProAsync.when(
                  data: (isPro) => isPro
                      ? _buildProStatusContent(color, textTheme, spacing)
                      : _buildFreeUserContent(
                          color,
                          textTheme,
                          spacing,
                          billing,
                        ),
                  loading: () =>
                      [const Center(child: CircularProgressIndicator())],
                  error: (_, __) =>
                      _buildFreeUserContent(color, textTheme, spacing, billing),
                ),
                const SizedBox(height: 80),
              ]),
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
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF4CAF50),
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
      _buildSectionLabel('Your Pro features', color, textTheme),
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
                'To manage your subscription, go to Google Play Store → Subscriptions.',
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
      _buildSectionLabel('Everything in Pro', color, textTheme),
      const SizedBox(height: 12),
      _buildFeaturesList(color, textTheme, spacing),
      const SizedBox(height: 28),

      _buildSectionLabel('Choose your plan', color, textTheme),
      const SizedBox(height: 12),
      _buildPlanCard(
        id: EntitlementProducts.yearlyPlan, // was yearlySubscription
        label: 'Yearly',
        fallbackPrice: '₹299/year',
        savings: 'Save 47%',
        billing: billing,
        color: color,
        textTheme: textTheme,
        spacing: spacing,
      ),
      const SizedBox(height: 10),
      _buildPlanCard(
        id: EntitlementProducts.monthlyPlan,
        label: 'Monthly',
        fallbackPrice: '₹49/month',
        billing: billing,
        color: color,
        textTheme: textTheme,
        spacing: spacing,
      ),
      const SizedBox(height: 10),
      _buildPlanCard(
        id: EntitlementProducts.lifetime,
        label: 'Lifetime',
        fallbackPrice: '₹999 once',
        savings: 'Best value',
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
                      'Continue',
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
            'Restore purchases',
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
    if (info.plan == ProPlan.lifetime) {
      return 'Lifetime access — forever yours ❤️';
    }

    if (info.expiresAt != null) {
      final days = info.expiresAt!.difference(DateTime.now()).inDays;
      if (days < 0) return 'Expired';
      if (days == 0) return 'Renews today';
      if (days == 1) return 'Renews tomorrow';
      return 'Renews in $days days';
    }

    return 'Active subscription';
  }

  // ── HERO ──
  Widget _buildHero(ColorScheme color, TextTheme textTheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primary.withValues(alpha: isDark ? 0.25 : 0.15),
            color.tertiary.withValues(alpha: isDark ? 0.12 : 0.06),
            color.surface,
          ],
        ),
      ),
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
              'Mudra Manager Pro',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Unlock the full power of your finances',
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
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '🎁 ${info.trialDaysRemaining} days of full access remaining',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF10B981),
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
    required BillingService billing,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    final isSelected = _selectedPlan == id;
    // Use Google Play price if loaded, otherwise fallback
    final displayPrice = (id == EntitlementProducts.monthlyPlan ||
            id == EntitlementProducts.yearlyPlan)
        ? fallbackPrice
        : (billing.getPrice(id) ?? fallbackPrice);

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
      SnackbarService.error('Google Play is not available on this device.');
      return;
    }

    setState(() => _purchasing = true);

    final isLifetime = _selectedPlan == EntitlementProducts.lifetime;
    final productId = isLifetime
        ? EntitlementProducts.lifetime
        : EntitlementProducts.subscription;

    // Tell billing which base plan was selected (for subscription)
    if (!isLifetime) {
      billing.setSelectedBasePlan(_selectedPlan);
    }

    final started = await billing.buy(productId);
    if (!started && mounted) {
      setState(() => _purchasing = false);
      SnackbarService.error('Could not start purchase. Please try again.');
    }
  }

  Future<void> _handleRestore() async {
    HapticFeedback.mediumImpact();
    final billing = ref.read(billingServiceProvider);

    if (!billing.isAvailable) {
      SnackbarService.error('Google Play is not available on this device.');
      return;
    }

    setState(() => _purchasing = true);
    await billing.restorePurchases();

    // Give the stream a moment to deliver restored purchases
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _purchasing = false);
      final isPro = await ref.read(isProProvider.future);
      if (isPro) {
        SnackbarService.success('Purchases restored! Welcome back 🎉');
        if (mounted) context.pop();
      } else {
        SnackbarService.info('No previous purchases found.');
      }
    }
  }
}
