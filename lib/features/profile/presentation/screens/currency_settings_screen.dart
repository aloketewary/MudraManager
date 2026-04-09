import 'package:mudra_manager/core/l10n/app_localizations.dart';
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
import 'package:mudra_manager/shared/widgets/currency_picker.dart';

class CurrencySettingsScreen extends ConsumerWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final baseCurrencyAsync = ref.watch(baseCurrencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(ctxt.currency_title)),
      body: baseCurrencyAsync.when(
        data: (baseCurrency) {
          final meta = kCurrencies[baseCurrency];
          return ListView(
            padding: EdgeInsets.only(
              left: spacing.cardHorizontal,
              right: spacing.cardHorizontal,
              top: spacing.cardVertical,
              bottom: MediaQuery.of(context).padding.bottom +
                  kBottomNavigationBarHeight +
                  spacing.sectionGap,
            ),
            children: [
              // Hero card
              Container(
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
                  border: Border.all(
                    color: color.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(spacing.cardInner),
                      decoration: BoxDecoration(
                        color: color.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        meta?.symbol ?? baseCurrency,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.sectionGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctxt.currency_baseCurrency,
                            style: textTheme.labelMedium?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '$baseCurrency — ${meta?.name ?? ''}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: spacing.elementGapMin),
                          Text(
                            ctxt.currency_baseDescription,
                            style: textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing.sectionGap),

              // Change button
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: color.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  side: BorderSide(
                    color: color.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  onTap: () => _showChangeDialog(
                    context,
                    ref,
                    baseCurrency,
                    color,
                    textTheme,
                    spacing,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardInner,
                      vertical: spacing.elementGap * 1.5,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacing.elementGap),
                          decoration: BoxDecoration(
                            color: color.error.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                          ),
                          child: Icon(
                            LucideIcons.arrowLeftRight,
                            color: color.error,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: spacing.elementGap * 1.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                BuddyMessages.currencyChangeTitle,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                BuddyMessages.currencyChangeWarning,
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.error,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          color: color.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing.elementGap),

              // Manage exchange rates
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: color.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  side: BorderSide(
                    color: color.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  onTap: () => context.push(AppRoutes.exchangeRates),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardInner,
                      vertical: spacing.elementGap * 1.5,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacing.elementGap),
                          decoration: BoxDecoration(
                            color: color.tertiary.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                          ),
                          child: Icon(
                            LucideIcons.arrowLeftRight,
                            color: color.tertiary,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: spacing.elementGap * 1.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ctxt.currency_exchangeRates,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                ctxt.currency_exchangeRatesDesc,
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          color: color.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing.elementGap),

              // View archived
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: color.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  side: BorderSide(
                    color: color.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  onTap: () => context.push(AppRoutes.archivedTransactions),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.cardInner,
                      vertical: spacing.elementGap * 1.5,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacing.elementGap),
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(spacing.radiusMedium),
                          ),
                          child: Icon(
                            LucideIcons.archive,
                            color: color.primary,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: spacing.elementGap * 1.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                BuddyMessages.archivedTransactionsTitle,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                ctxt.currency_archivedDesc,
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          color: color.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing.sectionGap),

              // Warning info
              Container(
                padding: EdgeInsets.all(spacing.cardInner),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  color: color.error.withValues(alpha: 0.06),
                  border: Border.all(
                    color: color.error.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.triangleAlert,
                      color: color.error,
                      size: 18,
                    ),
                    SizedBox(width: spacing.elementGap),
                    Expanded(
                      child: Text(
                        BuddyMessages.currencyChangeWarning,
                        style: textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: DashboardCardSkeleton(),
        ),
        error: (e, _) => Center(child: Text(ctxt.common_errorLoading)),
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
        await showCurrencyPicker(context, selected: currentBase);
    if (newCurrency == null || newCurrency == currentBase) return;
    if (!context.mounted) return;

    final newMeta = kCurrencies[newCurrency];
    final oldMeta = kCurrencies[currentBase];

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(spacing.radiusLarge)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.sectionGap,
          spacing.sectionGap,
          spacing.sectionGap,
          spacing.sectionGap + MediaQuery.of(ctx).padding.bottom,
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
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            // From → To visual
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardInner,
                vertical: spacing.elementGap,
              ),
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _currencyBadge(
                    currentBase,
                    oldMeta?.symbol ?? currentBase,
                    color,
                    textTheme,
                    spacing,
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: spacing.elementGap),
                    child: Icon(
                      LucideIcons.arrowRight,
                      size: 20,
                      color: color.error,
                    ),
                  ),
                  _currencyBadge(
                    newCurrency,
                    newMeta?.symbol ?? newCurrency,
                    color,
                    textTheme,
                    spacing,
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            // Warning bullets
            Container(
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
                  _warningRow(
                    BuddyMessages.currencyChangeWarning,
                    color,
                    textTheme,
                    spacing,
                  ),
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
            ),
            SizedBox(height: spacing.sectionGap),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ctx.pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: spacing.elementGap * 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    child: Text(BuddyMessages.currencyChangeCancel),
                  ),
                ),
                SizedBox(width: spacing.elementGap),
                Expanded(
                  child: FilledButton(
                    onPressed: () => ctx.pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: color.error,
                      padding: EdgeInsets.symmetric(
                        vertical: spacing.elementGap * 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    child: Text(
                      BuddyMessages.currencyChangeConfirm,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show blocking loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: spacing.sectionGap * 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacing.radiusMedium)),
            child: Padding(
              padding: EdgeInsets.all(spacing.sectionGap),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: color.primary),
                  SizedBox(height: spacing.sectionGap),
                  Text(
                    ctxt.currency_changingCurrency,
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: spacing.elementGapMin),
                  Text(
                    ctxt.currency_pleaseWait,
                    style: textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final currencyService = await ref.read(currencyServiceProvider.future);
      final archivedCount = await currencyService.changeBaseCurrency(newCurrency);

      BaseCurrency.sync(newCurrency);
      invalidateAll(ref);

      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        SnackbarService.success(
          BuddyMessages.currencyArchivedCount(archivedCount, newCurrency),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        SnackbarService.error(BuddyMessages.genericError);
      }
    }
  }

  Widget _currencyBadge(
    String code,
    String symbol,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
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
        Text(
          code,
          style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _warningRow(
    String text,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
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
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
