import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/providers/isar_provider.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/currency_picker.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';
import 'package:mudra_manager/shared/widgets/settings_group_card.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';

class CurrencySettingsScreen extends ConsumerWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        title: ctxt.currency_title,
        appBarMode: AppBarMode.standard,
        enableRefresh: false,
      ),
      actions: ScreenActions.empty,
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final baseCurrencyAsync = ref.watch(baseCurrencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final ctxt = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 600 ? 600.0 : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: baseCurrencyAsync.when(
              data: (baseCurrency) {
                final meta = kCurrencies[baseCurrency];
                return AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  key: ValueKey(baseCurrency),
                  child: _buildContent(
                    context,
                    ref,
                    baseCurrency,
                    meta,
                    color,
                    textTheme,
                    spacing,
                    ctxt,
                    isDark,
                    reduceMotion,
                  ),
                );
              },
              loading: () => _buildLoading(spacing, color),
              error: (e, _) => _buildError(e, ctxt, color, textTheme, spacing),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    String baseCurrency,
    CurrencyMeta? meta,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
    bool isDark,
    bool reduceMotion,
  ) {
    return ListView(
      padding: EdgeInsets.only(
        left: spacing.cardHorizontal,
        right: spacing.cardHorizontal,
        top: spacing.cardVertical,
        bottom: 0,
      ),
      children: [
        // Hero card with animations
        CurrencyHeroCard(
          baseCurrency: baseCurrency,
          meta: meta,
          isDark: isDark,
          reduceMotion: reduceMotion,
        ),
        SizedBox(height: spacing.sectionGap),

        // Currency Info
        SectionHeader('Currency Settings'),
        SettingsGroupCard(
          items: [
            SettingItem(
              icon: LucideIcons.dollarSign,
              title: ctxt.currency_baseCurrency,
              subtitle: '$baseCurrency — ${meta?.name ?? ''}',
              onTap: () {},
              trailing: _CurrencyBadgeCompact(
                symbol: meta?.symbol ?? baseCurrency,
                color: color,
                textTheme: textTheme,
                spacing: spacing,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.elementGap * 2),

        // Actions
        SectionHeader('Actions'),
        SettingsGroupCard(
          items: [
            SettingItem(
              icon: LucideIcons.arrowLeftRight,
              title: BuddyMessages.currencyChangeTitle,
              subtitle: BuddyMessages.currencyChangeWarning,
              onTap: () => _showChangeDialog(
                context,
                ref,
                baseCurrency,
                color,
                textTheme,
                spacing,
              ),
              trailing: Icon(LucideIcons.chevronRight,
                  color: color.onSurfaceVariant, size: 18),
            ),
            SettingItem(
              icon: LucideIcons.percent,
              title: ctxt.currency_exchangeRates,
              subtitle: ctxt.currency_exchangeRatesDesc,
              onTap: () => context.push(AppRoutes.exchangeRates),
              trailing: Icon(LucideIcons.chevronRight,
                  color: color.onSurfaceVariant, size: 18),
            ),
            SettingItem(
              icon: LucideIcons.archive,
              title: BuddyMessages.archivedTransactionsTitle,
              subtitle: ctxt.currency_archivedDesc,
              onTap: () => context.push(AppRoutes.archivedTransactions),
              trailing: Icon(LucideIcons.chevronRight,
                  color: color.onSurfaceVariant, size: 18),
            ),
          ],
        ),
        SizedBox(height: spacing.elementGap * 2),

        // Warning
        WarningCard(
          color: color,
          textTheme: textTheme,
          spacing: spacing,
        ),
        SizedBox(height: spacing.sectionGap),

        const AmbientBrandSection(showSignature: true, absorbBottomInset: false),
      ],
    );
  }

  Widget _buildLoading(AppSpacing spacing, ColorScheme color) {
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.all(spacing.cardHorizontal),
      children: [
        _CurrencyHeroSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _SettingsGroupSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.elementGap * 2),
        _SettingsGroupSkeleton(spacing: spacing, color: color),
      ],
    );
  }

  Widget _buildError(
    Object e,
    AppLocalizations ctxt,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.cardHorizontalMax),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circleAlert,
                size: spacing.iconXL, color: color.error),
            SizedBox(height: spacing.elementGap),
            Text(
              BuddyMessages.errorWith('$e'),
              textAlign: TextAlign.center,
              style:
                  textTheme.bodyMedium?.copyWith(color: color.onSurfaceVariant),
            ),
            SizedBox(height: spacing.elementGap * 1.5),
            FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(ctxt.common_retry),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeDialog(
    BuildContext context,
    WidgetRef ref,
    String currentBase,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) async {
    final ctxt = AppLocalizations.of(context)!;
    final newCurrency =
        await showCurrencyPicker(context, spacing, selected: currentBase);
    if (newCurrency == null || newCurrency == currentBase) return;
    if (!context.mounted) return;

    final newMeta = kCurrencies[newCurrency];
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(spacing.radiusSmall)),
      ),
      builder: (ctx) => _CurrencyChangeConfirmSheet(
        currentBase: currentBase,
        newCurrency: newCurrency,
        currentSymbol: kCurrencies[currentBase]?.symbol ?? currentBase,
        newSymbol: newMeta?.symbol ?? newCurrency,
      ),
    );

    if (confirmed != true || !context.mounted) return;

    _showLoadingDialog(context, color, textTheme, spacing, ctxt);

    try {
      final currencyService = await ref.read(currencyServiceProvider.future);
      final archivedCount =
          await currencyService.changeBaseCurrency(newCurrency);
      BaseCurrency.sync(newCurrency);
      invalidateAfterCurrencyChange(ref);

      if (context.mounted) {
        Navigator.of(context).pop();
        SnackbarService.success(
          BuddyMessages.currencyArchivedCount(archivedCount, newCurrency),
          spacing,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        SnackbarService.error(BuddyMessages.genericError, spacing);
      }
    }
  }

  void _showLoadingDialog(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
    AppLocalizations ctxt,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: spacing.sectionGap * 2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(spacing.radiusMedium)),
            child: Padding(
              padding: EdgeInsets.all(spacing.sectionGap),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: color.primary),
                  SizedBox(height: spacing.sectionGap),
                  Text(
                    ctxt.currency_changingCurrency,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: spacing.elementGapMin),
                  Text(
                    ctxt.currency_pleaseWait,
                    style: textTheme.bodySmall
                        ?.copyWith(color: color.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero card with ambient glow and animations
class CurrencyHeroCard extends ConsumerWidget {
  final String baseCurrency;
  final CurrencyMeta? meta;
  final bool isDark;
  final bool reduceMotion;

  const CurrencyHeroCard({
    super.key,
    required this.baseCurrency,
    this.meta,
    required this.isDark,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return Semantics(
      label: 'Base currency: $baseCurrency, ${meta?.name}',
      child: AnimatedContainer(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.primary.withValues(alpha: isDark ? 0.2 : 0.12),
              color.primary.withValues(alpha: isDark ? 0.08 : 0.04),
            ],
          ),
          border: Border.all(color: color.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Symbol with ambient glow
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          color.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                    ),
                  ),
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(width: 60, height: 60),
                    ),
                  ),
                  Hero(
                    tag: 'currency_symbol_$baseCurrency',
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color.primary.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          meta?.symbol ?? baseCurrency,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.sectionGap),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700) ??
                    const TextStyle(fontWeight: FontWeight.w700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$baseCurrency — ${meta?.name ?? ''}',
                    ),
                    SizedBox(height: spacing.elementGapMin),
                    Text(
                      'Base currency',
                      style: textTheme.bodySmall
                          ?.copyWith(color: color.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact currency badge for settings items
class _CurrencyBadgeCompact extends StatelessWidget {
  final String symbol;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;

  const _CurrencyBadgeCompact({
    required this.symbol,
    required this.color,
    required this.textTheme,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.elementGap,
        vertical: spacing.elementGapUltraMin,
      ),
      decoration: BoxDecoration(
        color: color.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(spacing.radiusSmall),
        border: Border.all(color: color.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        symbol,
        style: textTheme.labelMedium?.copyWith(
          color: color.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Warning card with gradient background
class WarningCard extends StatelessWidget {
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;

  const WarningCard({
    super.key,
    required this.color,
    required this.textTheme,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Warning: Currency change will archive transactions',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          gradient: LinearGradient(
            colors: [
              color.error.withValues(alpha: 0.06),
              color.error.withValues(alpha: 0.02),
            ],
          ),
          border: Border.all(color: color.error.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(spacing.elementGapMin + 2),
              decoration: BoxDecoration(
                color: color.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(spacing.radiusSmall),
              ),
              child:
                  Icon(LucideIcons.triangleAlert, color: color.error, size: 16),
            ),
            SizedBox(width: spacing.elementGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BuddyMessages.currencyChangeTitle,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.onSurface,
                    ),
                  ),
                  SizedBox(height: spacing.elementGapUltraMin),
                  Text(
                    BuddyMessages.currencyChangeWarning,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for hero card
class _CurrencyHeroSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _CurrencyHeroSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.surfaceContainerLow,
      ),
      child: Row(
        children: [
          SkeletonLoader(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(28),
          ),
          SizedBox(width: spacing.sectionGap),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 120, height: 18),
                SizedBox(height: 8),
                SkeletonLoader(width: 80, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for settings group
class _SettingsGroupSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _SettingsGroupSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(spacing.radiusMedium + 4),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: List.generate(3, (index) {
          final isLast = index == 2;
          return Padding(
            padding: EdgeInsets.only(
              left: spacing.cardInner,
              right: spacing.cardInner,
              top: spacing.cardInner,
              bottom: isLast ? spacing.cardInner : spacing.elementGapMin,
            ),
            child: Row(
              children: [
                SkeletonLoader(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(spacing.radiusSmall),
                ),
                SizedBox(width: spacing.cardInner),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(width: 150, height: 16),
                      SizedBox(height: 6),
                      SkeletonLoader(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _CurrencyChangeConfirmSheet extends ConsumerWidget {
  final String currentBase;
  final String newCurrency;
  final String currentSymbol;
  final String newSymbol;

  const _CurrencyChangeConfirmSheet({
    required this.currentBase,
    required this.newCurrency,
    required this.currentSymbol,
    required this.newSymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.read<AppSpacing>(spacingProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.sectionGap,
        spacing.sectionGap,
        spacing.sectionGap,
        spacing.sectionGap + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: color.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: spacing.sectionGap),
          Icon(LucideIcons.triangleAlert, size: 40, color: color.error),
          SizedBox(height: spacing.sectionGap),
          Text(
            BuddyMessages.currencyChangeTitle,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: spacing.sectionGap),
          _buildCurrencySwap(color, textTheme, spacing),
          SizedBox(height: spacing.sectionGap),
          _buildWarningBlock(color, textTheme, spacing),
          SizedBox(height: spacing.sectionGap),
          _buildActions(context, color, spacing),
        ],
      ),
    );
  }

  Widget _buildCurrencySwap(
      ColorScheme color, TextTheme textTheme, AppSpacing spacing) {
    return Hero(
      tag: 'currency_swap',
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: spacing.cardInner, vertical: spacing.elementGap),
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CurrencyBadge(
                code: currentBase,
                symbol: currentSymbol,
                color: color,
                textTheme: textTheme,
                spacing: spacing),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.elementGap),
              child: Icon(LucideIcons.arrowRight, size: 20, color: color.error),
            ),
            _CurrencyBadge(
                code: newCurrency,
                symbol: newSymbol,
                color: color,
                textTheme: textTheme,
                spacing: spacing),
          ],
        ),
      ),
    );
  }

  Widget _CurrencyBadge({
    required String code,
    required String symbol,
    required ColorScheme color,
    required TextTheme textTheme,
    required AppSpacing spacing,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            symbol,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: color.primary,
            ),
          ),
        ),
        SizedBox(height: spacing.elementGapMin),
        Text(code,
            style:
                textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildWarningBlock(
      ColorScheme color, TextTheme textTheme, AppSpacing spacing) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        color: color.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        border: Border.all(color: color.error.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WarningRow(
              BuddyMessages.currencyChangeWarning, color, textTheme, spacing),
          SizedBox(height: spacing.elementGap),
          Text(
            BuddyMessages.currencyChangeIrreversible,
            style: textTheme.labelSmall?.copyWith(
              color: color.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
      BuildContext context, ColorScheme color, AppSpacing spacing) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.pop(false),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: spacing.elementGap * 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium)),
            ),
            child: Text(BuddyMessages.currencyChangeCancel),
          ),
        ),
        SizedBox(width: spacing.elementGap),
        Expanded(
          child: FilledButton(
            onPressed: () => context.pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: color.error,
              padding: EdgeInsets.symmetric(vertical: spacing.elementGap * 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium)),
            ),
            child: Text(BuddyMessages.currencyChangeConfirm,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _WarningRow extends StatelessWidget {
  final String text;
  final ColorScheme color;
  final TextTheme textTheme;
  final AppSpacing spacing;

  const _WarningRow(this.text, this.color, this.textTheme, this.spacing);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: spacing.elementGapUltraMin),
          child: Icon(LucideIcons.dot, size: 16, color: color.error),
        ),
        SizedBox(width: spacing.elementGapMin),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall
                ?.copyWith(color: color.onSurfaceVariant, height: 1.4),
          ),
        ),
      ],
    );
  }
}
