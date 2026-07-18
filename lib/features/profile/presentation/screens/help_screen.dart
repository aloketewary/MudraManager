import 'package:mudra_manager/core/l10n/app_localizations.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/utils/buddy_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/providers/spacing_provider.dart';
import 'package:mudra_manager/core/utils/icon_helper.dart';
import 'package:mudra_manager/features/profile/data/help_item.dart';
import 'package:mudra_manager/features/profile/data/help_service.dart';
import 'package:mudra_manager/core/state/app_screen_state.dart';
import 'package:mudra_manager/shared/templates/screen_shell.dart';
import 'package:mudra_manager/shared/widgets/ambient_brand_section.dart';
import 'package:mudra_manager/shared/widgets/section_header.dart';
import 'package:mudra_manager/shared/widgets/settings_group_card.dart';
import 'package:mudra_manager/shared/widgets/setting_item.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  List<HelpItem> _items = [];
  List<HelpItem> _filteredItems = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  bool _isSearching = false;
  AppLocalizations get ctxt => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadHelp();
  }

  Future<void> _loadHelp() async {
    final items = await HelpService.loadHelpContent();
    if (!mounted) return;
    setState(() {
      _items = items;
      _filteredItems = items;
      _isLoading = false;
    });
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _items;
      } else {
        final q = query.toLowerCase();
        _filteredItems = _items.where((item) {
          return item.title.toLowerCase().contains(q) ||
              item.shortDescription.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctxt = AppLocalizations.of(context)!;

    return ScreenShell(
      config: ScreenShellConfig(
        title: _isSearching ? null : ctxt.help_title,
        appBarMode: _isSearching ? AppBarMode.search : AppBarMode.standard,
        enableRefresh: false,
      ),
      onSearch: _isSearching ? _search : null,
      searchHint: ctxt.help_searchHint,
      actions: ScreenActions.build(
        appBar: [
          ScreenAction(
            id: 'toggle_search',
            label: _isSearching ? 'Close' : 'Search',
            icon: _isSearching ? LucideIcons.x : LucideIcons.search,
            onTap: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _search('');
                }
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 600 ? 600.0 : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                key: ValueKey(_isLoading),
                child: _isLoading
                    ? const _HelpLoading()
                    : _HelpContent(
                        reduceMotion: reduceMotion,
                        isDark: isDark,
                        isSearching: _isSearching,
                        searchController: _searchController,
                        filteredItems: _filteredItems,
                        items: _items,
                        ctxt: ctxt,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HelpContent extends ConsumerWidget {
  final bool reduceMotion;
  final bool isDark;
  final bool isSearching;
  final TextEditingController searchController;
  final List<HelpItem> filteredItems;
  final List<HelpItem> items;
  final AppLocalizations ctxt;

  const _HelpContent({
    required this.reduceMotion,
    required this.isDark,
    required this.isSearching,
    required this.searchController,
    required this.filteredItems,
    required this.items,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        if (!isSearching) ...[
          _HeroCard(isDark: isDark, reduceMotion: reduceMotion),
          SizedBox(height: spacing.sectionGap),
        ],
        if (filteredItems.isEmpty) ...[
          _EmptyState(color: color, textTheme: textTheme, ctxt: ctxt),
        ] else ...[
          if (!isSearching) ...[
            SectionHeader(ctxt.help_topics),
            SizedBox(height: spacing.elementGap),
          ],
          if (isSearching && searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                ctxt.help_resultCount(filteredItems.length),
                style: textTheme.bodySmall?.copyWith(
                  color: color.onSurfaceVariant,
                ),
              ),
            ),
          _HelpList(
            items: filteredItems,
            reduceMotion: reduceMotion,
            ctxt: ctxt,
          ),
        ],
        if (!isSearching) ...[
          SizedBox(height: spacing.sectionGap),
          const _InfoCard(),
          SizedBox(height: spacing.sectionGap),
          const AmbientBrandSection(
            showSignature: false,
            absorbBottomInset: false,
          ),
        ],
      ],
    );
  }
}

class _HelpLoading extends ConsumerWidget {
  const _HelpLoading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final spacing = ref.watch(spacingProvider);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.cardHorizontal,
        vertical: spacing.cardVertical,
      ),
      children: [
        _HeroSkeleton(spacing: spacing, color: color),
        SizedBox(height: spacing.sectionGap),
        _HelpListSkeleton(spacing: spacing, color: color),
      ],
    );
  }
}

class _HeroCard extends ConsumerWidget {
  final bool isDark;
  final bool reduceMotion;

  const _HeroCard({required this.isDark, required this.reduceMotion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;
    final accent = color.primary;

    return Semantics(
      label: ctxt.help_heroTitle,
      child: Container(
        padding: EdgeInsets.all(spacing.cardInner),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.radiusMedium),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: isDark ? 0.2 : 0.12),
              accent.withValues(alpha: isDark ? 0.08 : 0.04),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.cardInner),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.bookOpen, color: accent, size: 28),
              ),
              SizedBox(width: spacing.cardInner),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctxt.help_heroTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    Text(
                      ctxt.help_heroDesc,
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
      ),
    );
  }
}

class _HelpList extends ConsumerWidget {
  final List<HelpItem> items;
  final bool reduceMotion;
  final AppLocalizations ctxt;

  const _HelpList({
    required this.items,
    required this.reduceMotion,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = ref.watch(spacingProvider);
    return SettingsGroupCard(
      items: items.map((item) {
        final icon = IconHelper.iconFromName(item.icon);
        return SettingItem(
          icon: icon,
          title: item.title,
          subtitle: item.shortDescription,
          onTap: () => _showHelpDetail(context, item, ctxt, spacing),
          selected: true,
        );
      }).toList(),
    );
  }

  void _showHelpDetail(
    BuildContext context,
    HelpItem item,
    AppLocalizations ctxt,
    AppSpacing spacing,
  ) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final icon = IconHelper.iconFromName(item.icon);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(spacing.radiusSmall * 2),
        ),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                decoration: BoxDecoration(
                  color: color.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(spacing.radiusSmall),
                  ),
                  child: Icon(icon, color: color.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.description,
              style: textTheme.bodyMedium?.copyWith(
                color: color.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _DetailSectionHeader(
              title: ctxt.help_howToUse,
              icon: LucideIcons.listOrdered,
              color: color,
              textTheme: textTheme,
            ),
            const SizedBox(height: 10),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: item.steps.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key < item.steps.length - 1 ? 12 : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: color.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                entry.value,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (item.tips.isNotEmpty) ...[
              const SizedBox(height: 24),
              _DetailSectionHeader(
                title: ctxt.help_tips,
                icon: LucideIcons.lightbulb,
                color: color,
                textTheme: textTheme,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(spacing.radiusMedium),
                  color: color.tertiary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: color.tertiary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: item.tips.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key < item.tips.length - 1 ? 10 : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.lightbulb,
                            size: 16,
                            color: color.tertiary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: textTheme.bodySmall?.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DetailSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final ColorScheme color;
  final TextTheme textTheme;

  const _DetailSectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme color;
  final TextTheme textTheme;
  final AppLocalizations ctxt;

  const _EmptyState({
    required this.color,
    required this.textTheme,
    required this.ctxt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(LucideIcons.searchX, size: 48, color: color.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            BuddyMessages.noFilterResults('search'),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ctxt.help_tryDifferent,
            style: textTheme.bodySmall?.copyWith(
              color: color.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends ConsumerWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = ref.watch(spacingProvider);
    final ctxt = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.primary.withValues(alpha: 0.06),
        border: Border.all(color: color.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, color: color.primary, size: 18),
          SizedBox(width: spacing.elementGap),
          Expanded(
            child: Text(
              ctxt.help_infoText,
              style: textTheme.bodySmall?.copyWith(
                color: color.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _HeroSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.cardInner),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(spacing.radiusMedium),
        color: color.surfaceContainerLow,
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SkeletonLoader(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(28),
          ),
          SizedBox(width: spacing.cardInner),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 140, height: 20),
                SizedBox(height: spacing.elementGapMin),
                const SkeletonLoader(width: 200, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpListSkeleton extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme color;

  const _HelpListSkeleton({required this.spacing, required this.color});

  @override
  Widget build(BuildContext context) {
    return SettingsGroupCard(
      items: List.generate(
        4,
        (index) => SettingItem(
          icon: LucideIcons.helpCircle,
          title: '...',
          subtitle: '...',
          onTap: () {},
          selected: false,
        ),
      ),
    );
  }
}
