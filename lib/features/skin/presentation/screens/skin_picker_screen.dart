import 'package:mudra_manager/core/tone/tone_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_provider.dart';
import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/core/router/app_routes.dart';
import 'package:mudra_manager/core/skin/model/skin.dart';
import 'package:mudra_manager/core/skin/provider/skin_provider.dart';
import 'package:mudra_manager/core/utils/snackbar_service.dart';
import 'package:mudra_manager/features/skin/presentation/widgets/skin_preview_card.dart';
import 'package:mudra_manager/shared/widgets/responsive_helper.dart';

class SkinPickerScreen extends ConsumerStatefulWidget {
  const SkinPickerScreen({super.key});

  @override
  ConsumerState<SkinPickerScreen> createState() => _SkinPickerScreenState();
}

class _SkinPickerScreenState extends ConsumerState<SkinPickerScreen> {
  String? _tempSelectedId;

  @override
  void initState() {
    super.initState();
    final current = ref.read(activeSkinProvider).value;
    _tempSelectedId = current?.id ?? 'finance';
  }

  void _applySkin() {
    if (_tempSelectedId == null) return;
    ref.read(activeSkinProvider.notifier).setSkin(_tempSelectedId!);
    SnackbarService.success(
      AppLocalizations.of(context)?.theme_themeAppliedMessage ??
          'Skin applied!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final ctxt = AppLocalizations.of(context)!;
    final isPro = ref.watch(hasFullAccessProvider).value ?? false;
    final catalog = ref.watch(skinCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ctxt.theme_chooseThemeTitle),
        actions: [
          // Customize button for active skin
          IconButton(
            onPressed: () => context.push(AppRoutes.skinEditor),
            icon: const Icon(LucideIcons.slidersHorizontal),
            tooltip: 'Customize',
          ),
        ],
      ),
      body: catalog.when(
        data: (skins) => _buildBody(skins, isPro, color, textTheme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _applySkin,
        icon: const Icon(LucideIcons.circleCheck),
        label: Text(ctxt.theme_applyThemeLabel),
      ),
    );
  }

  Widget _buildBody(
    List<Skin> skins,
    bool isPro,
    ColorScheme color,
    TextTheme textTheme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Skins', color, textTheme),
        const SizedBox(height: 12),
        _buildSkinGrid(skins, isPro: true, color: color, textTheme: textTheme),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    ColorScheme color,
    TextTheme textTheme, {
    bool showProBadge = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.primary,
              letterSpacing: 0.5,
            ),
          ),
          if (showProBadge) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.primary, color.tertiary],
                ),
                borderRadius: BorderRadius.circular(Tone.current.borderRadius * 0.5),
              ),
              child: Text(
                'PRO',
                style: textTheme.labelSmall?.copyWith(
                  color: color.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkinGrid(
    List<Skin> skins, {
    required bool isPro,
    required ColorScheme color,
    required TextTheme textTheme,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: ResponsiveHelper.getGridAspectRatio(
          context,
          defaultRatio: 0.70,
          singleColumnRatio: 1.2,
        ),
      ),
      itemCount: skins.length,
      itemBuilder: (context, index) {
        final skin = skins[index];
        final isSelected = _tempSelectedId == skin.id;
        final isLocked = skin.tier == SkinTier.pro && !isPro;

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Opacity(
                    opacity: isLocked ? 0.55 : 1.0,
                    child: SkinPreviewCard(
                      skin: skin,
                      isSelected: isSelected,
                      onTap: () {
                        if (isLocked) {
                          HapticFeedback.mediumImpact();
                          context.push(AppRoutes.upgrade);
                          return;
                        }
                        setState(() => _tempSelectedId = skin.id);
                      },
                    ),
                  ),
                  if (isLocked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.surface.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          size: 14,
                          color: color.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              skin.name,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? color.primary
                    : isLocked
                        ? color.onSurfaceVariant.withValues(alpha: 0.5)
                        : color.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              skin.meta.description,
              style: textTheme.labelSmall?.copyWith(
                color: color.onSurfaceVariant.withValues(
                  alpha: isLocked ? 0.4 : 0.7,
                ),
                fontSize: 10,
              ),
            ),
          ],
        );
      },
    );
  }
}
