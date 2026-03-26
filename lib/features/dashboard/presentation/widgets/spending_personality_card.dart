import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mudra_manager/core/entitlement/entitlement_feature.dart';
import 'package:mudra_manager/features/analytics/data/spending_analyzer.dart';
import 'package:mudra_manager/features/analytics/data/personality_archetype.dart';
import 'package:mudra_manager/shared/widgets/pro_gate.dart';
import 'package:mudra_manager/shared/widgets/skeleton_loader.dart';
import 'package:mudra_manager/core/router/app_routes.dart';

final spendingPersonalityProvider =
    FutureProvider<SpendingPersonality?>((ref) async {
  return await SpendingAnalyzer.analyzePersonality();
});

class SpendingPersonalityCard extends ConsumerWidget {
  final double globalPadding;

  const SpendingPersonalityCard({super.key, required this.globalPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personality = ref.watch(spendingPersonalityProvider);
    final color = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return personality.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();

        final archetype = PersonalityArchetype.fromSpendingPersonality(data);

        return ProCardGate(
          feature: ProFeature.spendingPersonality,
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: globalPadding),
                child: Card(
                  elevation: 0,
                  color: color.surfaceContainerLow,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push(AppRoutes.spendingPersonality);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: SvgPicture.asset(
                              archetype.svgAsset,
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                              placeholderBuilder: (context) => const SizedBox(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  archetype.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  archetype.description,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: color.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
              ),
            ),
          ),
        );
      },
      loading: () => const PersonalityCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
