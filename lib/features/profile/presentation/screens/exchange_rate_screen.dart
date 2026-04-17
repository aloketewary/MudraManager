import 'package:mudra_manager/core/utils/safe_date_format.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/currency/currency_meta.dart';
import 'package:mudra_manager/core/currency/currency_provider.dart';
import 'package:mudra_manager/core/currency/currency_service.dart';
import 'package:mudra_manager/core/db/models/exchange_rate.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';

final _ratesProvider = FutureProvider<List<ExchangeRate>>((ref) async {
  final service = await ref.watch(currencyServiceProvider.future);
  return service.getAllExchangeRates();
});

class ExchangeRateScreen extends ConsumerStatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  ConsumerState<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends ConsumerState<ExchangeRateScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ratesAsync = ref.watch(_ratesProvider);
    final base = BaseCurrency.code;
    final ctxt = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(ctxt.title_exchangeRates),
        elevation: 0,
      ),
      body: ratesAsync.when(
        data: (rates) {
          final entries = rates.where((r) {
            if (r.currencyCode == base) return false;
            if (_search.isEmpty) return true;
            final meta = kCurrencies[r.currencyCode];
            final q = _search.toLowerCase();
            return r.currencyCode.toLowerCase().contains(q) ||
                (meta?.name.toLowerCase().contains(q) ?? false);
          }).toList()
            ..sort((a, b) => a.currencyCode.compareTo(b.currencyCode));

          return Column(
            children: [
              // Info + Search
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.cardHorizontalMax,
                  vertical: spacing.cardVertical,
                ),
                child: Column(
                  children: [
                    Card(
                      elevation: 0,
                      color: color.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                        side: BorderSide(
                          color: color.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(spacing.cardInner),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.info,
                              size: 18,
                              color: color.primary,
                            ),
                            SizedBox(width: spacing.elementGap),
                            Expanded(
                              child: Text(
                                '1 ${ctxt.exchange_unitInfo(base)}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: color.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.elementGap),
                    TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: ctxt.exchange_search,
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        filled: true,
                        fillColor: color.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          borderSide: BorderSide(
                            color: color.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(spacing.radiusMedium),
                          borderSide:
                              BorderSide(color: color.primary, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: spacing.cardInner,
                          vertical: spacing.elementGap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Rate list
              Expanded(
                child: entries.isEmpty
                    ? Center(child: Text(BuddyMessages.noData))
                    : ListView.separated(
                        padding: EdgeInsets.only(
                          left: spacing.cardHorizontalMax,
                          right: spacing.cardHorizontalMax,
                          bottom: MediaQuery.of(context).padding.bottom +
                              kBottomNavigationBarHeight +
                              spacing.sectionGap,
                        ),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 56,
                          color: color.outlineVariant.withValues(alpha: 0.3),
                        ),
                        itemBuilder: (context, index) {
                          final r = entries[index];
                          final meta = kCurrencies[r.currencyCode];
                          return _RateTile(
                            code: r.currencyCode,
                            name: meta?.name ?? r.currencyCode,
                            symbol: meta?.symbol ?? r.currencyCode,
                            rate: r.rateToBase,
                            updatedAt: r.updatedAt,
                            base: base,
                            onSave: (newRate) => _updateRate(
                              r.currencyCode,
                              newRate,
                              ctxt,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => ListView(
          children: List.generate(6, (_) => const DashboardCardSkeleton()),
        ),
        error: (_, __) => Center(child: Text(BuddyMessages.genericError)),
      ),
    );
  }

  Future<void> _updateRate(
    String code,
    double newRate,
    AppLocalizations ctxt,
  ) async {
    final service = await ref.read(currencyServiceProvider.future);
    await service.updateRates({code: newRate});
    ref.invalidate(_ratesProvider);
    if (!context.mounted) return;
    SnackbarService.success(ctxt.exchange_rateUpdated(code));
  }
}

class _RateTile extends StatelessWidget {
  final String code;
  final String name;
  final String symbol;
  final double rate;
  final DateTime updatedAt;
  final String base;
  final ValueChanged<double> onSave;

  const _RateTile({
    required this.code,
    required this.name,
    required this.symbol,
    required this.rate,
    required this.updatedAt,
    required this.base,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = SpacingProvider.of(context);
    final ctxt = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => _showEditSheet(context, color, textTheme, spacing),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.elementGap * 1.5),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(spacing.radiusMedium),
              ),
              child: Text(
                symbol.length <= 2 ? symbol : code.substring(0, 1),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color.primary,
                ),
              ),
            ),
            SizedBox(width: spacing.elementGap * 1.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    name,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rate.toStringAsFixed(rate < 1 ? 6 : 2),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  safeDateFormat('dd MMM yy', ctxt.localeName).format(updatedAt),
                  style: textTheme.labelSmall?.copyWith(
                    color: color.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            SizedBox(width: spacing.elementGap),
            Icon(LucideIcons.pencil, size: 14, color: color.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    ColorScheme color,
    TextTheme textTheme,
    AppSpacing spacing,
  ) {
    final ctxt = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: rate.toStringAsFixed(rate < 1 ? 6 : 2),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(spacing.radiusLarge)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.sectionGap,
          spacing.sectionGap,
          spacing.sectionGap,
          spacing.sectionGap + MediaQuery.of(ctx).viewInsets.bottom,
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
            Text(
              ctxt.exchange_editRate(code),
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spacing.elementGap),
            Text(
              '1 $code = ? $base',
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                labelText: ctxt.exchange_rateLabel,
                prefixIcon: const Icon(LucideIcons.arrowLeftRight, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                ),
              ),
            ),
            SizedBox(height: spacing.sectionGap),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: spacing.elementGap * 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    child: Text(ctxt.common_cancel),
                  ),
                ),
                SizedBox(width: spacing.elementGap * 1.5),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final val = double.tryParse(controller.text);
                      if (val == null || val <= 0) {
                        SnackbarService.error(ctxt.exchange_invalidRate);
                        return;
                      }
                      onSave(val);
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: spacing.elementGap * 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(spacing.radiusMedium),
                      ),
                    ),
                    child: Text(ctxt.common_save),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.elementGap),
          ],
        ),
      ),
    );
  }
}

class SpacingProvider {
  static AppSpacing of(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    return container.read(spacingProvider);
  }
}
